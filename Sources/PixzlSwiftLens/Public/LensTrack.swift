import SwiftUI

public extension View {
    /// Tracks SwiftUI body re-evaluations of this view and surfaces them live in the
    /// PixzlSwiftLens "Views" panel with per-view counts and rates.
    ///
    ///     CartView()
    ///         .lensTrack("Cart")
    ///
    /// Every time SwiftUI re-evaluates this position in the view tree, an invalidation
    /// tick is recorded — letting you spot views that rerender far more often than
    /// expected (a common sign that parent state is scoped too broadly).
    ///
    /// Pass a stable, meaningful name. If the same view type appears in multiple
    /// places, use distinct names per instance to keep them separate in the panel.
    ///
    /// In Release builds this modifier is a no-op and collapses to `self` — zero
    /// runtime overhead.
    func lensTrack(_ name: String) -> some View {
        #if DEBUG
        modifier(LensTrackModifier(name: name))
        #else
        self
        #endif
    }
}

#if DEBUG
struct LensTrackModifier: ViewModifier {
    let name: String

    func body(content: Content) -> some View {
        ViewInvalidationRecorder.shared.record(name: name)
        return content
    }
}
#endif
