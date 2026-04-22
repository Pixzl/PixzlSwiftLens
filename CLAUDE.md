# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & test

```sh
swift build                                                    # library, macOS host
swift test                                                     # all tests
swift test --filter EndToEndCaptureTests                       # one suite
swift test --filter "EndToEndCaptureTests/capturesSuccessfulGET"  # one test
```

The package builds for **both iOS 26 and macOS 26** so that `swift test` runs on a Mac without booting a simulator. iOS-only code lives behind `#if canImport(UIKit)` with no-op stubs for the macOS branch.

To verify an iOS-only change actually compiles for the device target:

```sh
xcodebuild -scheme PixzlSwiftLens -destination 'generic/platform=iOS Simulator' build
cd Examples/PixzlSwiftLensDemo && \
  xcodebuild -scheme PixzlSwiftLensDemo -destination 'generic/platform=iOS Simulator' build
```

The demo app uses an **`XCLocalSwiftPackageReference` to `../..`** — local edits to `Sources/PixzlSwiftLens` are picked up on its next build, no manual re-link needed.

To record a fresh hero GIF (requires booted iPhone simulator, ffmpeg):

```sh
DEVICE_ID=<sim-udid>
xcodebuild -scheme PixzlSwiftLensDemo \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath ./.build build
xcrun simctl install "$DEVICE_ID" .build/Build/Products/Debug-iphonesimulator/PixzlSwiftLensDemo.app
(xcrun simctl io "$DEVICE_ID" recordVideo --codec h264 --force /tmp/demo.mov & echo $! > /tmp/recpid)
sleep 0.6
xcrun simctl launch "$DEVICE_ID" com.pixzl.swiftlens.demo --auto-demo
sleep 12 && kill -INT $(cat /tmp/recpid)
ffmpeg -y -ss 1 -t 11 -i /tmp/demo.mov \
  -vf "fps=15,scale=320:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=5" \
  -loop 0 Resources/hero.gif
```

The demo app's `--auto-demo` launch arg makes it self-drive a network/log/HUD-expand sequence used by the GIF recipe.

## Architecture

PixzlSwiftLens is a SwiftUI debug HUD for iOS 26+, attached via a single `.pixzlSwiftLens()` View modifier. It compiles to **`self`** outside `#if DEBUG` (the modifier body — `LensState`, samplers, UI types — disappears; **note that the public types in `Public/` are not gated and do remain in release binaries**).

### Data flow

```
Activator ─────┐
(Shake /       │
 ThreeFinger / │  toggleExpanded()
 FloatingBtn)  ├──────────────────────► LensState ◄────── @Observable bindings
               │                          ▲                    in UI/
               │                          │
   Samplers ───┤   1 Hz aggregate loop    │
   (FPS/Mem/   │   (state.start)          │
    CPU)       │                          │
               │                          │
   Network ────┤   500 ms snapshot poll   │
   (Recorder   │   from actor             │
    actor)     │                          │
               │                          │
   Logs ───────┘   1 s OSLogStore poll    │
   (OSLogReader    actor)                 │
                                          │
   PixzlSwiftURLProtocol ────────────► NetworkRecorder.shared (actor)
   (intercepts URLSession traffic;
    swizzled into URLSessionConfiguration.default
    by PixzlSwiftLensNetwork.install())
```

`LensState` is the single `@Observable` `@MainActor` store the UI binds to. Background work (network capture, log reading) lives in actors; `LensState.start` spins polling Tasks that snapshot those actors onto the main actor at modest rates (chosen to be cheap, not real-time).

### Key seams when extending

- **Public API surface** (`Sources/PixzlSwiftLens/Public/`): `pixzlSwiftLens()` modifier, `PixzlSwiftLensConfig`, `PixzlSwiftLensNetwork.install()`, `URLSessionConfiguration.pixzlSwiftLens()`. New activator/panel/option enums go here.
- **Activators**: each posts `Notification.Name.pixzlSwiftLensDeviceShake` (single bus for all activators). The modifier filters by `config.activator` so multiple activators don't double-toggle. Shake works via `extension UIWindow { open override func motionEnded }` (Swift's UIKit-category-override = effective method swizzle; conflicts possible with Sentry/UXCam).
- **Network capture**: `PixzlSwiftLensNetwork.install()` swizzles `URLSessionConfiguration.default()` and `.ephemeral()` (class methods, exchanged via `method_exchangeImplementations`). New sessions built from those configs get `PixzlSwiftURLProtocol` prepended. `URLSession.shared` picks it up because shared is initialized lazily from `.default`.
- **`PixzlSwiftURLProtocol.startLoading()` proxies via a fresh `URLSessionConfiguration.default`** — this loses the original session's auth/timeout/cookie/redirect config. Known limitation. The `innerProtocols` static is a test seam (read by the same method) used by `EndToEndCaptureTests` to inject a `MockResponderURLProtocol`.
- **Logs**: `OSLogReader` is an actor that polls `OSLogStore(scope: .currentProcessIdentifier)` with a date-cursor. Date cursors are loose (sub-second collisions, clock-jumps) — keep that in mind for any reliability work.
- **UI** (`Sources/PixzlSwiftLens/UI/`): `LensOverlay` chooses pill vs floating button; `ExpandedPanel` is a `.sheet(isPresented:)` with tabs, **not** a custom presentation. New panels require entries in `LensTab` (in `LensState.swift`), `PixzlSwiftLensPanels` OptionSet, and a case in `ExpandedPanel.content`.

### Cross-platform compile rule

Files using `UIKit`/`UIWindow`/`UITapGestureRecognizer`/`CADisplayLink` must be wrapped:

```swift
#if canImport(UIKit)
import UIKit
// real impl
#else
// no-op stub matching the same public surface
#endif
```

This keeps `swift test` green on macOS host. `Notification.Name.pixzlSwiftLensDeviceShake` is intentionally **outside** the UIKit guard so subscribers compile on macOS too.

### Testing patterns

- Unit: pure function tests (`CURLBuilderTests`), actor smoke tests (`NetworkRecorderTests`), Mach-API smoke tests (`MemorySamplerTests`, `CPUSamplerTests`).
- Integration: `EndToEndCaptureTests` builds a real `URLSession` with `PixzlSwiftURLProtocol` and injects `MockResponderURLProtocol` via `PixzlSwiftURLProtocol.innerProtocols`. The mock's `canInit` checks `host == "e2e.test"` so production traffic is unaffected. Tests use `.serialized` because `NetworkRecorder.shared` is a process-wide singleton.

## Release-build invariant

The `.pixzlSwiftLens()` modifier and the `PixzlSwiftLensModifier` struct that backs it are inside `#if DEBUG` blocks in `Public/PixzlSwiftLensModifier.swift`. Any new code reachable from the modifier's body must stay either in those blocks or in always-compiled files that are never invoked at runtime in release. **Do not** reference `LensState`, `LensOverlay`, samplers, recorders, or UI types from non-`#if DEBUG` code paths — that defeats the dead-code-stripper.

## Commit identity & remote

The entire commit history was rewritten via `git filter-repo` to use the GitHub no-reply email (`26158645+drieken@users.noreply.github.com`). The local `user.email` for this repo is set accordingly. **Do not author commits with `dominikrieken@icloud.com` or `drieken@pixzl.de`** — those leak personal contact info publicly. If the global git config still has a personal email, override per-commit with `git -c user.email="26158645+drieken@users.noreply.github.com" commit …`.

`main` has branch protection: **force-push and deletion are blocked**. PR reviews and required status checks are *not* enforced — direct pushes are fine, but rewriting history needs the protection toggled off via the GitHub API first (which is itself a destructive change requiring explicit user authorization).

The remote is SSH (`git@github.com:Pixzl/PixzlSwiftLens.git`) — HTTPS pushes fail because the OAuth token lacks the `workflow` scope and any commit touching `.github/workflows/` gets rejected.

## Releasing

CHANGELOG-driven, manual:

1. Move `Unreleased` → `[X.Y.Z]` in `CHANGELOG.md` with date
2. `git tag -a vX.Y.Z -m "vX.Y.Z — short note"`
3. `git push origin main vX.Y.Z`
4. `gh release create vX.Y.Z --notes <…> --latest`

Deployment-target floor changes are SemVer-breaking → minor bump pre-1.0, major after.
