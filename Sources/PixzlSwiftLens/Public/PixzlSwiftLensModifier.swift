import SwiftUI

public extension View {
    /// Drop-in debug HUD overlay. Shows a floating performance pill (FPS / RAM / CPU)
    /// that expands into a full inspector (network, logs, performance graph) on activation.
    ///
    /// In `RELEASE` builds this modifier is a no-op and contributes zero runtime overhead.
    func pixzlSwiftLens(
        activator: PixzlSwiftLensActivator = .shake,
        panels: PixzlSwiftLensPanels = .all,
        position: PixzlSwiftLensPosition = .topTrailing,
        pillStyle: PixzlSwiftLensPillStyle = .compact
    ) -> some View {
        #if DEBUG
        modifier(PixzlSwiftLensModifier(
            config: PixzlSwiftLensConfig(
                activator: activator,
                panels: panels,
                position: position,
                pillStyle: pillStyle
            )
        ))
        #else
        self
        #endif
    }
}

#if DEBUG
struct PixzlSwiftLensModifier: ViewModifier {
    let config: PixzlSwiftLensConfig
    @State private var state = LensState()

    func body(content: Content) -> some View {
        content
            .overlay(alignment: config.position.alignment) {
                LensOverlay(state: state, config: config)
                    .allowsHitTesting(true)
                    .padding(8)
                    .accessibilityIdentifier("PixzlSwiftLens.Overlay")
            }
            .task {
                await state.start(panels: config.panels)
                #if canImport(UIKit)
                if config.activator == .threeFingerTap {
                    ThreeFingerTapDetector.shared.install()
                }
                #endif
            }
            .onShake(enabled: config.activator == .shake) {
                state.toggleExpanded()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pixzlSwiftLensDeviceShake)) { _ in
                guard config.activator == .threeFingerTap else { return }
                state.toggleExpanded()
            }
    }
}
#endif
