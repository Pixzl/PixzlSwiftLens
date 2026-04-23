<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="Resources/pixzl-logo-light.svg">
    <img src="Resources/pixzl-logo-dark.svg" width="120" alt="Pixzl">
  </picture>
</p>

<h1 align="center">PixzlSwiftLens</h1>

<p align="center">
  <strong>The SwiftUI-native debug HUD that tells you why your views keep rerendering.</strong><br>
  One modifier — and you get FPS, RAM, CPU, network calls, OSLog stream, and live per-view body-invalidation rates inside your app.<br>
  Shake to expand. Zero overhead in release.
</p>

<p align="center">
  <a href="https://github.com/Pixzl/PixzlSwiftLens/actions/workflows/ci.yml"><img src="https://github.com/Pixzl/PixzlSwiftLens/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <img src="https://img.shields.io/badge/swift-6.2-orange.svg" alt="Swift 6.2">
  <img src="https://img.shields.io/badge/iOS-26.0%2B-blue.svg" alt="iOS 26.0+">
  <img src="https://img.shields.io/badge/SPM-compatible-brightgreen.svg" alt="SPM">
  <img src="https://img.shields.io/badge/license-MIT-lightgrey.svg" alt="MIT">
</p>

<p align="center">
  <img src="Resources/hero.gif" alt="PixzlSwiftLens demo" width="320">
</p>

```swift
import PixzlSwiftLens

@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup { ContentView() }
      .pixzlSwiftLens()                  // one line. that's it.
  }
}
```

## The killer feature: Views that rerender too often

SwiftUI's biggest performance trap isn't slow code — it's bodies that get re-evaluated hundreds of times per second because some `@Observable` higher up in the tree is too broad. `Self._printChanges()` in the console isn't enough. Xcode Instruments is overkill. You need a live, per-view, in-app counter.

```swift
CartView()
  .lensTrack("Cart")                    // mark any view you want to watch
```

Shake → tap **Views** → you see a live table:

| View | total | rate |
|-----|------|------|
| Cart | 842 | **38.0/s** 🔴 hot |
| Header | 128 | 1.0/s |
| ProductRow | 64 | 0.2/s |

Rows auto-sort by live rate. Anything over 15/s gets a red "hot" badge. No other iOS debug tool shows you this.

## Why this, not Pulse/FLEX/Atlantis

| | PixzlSwiftLens | Pulse | FLEX | Atlantis |
|-----|:---:|:---:|:---:|:---:|
| Installation | **1 line** | ~10 | ~10 | Desktop + app |
| Pure SwiftUI | ✅ | partial | UIKit | — |
| **View-render tracking** | ✅ | — | — | — |
| Live FPS / RAM / CPU HUD | ✅ | — | — | — |
| Network capture | ✅ | ✅ (deeper) | ✅ | ✅ |
| OSLog stream | ✅ | ✅ | — | — |
| Release no-op | ✅ | ✅ | ✅ | ✅ |
| iOS 26 / Swift 6 native | ✅ | ⚠️ | ⚠️ | ⚠️ |

PixzlSwiftLens doesn't try to replace Pulse on network depth. It wins on **installation friction**, **SwiftUI-native feel**, and the one thing no other tool has: **view-render diagnostics**.

## Install

Swift Package Manager:

```swift
.package(url: "https://github.com/Pixzl/PixzlSwiftLens.git", from: "0.3.0")
```

Then add `"PixzlSwiftLens"` to your target's dependencies.

## Quickstart

### 1. Attach the HUD

```swift
ContentView()
  .pixzlSwiftLens()                                // shake to toggle
```

### 2. Capture network calls

For custom sessions, build them with the helper:

```swift
let session = URLSession(configuration: .pixzlSwiftLens())
```

For `URLSession.shared` and other ambient traffic, install once at launch:

```swift
@main
struct MyApp: App {
  init() { PixzlSwiftLensNetwork.install() }
  var body: some Scene {
    WindowGroup { ContentView().pixzlSwiftLens() }
  }
}
```

`install()` registers globally **and** swizzles `URLSessionConfiguration.default`/`.ephemeral`, so sessions built from either pick up the recorder automatically.

### 3. Track view body invalidations

Add `.lensTrack(_:)` to any view you suspect is rerendering too often:

```swift
CartView()
  .lensTrack("Cart")

UserProfileView(user: user)
  .lensTrack("UserProfile")
```

The Views panel updates every 500 ms. Rates above 5/s go orange, above 15/s go red with a "hot" badge.

### 4. See your `Logger` output

Nothing to wire — `OSLogStore` is read for the current process on a monotonic clock, every second. Both `Logger(...)` and `os_log(...)` show up.

## Configuration

| Parameter   | Default          | Options                                                               |
|-------------|------------------|-----------------------------------------------------------------------|
| `activator` | `.shake`         | `.shake`, `.threeFingerTap`, `.floatingButton`                        |
| `panels`    | `.all`           | OptionSet of `.performance`, `.network`, `.logs`, `.views`            |
| `position`  | `.topTrailing`   | `.topLeading`, `.topTrailing`, `.bottomLeading`, `.bottomTrailing`    |
| `pillStyle` | `.compact`       | `.compact`, `.detailed`, `.hidden`                                    |

```swift
.pixzlSwiftLens(
  activator: .floatingButton,
  panels: [.performance, .views],       // drop panels you don't need
  position: .bottomLeading,
  pillStyle: .detailed
)
```

## What you get

- **Performance panel** — live FPS / RAM (phys_footprint, the metric iOS Jetsam uses) / CPU with rolling 60s charts
- **Network panel** — every URLSession call, inline status, `Copy as cURL`, JSON pretty-print, truncation flag for large bodies (256 KB cap keeps the recorder cheap)
- **Logs panel** — `OSLogStore` stream with level filter and full-text search, monotonic uptime cursor immune to wall-clock jumps
- **Views panel** — live body-invalidation rates per `.lensTrack(_:)`-annotated view

## Release builds

The public modifier, the network protocol, and `.lensTrack` all collapse to `self` outside `#if DEBUG`. There is no PixzlSwiftURLProtocol, URLSessionSwizzler, or LensTrackModifier symbol in your release binary — verify with `nm`:

```sh
xcrun nm -gU YourApp.app/YourApp | grep -i "PixzlSwiftURLProtocol\|LensTrack"
# (no output)
```

## Requirements

- iOS 26+
- Swift 6.2+
- Xcode 26+

## License

MIT.
