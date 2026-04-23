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
                        Button("Done") { state.isExpanded = false }
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

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(availableTabs) { tab in
                Button { state.selectedTab = tab } label: {
                    Text(tab.title)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(state.selectedTab == tab ? Color.accentColor : Color.gray.opacity(0.2))
                        )
                        .foregroundStyle(state.selectedTab == tab ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var availableTabs: [LensTab] {
        var tabs: [LensTab] = []
        if config.panels.contains(.performance) { tabs.append(.performance) }
        if config.panels.contains(.network)     { tabs.append(.network) }
        if config.panels.contains(.logs)        { tabs.append(.logs) }
        if config.panels.contains(.views)       { tabs.append(.views) }
        return tabs
    }
}
