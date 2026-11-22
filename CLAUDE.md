# cli-tools

See README.md for layout and commands.

- Choose Go for anything that must run on Linux. Choose Swift only when the tool needs macOS frameworks.
- Create tools with `scripts/new-tool`. Do not edit `swift/Package.swift` to register tools, it discovers them.
- Verify with `make && make test` before claiming a change works.

## Changelog

When a commit changes something users notice, add a line under `## [Unreleased]` in CHANGELOG.md:
`- <Added|Changed|Improved|Fixed|Removed>: <one short sentence naming the tool>`. Skip CI, docs and
other housekeeping. Releases are cut with `/release`, see README.md.
