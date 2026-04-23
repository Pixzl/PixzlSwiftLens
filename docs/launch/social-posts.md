# Launch social posts — v0.3.0

Copy-paste-ready. Pick one channel at a time; spread over 2-3 days.

---

## Twitter / X (thread, 7 tweets)

**1/**
Your SwiftUI view is rerendering 40 times per second. You probably don't know which one.

Shipped a debug HUD that tells you — live, in-app, one line of code.

🔗 https://github.com/Pixzl/PixzlSwiftLens

**2/**
The existing story for SwiftUI rerender debugging is painful:

- `Self._printChanges()` → console noise, not aggregatable
- Xcode Instruments → capture, stop, analyze loop breaks flow
- Pulse / FLEX → great tools, but don't show view bodies at all

**3/**
With PixzlSwiftLens 0.3.0 you annotate any view:

```swift
CartView()
  .lensTrack("Cart")
```

Shake → Views tab → live sortable table. Cart flashing red at 38/s? Parent `@Observable` is too broad. Fix, watch it drop to 0.2/s.

**4/**
Implementation is about 50 lines of Swift. The trick: a ViewModifier whose `body(content:)` has a side effect (increment a counter). That's a SwiftUI anti-pattern in production. In a debug-only opt-in tool, it's exactly the signal you want.

**5/**
Release build? `.lensTrack` collapses to `self`. No symbol in the binary, zero runtime overhead. Verify with `nm`. The whole network / perf / logs / views HUD compiles away in `#if DEBUG`.

**6/**
Why now: SwiftUI debugging tooling hasn't kept up with `@Observable`. Most iOS debug HUDs come from the UIKit era. This one is SwiftUI-native from day one.

**7/**
Swift 6, iOS 26+, MIT. One `.pixzlSwiftLens()` modifier and you get FPS / RAM / CPU / network / logs / live view-render tracking.

Install:

```swift
.package(url: "https://github.com/Pixzl/PixzlSwiftLens.git", from: "0.3.0")
```

---

## LinkedIn (single long-form post)

**Title ideas (pick one):**
- "The one-line debug tool I wish I'd had two years ago"
- "Why iOS debug tools still can't tell you this, in 2026"
- "Building developer tools people actually use"

**Body:**

> SwiftUI's biggest performance trap isn't slow code. It's bodies that get re-evaluated hundreds of times per second because some `@Observable` higher up in the tree is too broad.
>
> For years, the only tool we had was `Self._printChanges()` — useful, but it dumps into the console, one line per invalidation, impossible to aggregate. Xcode Instruments has the data, but the capture-stop-analyze loop breaks your flow. Pulse, FLEX, Atlantis — all great tools, none of them show view bodies.
>
> So I built one.
>
> PixzlSwiftLens 0.3.0 adds `.lensTrack("Cart")` — a single modifier you drop on any view you suspect is misbehaving. Shake your device, tap the Views tab in the HUD, and you see a live sorted table: view name, total invalidations, rate per second. Anything above 15/s goes red with a "hot" badge. Fix your state scope, watch the number drop to 0.2/s. Real-time feedback loop.
>
> The whole thing compiles to nothing in Release — `#if DEBUG`-gated at the source level, verified with `nm`. Zero overhead in the app you ship.
>
> Also in this release: 256 KB body-cap on the network recorder (previously unbounded — a 50 MB download would pin 50 MB in memory), monotonic uptime cursor on the OSLog reader (immune to wall-clock jumps), proper `phys_footprint` memory reporting, and the `URLSessionConfiguration.default` swizzle that the README has been promising for three versions but never actually did.
>
> MIT-licensed, Swift 6, iOS 26+. If you've ever spent a morning hunting down a rogue SwiftUI rerender, give it a try.
>
> 🔗 https://github.com/Pixzl/PixzlSwiftLens

---

## Mastodon / Threads / Bluesky (single post, ~500 chars)

Shipped PixzlSwiftLens 0.3.0 — a SwiftUI debug HUD with something no other iOS tool has: live per-view body-invalidation rates.

```swift
CartView()
  .lensTrack("Cart")
```

Shake, tap Views, see which of your views is rerendering 40 times per second and why. Zero runtime overhead in Release.

One `.pixzlSwiftLens()` modifier gets you FPS / RAM / CPU / network / logs / view-render tracking.

MIT, Swift 6, iOS 26+.

🔗 https://github.com/Pixzl/PixzlSwiftLens

---

## Short variations (for reposts / follow-ups)

**"Show, don't tell" variant:**

> Before: `Self._printChanges()` → scroll through 2000 lines of console output
> After: `.lensTrack("Cart")` → Shake, see "Cart: 38.0/s 🔴 hot" in a sorted table
>
> PixzlSwiftLens 0.3.0 is out.

**Technical hook:**

> How do you count SwiftUI body invalidations from inside a ViewModifier?
> You put a side effect in `body(content:)`. Anti-pattern in production. Debug-only gold.
> Full implementation (~50 lines) in the blog post below.

**Niche hook:**

> Pulse is great for network inspection.
> FLEX is great for UIKit.
> Neither tells you which of your SwiftUI views is rerendering too often.
> That's the gap PixzlSwiftLens 0.3.0 fills.
