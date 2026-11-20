# cli-tools

See README.md for layout and commands.

- Choose Go for anything that must run on Linux. Choose Swift only when the tool needs macOS frameworks.
- Create tools with `scripts/new-tool`. Do not edit `swift/Package.swift` to register tools, it discovers them.
- Verify with `make && make test` before claiming a change works.
