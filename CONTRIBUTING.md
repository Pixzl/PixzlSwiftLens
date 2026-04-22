# Contributing to PixzlSwiftLens

Thanks for considering a contribution! This document covers the practical bits — the bar is "useful and tested", not "perfect".

## Development setup

```sh
git clone git@github.com:Pixzl/PixzlSwiftLens.git
cd PixzlSwiftLens
swift build
swift test
```

The library builds for both **iOS 26+** (deployment target) and **macOS 26+** (so `swift test` works on a Mac without booting a simulator).

To run the demo app:

```sh
open Examples/PixzlSwiftLensDemo/PixzlSwiftLensDemo.xcodeproj
# ⌘R in Xcode
```

The demo project consumes the local package via `XCLocalSwiftPackageReference`, so any change you make in `Sources/PixzlSwiftLens` is picked up on the next build.

## Project layout

```
Sources/PixzlSwiftLens/
├── Public/        Public API — modifier, config, URLSession helpers
├── Core/          @Observable LensState
├── Activators/    Shake, three-finger tap, floating button
├── Samplers/      FPS / RAM / CPU
├── Network/       URLProtocol + recorder + cURL builder + swizzler
├── Logs/          OSLogStore reader
└── UI/            Overlay, pill, expanded panel, panels/
Tests/PixzlSwiftLensTests/
Examples/PixzlSwiftLensDemo/
```

## Pull requests

1. Open an issue first for anything non-trivial. Saves both of us time.
2. One topic per PR. Keep the diff scannable.
3. Tests for new behavior. The bar is end-to-end where it makes sense (see `EndToEndCaptureTests.swift` for the URLProtocol pattern).
4. Update `CHANGELOG.md` under `## [Unreleased]`.
5. Don't bump the version yourself — that happens at release time.

## Coding notes

- **Pure SwiftUI, zero dependencies.** Don't add a package without discussion.
- **Swift 6 strict concurrency must stay clean.** No new `@unchecked Sendable` without a comment explaining why.
- **iOS-only APIs go behind `#if canImport(UIKit)`.** Cross-platform stubs let `swift test` work on macOS host.
- **Public API additions need `///` docs.** Default values in the docs help.
- **Release-build no-op** must be preserved for any code reachable from `.pixzlSwiftLens()`.

## Releasing (maintainers)

1. Bump version in `CHANGELOG.md`, move `Unreleased` → `[X.Y.Z]`
2. Tag: `git tag -a vX.Y.Z -m "vX.Y.Z — short note"`
3. Push: `git push origin main vX.Y.Z`
4. `gh release create vX.Y.Z --notes-from-tag --latest`
