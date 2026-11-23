// Open a URL in a new window of the default browser, close that window once
// kubelogin's callback listener (127.0.0.1:8000) exits, then re-activate the
// previously frontmost app. Chromium-family browsers and Safari are scriptable.
// Anything else (Firefox) is just opened and cannot be closed afterwards.
// Also notifies op-who (if running) so it can show which command needed the login.
import AppKit
import ArgumentParser
import Foundation

@main
struct OidcBrowser: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "oidc-browser",
        abstract: "Open an OIDC login URL in a closable browser window."
    )

    @Argument(help: "URL to open.")
    var url: String?

    @Option(help: "Port of the callback listener to wait for.")
    var port: UInt16 = 8000

    @Option(help: .hidden) var watchBundle: String?
    @Option(help: .hidden) var watchWindow: Int?
    @Option(help: .hidden) var watchPrevPid: Int32?

    func validate() throws {
        if watchBundle == nil, url == nil { throw ValidationError("Missing URL.") }
    }

    func run() throws {
        if let bundle = watchBundle, let window = watchWindow {
            watch(bundle: bundle, window: window)
            return
        }
        try open(url!)
    }

    private func open(_ urlString: String) throws {
        guard let url = URL(string: urlString) else { throw ValidationError("Invalid URL: \(urlString)") }
        let requester = getppid()  // kubelogin
        let bundle = defaultBrowserBundleID()
        guard let script = openScript(bundle: bundle, url: urlString) else {
            NSWorkspace.shared.open(url)
            notifyOpWho(requesterPID: requester, bounds: nil)
            return
        }
        let prev = NSWorkspace.shared.frontmostApplication
        let result = try runAppleScript(script)
        let window = Int(result.atIndex(1)?.int32Value ?? 0)
        let bounds = result.atIndex(2).map { list in
            (1...max(list.numberOfItems, 1)).compactMap { list.atIndex($0).map { Int($0.int32Value) } }
        }
        notifyOpWho(requesterPID: requester, bounds: bounds)
        try spawnWatcher(bundle: bundle, window: window, prevPid: prev?.processIdentifier)
    }

    /// Runs in a detached child: waits for the listener to go away, then cleans up.
    private func watch(bundle: String, window: Int) {
        Thread.sleep(forTimeInterval: 2)
        while isListening(port: port) { Thread.sleep(forTimeInterval: 1) }
        _ = try? runAppleScript("tell application id \"\(bundle)\" to close (window id \(window))")
        if let pid = watchPrevPid, let app = NSRunningApplication(processIdentifier: pid) {
            app.activate()
        }
    }

    private func defaultBrowserBundleID() -> String {
        let app = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https:")!)
        return app.flatMap { Bundle(url: $0)?.bundleIdentifier }?.lowercased() ?? "com.apple.safari"
    }

    private func openScript(bundle: String, url: String) -> String? {
        let quoted = "\"" + url.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
        let chromium = ["com.google.chrome", "com.brave.browser", "com.microsoft.edgemac"]
        let chromiumExact = ["org.chromium.chromium", "company.thebrowser.browser",
                             "com.vivaldi.vivaldi", "com.operasoftware.opera"]
        if bundle == "com.apple.safari" {
            return """
                tell application id "\(bundle)"
                  make new document with properties {URL:\(quoted)}
                  set b to {}
                  try
                    set b to bounds of front window
                  end try
                  return {id of front window, b}
                end tell
                """
        }
        if chromiumExact.contains(bundle) || chromium.contains(where: bundle.hasPrefix) {
            return """
                tell application id "\(bundle)"
                  set w to make new window
                  set URL of active tab of w to \(quoted)
                  set b to {}
                  try
                    set b to bounds of w
                  end try
                  return {id of w, b}
                end tell
                """
        }
        return nil
    }

    private func spawnWatcher(bundle: String, window: Int, prevPid: pid_t?) throws {
        var args = [CommandLine.arguments[0], "--port", String(port),
                    "--watch-bundle", bundle, "--watch-window", String(window)]
        if let prevPid { args += ["--watch-prev-pid", String(prevPid)] }

        var actions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&actions)
        defer { posix_spawn_file_actions_destroy(&actions) }
        for fd: Int32 in 0...2 {
            posix_spawn_file_actions_addopen(&actions, fd, "/dev/null", fd == 0 ? O_RDONLY : O_WRONLY, 0)
        }
        var attr: posix_spawnattr_t?
        posix_spawnattr_init(&attr)
        defer { posix_spawnattr_destroy(&attr) }
        posix_spawnattr_setflags(&attr, Int16(POSIX_SPAWN_SETSID))

        let cargs = args.map { strdup($0) } + [nil]
        defer { cargs.forEach { free($0) } }
        var pid: pid_t = 0
        let rc = posix_spawn(&pid, Bundle.main.executablePath ?? args[0], &actions, &attr, cargs, environ)
        if rc != 0 { throw RuntimeError("posix_spawn failed: \(String(cString: strerror(rc)))") }
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

func runAppleScript(_ source: String) throws -> NSAppleEventDescriptor {
    var error: NSDictionary?
    guard let result = NSAppleScript(source: source)?.executeAndReturnError(&error) else {
        throw RuntimeError("AppleScript failed: \(error?[NSAppleScript.errorMessage] ?? "unknown error")")
    }
    return result
}

/// userInfo for op-who's OIDC overlay. Protocol: op-who
/// docs/superpowers/specs/2026-11-23-oidc-login-overlay-design.md.
func opWhoUserInfo(requesterPID: pid_t, bounds: [Int]?) -> [String: String] {
    var info = ["requesterPID": String(requesterPID)]
    if let b = bounds, b.count == 4, b[2] > b[0], b[3] > b[1] {
        info["frame"] = "\(b[0]),\(b[1]),\(b[2] - b[0]),\(b[3] - b[1])"
    }
    return info
}

/// Tells op-who, if running, which kubelogin process opened this login.
func notifyOpWho(requesterPID: pid_t, bounds: [Int]?) {
    DistributedNotificationCenter.default().postNotificationName(
        Notification.Name("com.stigbakken.op-who.oidc-login"),
        object: nil,
        userInfo: opWhoUserInfo(requesterPID: requesterPID, bounds: bounds),
        deliverImmediately: true
    )
}

func isListening(port: UInt16) -> Bool {
    let fd = socket(AF_INET, SOCK_STREAM, 0)
    guard fd >= 0 else { return false }
    defer { close(fd) }
    var addr = sockaddr_in()
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = port.bigEndian
    addr.sin_addr.s_addr = inet_addr("127.0.0.1")
    return withUnsafePointer(to: &addr) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) == 0
        }
    }
}
