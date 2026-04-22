# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [Unreleased]

## [0.2.0] — 2026-04-23

### Changed
- **Breaking:** raised deployment target floor to **iOS 26 / macOS 26**, swift-tools to **6.2**
- README: badges now point to the actual repo; SPM install snippet uses `Pixzl/PixzlSwiftLens`
- CI: `actions/checkout@v4` → `@v5` (Node 24); rely on the runner's default Xcode

### Added
- Theme-responsive logo: `<picture>` with dark/light variants, swaps with `prefers-color-scheme`
- Social preview asset under `Resources/social-preview.png`

## [0.1.0] — 2026-04-22

Initial release.

### Added
- `.pixzlSwiftLens()` SwiftUI modifier with FPS / RAM / CPU pill that expands into a tabbed inspector
- **Performance panel** — live charts via Swift Charts (CADisplayLink, mach_task_basic_info, thread_info)
- **Network panel** — URLProtocol-based capture, JSON pretty-print, Copy as cURL, search/filter
- **Logs panel** — OSLogStore reader with level filter and full-text search
- Three activators: `.shake`, `.threeFingerTap`, `.floatingButton`
- `PixzlSwiftLensNetwork.install()` — method-swizzles `URLSessionConfiguration.default`/`.ephemeral` so `URLSession.shared` traffic is captured transparently
- `URLSessionConfiguration.pixzlSwiftLens()` — explicit per-session opt-in
- Compiles to a no-op outside `#if DEBUG`
- Demo app under `Examples/PixzlSwiftLensDemo` with a `--auto-demo` launch argument
- 13 unit + integration tests, including end-to-end URLProtocol capture with an injected mock responder

[Unreleased]: https://github.com/Pixzl/PixzlSwiftLens/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Pixzl/PixzlSwiftLens/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Pixzl/PixzlSwiftLens/releases/tag/v0.1.0
