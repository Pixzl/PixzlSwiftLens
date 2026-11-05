import SwiftUI

struct ExpandedPanel: View {
    @Bindable var state: LensState
    let config: PixzlSwiftLensConfig

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("PixzlSwiftLens")
                .lensInlineNavigationTitle()
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(role: .close) { state.isExpanded = false }
                    }
                }
                .safeAreaInset(edge: .top) {
                    tabBar
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state.selectedTab {
        case .performance: PerformancePanel(state: state)
        case .network:     NetworkPanel(state: state)
        case .logs:        LogsPanel(state: state)
        case .views:       ViewsPanel(state: state)
        }
    }

    @ViewBuilder
    private var tabBar: some View {
        if availableTabs.count > 1 {
            Picker("Panel", selection: $state.selectedTab) {
                ForEach(availableTabs) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var availableTabs: [LensTab] {
        LensTab.allCases.filter { config.panels.contains($0.panel) }
    }
}
