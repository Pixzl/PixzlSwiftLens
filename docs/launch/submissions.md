# Submission texts — v0.3.0 launch

For each outbound channel, the exact text to paste. Most forms don't accept markdown; where relevant, a plain-text version is included.

---

## iOS Dev Weekly (Dave Verwer)

**Submission form:** https://iosdevweekly.com/submit

**Category:** Tools (or Code)

**URL:** https://github.com/Pixzl/PixzlSwiftLens

**Title / Blurb (Dave rewrites, so give him clean signal):**

> PixzlSwiftLens — a SwiftUI-native debug HUD for iOS 26+. Added in 0.3.0: live per-view body-invalidation rates via `.lensTrack(_:)`. Annotate any view, shake, see which of your views is rerendering 40 times per second. The implementation (~50 lines) is a ViewModifier whose `body(content:)` increments a counter — an anti-pattern in production, the right signal in an opt-in debug-only tool. Compiles to a no-op outside `#if DEBUG`.

**Additional note to Dave:**

> Dave — this fills a specific gap (SwiftUI view-render diagnostics) that Pulse / FLEX / Instruments don't address today. If helpful there's a blog-post draft walking through the implementation: [link after you publish it]

---

## r/iOSProgramming (Reddit)

**Post type:** Self-post (not link post — text gets more engagement)

**Title:**

> I built a SwiftUI debug HUD that tells you which of your views is rerendering 40 times per second [open source]

**Body:**

> SwiftUI's biggest performance trap isn't slow code — it's bodies that get re-evaluated hundreds of times per second because some `@Observable` higher up in the tree is too broad. `Self._printChanges()` works but dumps to console. Instruments has the data but the capture-stop-analyze loop breaks your flow.
>
> PixzlSwiftLens 0.3.0 adds an in-app, live, per-view counter. Annotate a view:
>
> ```swift
> CartView()
>   .lensTrack("Cart")
> ```
>
> Shake, tap the Views tab, see a sorted table with live rates. Anything above 15/s goes red.
>
> The whole HUD also does FPS / RAM (phys_footprint — the metric iOS Jetsam uses, not the usual resident_size) / CPU / network / OSLog stream, all via one `.pixzlSwiftLens()` modifier on your root view. Compiles to nothing in Release.
>
> MIT, Swift 6, iOS 26+. Not trying to replace Pulse on network depth — that fight is unwinnable. The wedge is SwiftUI-native diagnostics and installation friction (one line).
>
> https://github.com/Pixzl/PixzlSwiftLens
>
> Happy to answer questions about the implementation — the view tracking is about 50 lines of Swift and relies on a trick (side effect in ViewModifier.body) that's normally an anti-pattern.

**Flair:** Open Source (if available) or Library

---

## Hacker News — Show HN

**Best timing:** Tuesday or Wednesday, 9-10am ET (most engaged audience)

**Title (80 char max):**

> Show HN: PixzlSwiftLens – one-line SwiftUI debug HUD with view-render tracking

**URL:** https://github.com/Pixzl/PixzlSwiftLens

**First comment (post within a minute of submission):**

> Author here. I built this because SwiftUI's biggest performance trap isn't slow code — it's views whose bodies get re-evaluated hundreds of times per second because some `@Observable` higher up in the tree is too broad. The existing tools (`Self._printChanges()`, Instruments) are either too noisy or too heavyweight for "I wonder…" debugging.
>
> PixzlSwiftLens is a single `.pixzlSwiftLens()` SwiftUI modifier that gives you an in-app HUD with FPS / RAM (phys_footprint, not resident_size) / CPU / network / OSLog stream, plus the 0.3.0 feature: live per-view body-invalidation rates via `.lensTrack(_:)`.
>
> Technically interesting bits:
> - The view-render counter is a ViewModifier whose `body(content:)` has a side effect. Normally an anti-pattern. In a debug-only opt-in tool it's exactly the signal you want.
> - `URLSessionConfiguration.default` / `.ephemeral` method swizzle via `method_exchangeImplementations`, so requests through `URLSession.shared` are captured without user intervention.
> - The whole thing compiles to `self` outside `#if DEBUG` — verified with `nm` on the Release binary.
>
> Happy to answer questions about the design tradeoffs (why not Pulse, why swizzle, why NSLock over actor for the recorder, etc.).
>
> MIT, Swift 6, iOS 26+.

---

## Individual DMs (Paul Hudson, Antoine van der Lee, Majid Jabrayilov)

**Template — adapt the opening per person:**

> Hi [name],
>
> Built a small open-source SwiftUI debug HUD that does something I haven't seen in other iOS tools: live per-view body-invalidation rates via a one-line `.lensTrack(_:)` modifier. Thought it might be up your alley given [your recent post on X / your work on Y / the Hacking with Swift debug-tool series].
>
> Repo: https://github.com/Pixzl/PixzlSwiftLens
> Blog post with implementation walkthrough: [link after publish]
>
> Would love your take. No obligation to share — if it's not a fit, no worries at all.
>
> Cheers,
> [your name]

**Personalization hints:**
- **Paul Hudson** — mention Hacking with Swift's debug / SwiftUI content if you've enjoyed it
- **Antoine van der Lee** — mentions his Swift Weekly as a reference point
- **Majid Jabrayilov** — compliment his `@Observable` / SwiftUI deep dives; the recorder's write-in-body trick is the kind of thing he writes about well

---

## Swift Forums (optional but worth it)

**Category:** Related Projects

**Title:** PixzlSwiftLens 0.3.0 — SwiftUI debug HUD with live view-render tracking

**Post body:** Use the r/iOSProgramming body above, trim the casual framing, keep the technical substance.

---

## Order of operations

Recommendation:

1. **Day 1, morning:** Publish the blog post (pixzl.de/blog or dev.to)
2. **Day 1, after blog is live:** Submit to iOS Dev Weekly (Dave curates Monday evening)
3. **Day 2, Tuesday 9am ET:** Show HN
4. **Day 2, same morning:** r/iOSProgramming post
5. **Day 2, evening:** Twitter/X thread (linking blog post, not repo directly — blog posts get more engagement on X)
6. **Day 3:** LinkedIn post, Mastodon, individual DMs

Spreading it avoids "launch looks like spam" and gives each channel a clean window to breathe.
