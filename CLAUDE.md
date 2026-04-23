# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & test

```sh
swift build                                                    # library, macOS host
swift test                                                     # all tests (18 in 7 suites as of 0.3.0)
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

The demo app's `--auto-demo` launch arg makes it self-drive a network/log/HUD-expand sequence used by the GIF recipe. The `--auto-demo` flow opens on the **Performance** panel — switching to **Views** requires a manual tap (SwiftUI has no public tab-selection programmatic hook; adding a demo-only notification bus to `LensState` would be library pollution for marketing purposes, consciously not done).

## Repo layout worth knowing

- `Sources/PixzlSwiftLens/Public/` — public API surface (`.pixzlSwiftLens()`, `.lensTrack()`, `PixzlSwiftLensConfig`, `PixzlSwiftLensNetwork.install`/`uninstall`, `URLSessionConfiguration.pixzlSwiftLens()`)
- `Sources/PixzlSwiftLens/Core/` — `LensState` + `ViewInvalidationRecorder` (the non-UI, non-sampler glue)
- `Sources/PixzlSwiftLens/{Samplers, Network, Logs, Activators, UI}/` — what the names say
- `Examples/PixzlSwiftLensDemo/` — demo app, uses local SPM reference to `../..`
- `docs/blog/` — long-form launch posts (draft artifacts; `docs/blog/view-render-tracking.md` is the 0.3.0 launch post)
- `docs/launch/` — copy-paste-ready social posts and submission texts (iOS Dev Weekly, r/iOSProgramming, Show HN, DM templates)

## Architecture

PixzlSwiftLens is a SwiftUI debug HUD for iOS 26+, attached via a single `.pixzlSwiftLens()` View modifier. The modifier collapses to **`self`** outside `#if DEBUG` (the modifier body — `LensState`, samplers, UI types — disappears). The network-capture and view-tracking public API surfaces are also **body-gated**: the symbols stay public for source-compat (so callers like `PixzlSwiftLensNetwork.install()` in an unconditional `init()` still link), but their bodies are `#if DEBUG` and references to `PixzlSwiftURLProtocol` / `URLSessionSwizzler` / `LensTrackModifier` are gone from release binaries.

Public *types* in `Public/PixzlSwiftLensConfig.swift` (`PixzlSwiftLensActivator`, `PixzlSwiftLensPanels`, `PixzlSwiftLensPosition`, `PixzlSwiftLensPillStyle`, `PixzlSwiftLensConfig`) are not gated and retain their type descriptors in release. `PixzlSwiftLensConfig` is **immutable (`public let` fields)** — do not "fix" to `var`, the modifier captures the config at init and never observes post-init mutations.

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
   (Recorder   │                          │
    actor)     │                          │
               │                          │
   Logs ───────┤   1 s OSLogStore poll    │
   (OSLogReader                           │
    actor, uptime-cursor)                 │
               │                          │
   Views ──────┘   500 ms snapshot poll   │
   (Invalidation                          │
    Recorder class)                       │
                                          │
   PixzlSwiftURLProtocol ────────────► NetworkRecorder.shared (actor)
   (intercepts URLSession traffic;
    registered + swizzled by
    PixzlSwiftLensNetwork.install())

   .lensTrack("…") modifier ─────────► ViewInvalidationRecorder.shared
   (one record() per body re-eval;      (NSLock-guarded class, NOT actor)
    synchronous, on main thread)
```

`LensState` is the single `@Observable` `@MainActor` store the UI binds to. Background work (network capture, log reading) lives in actors; view invalidation writes live in a class (see rationale below). `LensState.start` spins polling Tasks that snapshot those recorders onto the main actor at modest rates (chosen to be cheap, not real-time).

### Key seams when extending

- **Public API surface** (`Sources/PixzlSwiftLens/Public/`): `pixzlSwiftLens()` modifier, `PixzlSwiftLensConfig`, `PixzlSwiftLensNetwork.install()/uninstall()`, `URLSessionConfiguration.pixzlSwiftLens()`, `View.lensTrack(_:)`. New activator/panel/option enums go here.
- **Activators**: each posts `Notification.Name.pixzlSwiftLensDeviceShake` (single bus for all activators). The modifier filters by `config.activator` so multiple activators don't double-toggle. Shake works via `extension UIWindow { open override func motionEnded }` (Swift's UIKit-category-override = effective method swizzle; conflicts possible with Sentry/UXCam). `Notification.Name.pixzlSwiftLensDeviceShake` is intentionally **outside** the UIKit guard in `ShakeDetector.swift` so subscribers compile on macOS — do not move it inside.
- **Network capture**: `PixzlSwiftLensNetwork.install()` both registers `PixzlSwiftURLProtocol` globally (for `URLSession.shared`) AND calls `URLSessionSwizzler.installIfNeeded()` to swizzle `URLSessionConfiguration.default()`/`.ephemeral()` class methods (via `method_exchangeImplementations`). So sessions built from those configs also pick up the protocol. `install()` is idempotent; `uninstall()` unregisters the URLProtocol but does **not** un-swizzle (the class-method swizzle is process-global for the lifetime of the process — self-inverse double-swizzle would be dangerous if other code relied on the current state).
- **`PixzlSwiftURLProtocol.startLoading()` proxies via a fresh `URLSessionConfiguration.default`** — this loses the original session's auth/timeout/cookie/redirect config. Known limitation, commented in-code. The `innerProtocols` static is a test seam (read under the same `NSLock`) used by `EndToEndCaptureTests` to inject a `MockResponderURLProtocol`.
- **Body capture cap**: `PixzlSwiftURLProtocol.maxCapturedBodyBytes = 256 KB`. Request and response bodies are truncated at that size for the recorder; the downstream URL client still receives the full body. `NetworkRecord.requestBodyTruncated` / `.responseBodyTruncated` flags surface the truncation in the detail view.
- **Logs**: `OSLogReader` is an actor that polls `OSLogStore(scope: .currentProcessIdentifier)` using a **monotonic cursor** (`ProcessInfo.systemUptime` + `OSLogStore.position(timeIntervalSinceLatestBoot:)`). Do **not** regress to a wall-clock `Date` cursor — that drops entries on NTP sync forward-jumps and duplicates entries on backward-jumps.
- **Memory**: `MemorySampler` reads `task_vm_info.phys_footprint` (the metric iOS Jetsam uses, same as Xcode's Memory Graph). Do not revert to `mach_task_basic_info.resident_size` — that metric is consistently lower than what actually causes termination.
- **UI** (`Sources/PixzlSwiftLens/UI/`): `LensOverlay` chooses pill vs floating button; `ExpandedPanel` is a `.sheet(isPresented:)` with tabs, **not** a custom presentation. Adding a panel requires **four** coordinated edits: (1) new case in `LensTab` (in `LensState.swift`), (2) new flag in `PixzlSwiftLensPanels` OptionSet (in `PixzlSwiftLensConfig.swift`), (3) new case in `ExpandedPanel.content`, (4) new entry in `ExpandedPanel.availableTabs`. Missing any of the four fails silently (panel simply doesn't show or crashes on tab selection).

### View-render tracking — deliberate design choices

The `.lensTrack(_:)` feature relies on two patterns that look wrong at first glance. Both are intentional; don't "fix" them without signal:

1. **`LensTrackModifier.body(content:)` has a side effect** — it calls `ViewInvalidationRecorder.shared.record(name:)` on every body re-evaluation. SwiftUI's "no side effects in body" rule is about *not writing to state the view reads* (which causes infinite loops). The recorder is a detached class the view never reads from, so no loop is possible. The side effect *is* the signal — this is how we count body invalidations.

2. **`ViewInvalidationRecorder` is a `final class` with `NSLock`, not an `actor`** — writes happen synchronously from `LensTrackModifier.body(content:)`, which can fire dozens of times per second per tracked view, all on the main thread. Actor isolation would require each write to hop through a `Task`, which blows the frame budget at even modest tracking loads. A locked dictionary write is cheap (microseconds) and stays off the render path.

If you find yourself refactoring `ViewInvalidationRecorder` to an actor or moving the record() call out of `body()`, you're probably breaking the design. Add tests that track body invalidation frequency before making such a change.

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

This keeps `swift test` green on macOS host.

### Testing patterns

- Unit: pure function tests (`CURLBuilderTests`), actor / class smoke tests (`NetworkRecorderTests`, `ViewInvalidationRecorderTests`), Mach-API smoke tests (`MemorySamplerTests`, `CPUSamplerTests`).
- Integration: `EndToEndCaptureTests` builds a real `URLSession` with `PixzlSwiftURLProtocol` and injects `MockResponderURLProtocol` via `PixzlSwiftURLProtocol.innerProtocols`. The mock's `canInit` checks `host == "e2e.test"` so production traffic is unaffected. Tests use `.serialized` because `NetworkRecorder.shared` is a process-wide singleton.
- `ViewInvalidationRecorderTests` uses a **local** `ViewInvalidationRecorder()` instance (not `.shared`) to avoid cross-test contamination.

## Release-build invariant

Three nested layers of gating, all pointing at `#if DEBUG`:

1. The `.pixzlSwiftLens()` modifier and the `PixzlSwiftLensModifier` struct that backs it are inside `#if DEBUG` blocks in `Public/PixzlSwiftLensModifier.swift`. Outside DEBUG the modifier collapses to `self`.
2. The `.lensTrack(_:)` modifier collapses to `self` outside DEBUG; `LensTrackModifier` itself is `#if DEBUG`-only.
3. The network-capture public symbols (`PixzlSwiftLensNetwork.install`/`uninstall`, `URLSessionConfiguration.pixzlSwiftLens()`) **remain public** in release for source-compat, but their bodies are `#if DEBUG` — so they are no-ops in release. `PixzlSwiftURLProtocol.swift` and `URLSessionSwizzler.swift` are themselves wrapped in `#if DEBUG`.

Verify with `nm` on the release binary of the demo app (or any host app): `PixzlSwiftURLProtocol`, `PixzlSwiftProtocolDelegate`, `URLSessionSwizzler`, `LensTrackModifier` should not appear. Note that `LensState` and the samplers currently still leave *type metadata* in the release binary (a few KB) because they are always-compiled internal types; gating them is a future scope-expansion task if binary size matters.

Any new code reachable from the modifier's body, from `lensTrack`, or from the network-capture API must stay inside the relevant `#if DEBUG` block. **Do not** reference `LensState`, `LensOverlay`, samplers, recorders, `PixzlSwiftURLProtocol`, `URLSessionSwizzler`, or `LensTrackModifier` from always-compiled code paths — that defeats the dead-code-stripper.

## Commit identity & remote

The entire commit history was rewritten via `git filter-repo` to use the GitHub no-reply email (`26158645+drieken@users.noreply.github.com`). The local `user.email` for this repo is set accordingly. **Do not author commits with `dominikrieken@icloud.com` or `drieken@pixzl.de`** — those leak personal contact info publicly. If the global git config still has a personal email, override per-commit with `git -c user.email="26158645+drieken@users.noreply.github.com" commit …`.

`main` has branch protection: **force-push and deletion are blocked**. PR reviews and required status checks are *not* enforced — direct pushes are fine, but rewriting history needs the protection toggled off via the GitHub API first (which is itself a destructive change requiring explicit user authorization).

The remote is SSH (`git@github.com:Pixzl/PixzlSwiftLens.git`) — HTTPS pushes fail because the OAuth token lacks the `workflow` scope and any commit touching `.github/workflows/` gets rejected. The same scope limitation breaks `gh pr merge` on Dependabot PRs that touch workflows: the workaround is to push the same diff directly to `main` over SSH, after which Dependabot auto-closes its now-redundant PR.

Dependabot is configured in `.github/dependabot.yml` and opens weekly PRs for GitHub Actions version bumps. They are safe to merge or to land directly on `main` (see above).

## Releasing

CHANGELOG-driven, manual:

1. Move `Unreleased` → `[X.Y.Z]` in `CHANGELOG.md` with date
2. Bump `PixzlSwiftLens.version` string in `Sources/PixzlSwiftLens/PixzlSwiftLens.swift` — this has drifted behind real tags before (0.1.0 → 0.2.0 release shipped with stale string)
3. `git tag -a vX.Y.Z -m "vX.Y.Z — short note"`
4. `git push origin main vX.Y.Z`
5. `gh release create vX.Y.Z --notes <…> --latest`

Deployment-target floor changes are SemVer-breaking → minor bump pre-1.0, major after. Same goes for source-breaking public API changes (e.g., the 0.3.0 `public var` → `public let` on `PixzlSwiftLensConfig`).
