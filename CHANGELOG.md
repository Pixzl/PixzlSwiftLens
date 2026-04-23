# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [Unreleased]

## [0.3.0] — 2026-04-23

### Added
- **Views panel** — live body-invalidation rate per SwiftUI view. Annotate with `.lensTrack("name")`, shake, see the table. Rates above 5/s color orange, above 15/s go red with a "hot" badge. Fills a gap no other iOS debug tool addresses.
- `PixzlSwiftLensNetwork.uninstall()` — symmetric to `install()`; unregisters the URLProtocol hook. Note: the `URLSessionConfiguration.default`/`.ephemeral` method-swizzle is process-global and not reverted.
- 5 new tests for `ViewInvalidationRecorder` (rate windows, pruning, separate counters, reset)
- `docs/blog/view-render-tracking.md` — launch-post draft walking through the tracking implementation

### Changed
- **Breaking (source-level):** `PixzlSwiftLensConfig` fields are now `public let` instead of `public var`. The modifier captured the config at init and never observed mutations — making it mutable was a silent-bug invitation. Users constructing configs inline are unaffected.
- `PixzlSwiftLensNetwork.install()` now **actually** calls `URLSessionSwizzler.installIfNeeded()` as the README has always claimed. Before, the swizzler code existed but was never wired; sessions built from `URLSessionConfiguration.default` weren't being captured. Now they are.
- `MemorySampler` reports `phys_footprint` (via `task_vm_info`) instead of `resident_size`. `phys_footprint` is what iOS Jetsam uses to terminate processes and what Xcode's Memory Graph shows — the old resident_size was consistently lower than what mattered.
- `OSLogReader` cursor migrated from wall-clock `Date` to monotonic `ProcessInfo.systemUptime` + `OSLogStore.position(timeIntervalSinceLatestBoot:)`. NTP syncs and manual clock changes no longer drop or duplicate log lines.
- Network capture API (`PixzlSwiftLensNetwork.install`/`uninstall`, `URLSessionConfiguration.pixzlSwiftLens()`) bodies are now `#if DEBUG`-gated. Public symbols remain for source compatibility, but Release builds strip `PixzlSwiftURLProtocol`, `URLSessionSwizzler`, `PixzlSwiftProtocolDelegate` — verified with `nm`.
- Package.swift: removed redundant `.enableExperimentalFeature("StrictConcurrency")` — Swift 6.2 enables strict concurrency by default.
- Public `PixzlSwiftLensConfig` types (`PixzlSwiftLensActivator`, `PixzlSwiftLensPanels`, `PixzlSwiftLensPosition`, `PixzlSwiftLensPillStyle`) now have doc comments.

### Fixed
- **Unbounded response-body capture.** `PixzlSwiftURLProtocol.responseBuffer` grew with every `didReceiveData` chunk; a 50 MB download would keep 50 MB pinned in the recorder. Now capped at 256 KB per record with a `responseBodyTruncated` flag surfaced in the network detail view. Request bodies are capped identically (`requestBodyTruncated`). The downstream URL client still receives the full body — only the debug capture is gated.
- `PixzlSwiftLens.version` string was stuck at `"0.1.0"` across the 0.2.0 release; now reflects the current version.

### Added (documentation)
- README rewritten with Views feature prominent, Pulse/FLEX/Atlantis comparison table, and release-build strip verification snippet.

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

[Unreleased]: https://github.com/Pixzl/PixzlSwiftLens/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/Pixzl/PixzlSwiftLens/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/Pixzl/PixzlSwiftLens/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Pixzl/PixzlSwiftLens/releases/tag/v0.1.0
