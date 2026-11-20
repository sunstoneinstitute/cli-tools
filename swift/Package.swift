// swift-tools-version: 6.0
// Every directory in Sources/ is an executable tool. Tests/<Tool>Tests tests <Tool>.
import Foundation
import PackageDescription

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

func subdirs(_ path: String) -> [String] {
    let dir = root.appendingPathComponent(path)
    let names = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
    return names.filter { name in
        var isDir: ObjCBool = false
        return !name.hasPrefix(".")
            && FileManager.default.fileExists(atPath: dir.appendingPathComponent(name).path, isDirectory: &isDir)
            && isDir.boolValue
    }.sorted()
}

let tools = subdirs("Sources")
let argumentParser = Target.Dependency.product(name: "ArgumentParser", package: "swift-argument-parser")

let package = Package(
    name: "cli-tools",
    platforms: [.macOS(.v14)],
    products: tools.map { .executable(name: $0, targets: [$0]) },
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: tools.map { .executableTarget(name: $0, dependencies: [argumentParser]) }
        + subdirs("Tests").filter { tools.contains(String($0.dropLast(5))) }.map {
            .testTarget(name: $0, dependencies: [.target(name: String($0.dropLast(5)))])
        }
)
