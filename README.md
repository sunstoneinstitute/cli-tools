# cli-tools

Sunstone CLI tools. Go tools build on macOS and Linux. Swift tools are macOS only.

## Installation

    brew install sunstoneinstitute/tap/cli-tools

macOS on Apple Silicon gets prebuilt bottles. Elsewhere brew builds from source.

## Development setup

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
    make sign                       # build, then Developer ID sign bin/* (macOS)
    make clean

## Releasing

Add user-facing changes to `## [Unreleased]` in CHANGELOG.md as you go. Run `/release` in Claude Code
(or `scripts/release.py --bump <level>` with the changelog entry on stdin), then `git push && git push --tags`.
The tag runs `.github/workflows/release.yml`: it builds macOS bottles, creates the GitHub release, and
updates `Formula/cli-tools.rb` in [sunstoneinstitute/homebrew-tap](https://github.com/sunstoneinstitute/homebrew-tap).
Release bottles are signed with Developer ID and hardened runtime by `scripts/codesign`.
Per-tool entitlements go in `macos/entitlements/<tool>.plist`. The formula template is `.github/homebrew/cli-tools.rb.template`.
