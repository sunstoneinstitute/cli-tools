# Changelog

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Added: oidc-browser posts the distributed notification `ai.sunstoneinstitute.oidc-browser.login-opened` with the requesting PID and the browser window frame, so a listening app (such as op-who) can show which command started the login.

## [0.1.1] - 2026-11-23

- Changed: macOS binaries in the Homebrew bottles are signed with Developer ID and hardened runtime.

## [0.1.0] - 2026-11-23

- Added: `oidc-browser` opens an OIDC login URL in a new browser window and closes it when kubelogin's callback listener exits.
- Added: install all tools with `brew install sunstoneinstitute/tap/cli-tools`.
