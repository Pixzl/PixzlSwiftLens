# Your SwiftUI view is rerendering 40 times per second. Here's how I found out — and how you can too, in one line of code.

*Published April 2026 · PixzlSwiftLens 0.3.0*

---

SwiftUI's biggest performance trap isn't slow code. It's bodies that get re-evaluated far more often than you think — because some `@Observable` higher up in the tree is too broad, or a parent is re-rendering on state you didn't even realize it was reading.

For years, the only tool we had to investigate was `Self._printChanges()` in the console. It works, kind of. You sprinkle it into every suspect view. You scroll through Xcode's log. You correlate. You swear. You try to remember which view was in the scrolled-past lines.

I wanted a better story. What if the HUD in your running app just **told you**, live, which of your views are rerendering most, at what rate, right now?

That's what I built in PixzlSwiftLens 0.3.0. Here's how it works, in about 50 lines of Swift.

## The API

```swift
CartView()
  .lensTrack("Cart")
```

That's the whole public surface. Shake your device, tap **Views**, and you see a sortable table of every view you've annotated — name, total invalidations since app start, live rate over the last second, with color coding (orange >5/s, red >15/s with a "hot" badge).

Rates auto-sort so the worst offender is always on top. The moment you refactor and the number drops to 0.2/s, you see it immediately. No re-running, no scrolling logs.

## The trick

SwiftUI calls `body` on a `ViewModifier` every time it re-evaluates that position in the view tree. If the modifier's own `body(content:)` has a side effect, that side effect fires on every invalidation.

"Don't do side effects in body" is the SwiftUI mantra — and it's right, for production code. For a debug-only tool that's gated behind `#if DEBUG` and writes only to a detached recorder (never to state the view reads), it's exactly the signal we want.

```swift
struct LensTrackModifier: ViewModifier {
    let name: String

    func body(content: Content) -> some View {
        ViewInvalidationRecorder.shared.record(name: name)
        return content
    }
}
```

That's it. The rest is plumbing.

## The recorder

Writes happen dozens of times per second per tracked view — on the main thread, from body re-evaluations. An actor would require each write to hop through a `Task`, which blows the frame budget at even modest tracking loads. `NSLock` around a dictionary is cheap enough to stay invisible:

```swift
final class ViewInvalidationRecorder: @unchecked Sendable {
    static let shared = ViewInvalidationRecorder()

    private let lock = NSLock()
    private var counters: [String: Counter] = [:]

    func record(name: String, at date: Date = Date()) {
        lock.lock()
        defer { lock.unlock() }
        counters[name, default: Counter()].tick(at: date)
    }

    func snapshot(now: Date = Date()) -> [ViewInvalidationSummary] {
        lock.lock()
        defer { lock.unlock() }
        return counters.map { name, counter in
            ViewInvalidationSummary(
                name: name,
                total: counter.total,
                last: counter.lastTick,
                recentRate: counter.rate(over: 1, now: now)
            )
        }
    }
}
```

Each `Counter` is a tiny rolling window:

```swift
private struct Counter {
    var total: Int = 0
    var lastTick: Date?
    var recent: [Date] = []       // sliding 2s window

    mutating func tick(at date: Date) {
        total += 1
        lastTick = date
        recent.append(date)
        let cutoff = date.addingTimeInterval(-2)
        while let first = recent.first, first < cutoff {
            recent.removeFirst()
        }
    }

    func rate(over seconds: Double, now: Date) -> Double {
        let cutoff = now.addingTimeInterval(-seconds)
        return Double(recent.reversed().prefix(while: { $0 >= cutoff }).count) / seconds
    }
}
```

That's the whole engine. Two locked operations, no async, no actors, no concurrency gymnastics.

## The polling

The HUD's central `@Observable` state polls the recorder every 500 ms — same pattern used for network capture and log reading:

```swift
private func startViewsPolling() {
    viewsPollTask?.cancel()
    viewsPollTask = Task { @MainActor [weak self] in
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(500))
            guard let self else { return }
            self.viewInvalidations = ViewInvalidationRecorder.shared.snapshot()
        }
    }
}
```

500 ms means the UI feels live without spending meaningful CPU. When the HUD sheet is dismissed, the task is still running but the rendered rows aren't visible — no actual cost beyond the snapshot itself (a locked dictionary copy that takes microseconds).

## Why this didn't exist already

Pulse is great, but it's a network-focused tool — view rendering is outside its scope. FLEX is a UIKit-era inspector; SwiftUI views don't have the runtime introspection UIKit does. Xcode Instruments' SwiftUI template shows you the same data but lives in a separate app with a capture-stop-analyze loop you break your flow for.

An in-app, live, one-annotation-per-view counter fills a gap. It's not about depth — it's about *friction*. The ten seconds between "I wonder" and "oh, **that's** why" is exactly where most debugging happens, and those ten seconds are where every existing tool falls down.

## Release-build guarantee

Every symbol touched by `.lensTrack` is inside `#if DEBUG`. In a release build:

```sh
xcrun nm -gU YourApp.app/YourApp | grep LensTrack
# (no output)
```

Nothing ships to users. No conditional runtime checks, no `if isDebug { … }`. The modifier expands to `self` at compile time.

## Try it

```swift
.package(url: "https://github.com/Pixzl/PixzlSwiftLens.git", from: "0.3.0")
```

Drop `.pixzlSwiftLens()` on your root view, `.lensTrack("Cart")` on your suspect views, shake the device. That's the whole loop.

If you find a view rerendering 40 times per second in your app, I'd love to hear about it. The whole point of this thing is that you *see* that number — and then you go fix it.

*PixzlSwiftLens is MIT-licensed and [on GitHub](https://github.com/Pixzl/PixzlSwiftLens).*
