import SwiftUI

struct ViewsPanel: View {
    @Bindable var state: LensState

    var body: some View {
        List {
            ForEach(sorted) { summary in
                ViewInvalidationRow(summary: summary)
            }
        }
        .listStyle(.plain)
        .overlay {
            if state.viewInvalidations.isEmpty {
                ContentUnavailableView(
                    "No tracked views",
                    systemImage: "eye.slash",
                    description: Text("Add `.lensTrack(\"Cart\")` to any View to see its body-invalidation rate here.")
                )
            }
        }
        .animation(.easeOut(duration: 0.2), value: state.viewInvalidations)
    }

    private var sorted: [ViewInvalidationSummary] {
        state.viewInvalidations.sorted { $0.recentRate > $1.recentRate }
    }
}

struct ViewInvalidationRow: View {
    let summary: ViewInvalidationSummary

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("\(summary.total) total")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f/s", summary.recentRate))
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                    .foregroundStyle(rateColor)
                if summary.recentRate >= 15 {
                    Text("hot")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Capsule().fill(Color.red.opacity(0.2)))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var rateColor: Color {
        switch summary.recentRate {
        case ..<1:        .secondary
        case 1..<5:       .primary
        case 5..<15:      .orange
        default:          .red
        }
    }
}
