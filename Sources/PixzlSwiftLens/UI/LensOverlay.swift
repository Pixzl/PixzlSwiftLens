import SwiftUI

struct LensOverlay: View {
    @Bindable var state: LensState
    let config: PixzlSwiftLensConfig

    var body: some View {
        Group {
            if config.activator == .floatingButton {
                FloatingButton { state.toggleExpanded() }
            } else if config.pillStyle != .hidden {
                CollapsedPill(state: state, style: config.pillStyle)
                    .onTapGesture { state.toggleExpanded() }
            }
        }
        .sheet(isPresented: $state.isExpanded) {
            ExpandedPanel(state: state, config: config)
                .presentationDetents([.medium, .large])
                .presentationBackground(.regularMaterial)
        }
    }
}
