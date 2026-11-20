# cli-tools

Sunstone CLI tools. Go tools build on macOS and Linux. Swift tools are macOS only.

## Setup

    brew bundle                 # Go. Swift comes from Xcode or `xcode-select --install`.

## Layout

| Path | Contents |
|---|---|
| `go/cmd/<tool>/` | One Go tool per directory. Single module `github.com/sunstoneinstitute/cli-tools/go`. |
| `swift/Sources/<tool>/` | One Swift executable per directory, using swift-argument-parser. Auto-discovered by `Package.swift`. |
| `swift/Tests/<tool>Tests/` | Tests for a Swift tool (`@testable import <tool>`, hyphens become underscores). |
| `bin/` | Build output (git-ignored). |

Tool names must be unique across Go and Swift.

## Usage

    scripts/new-tool go <name>      # or: scripts/new-tool swift <name>
    make                            # build all tools into bin/ (Swift skipped on Linux)
    make test                       # go vet + go test, swift test
    make clean
