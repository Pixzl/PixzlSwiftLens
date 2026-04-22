import SwiftUI

struct LogsPanel: View {
    @Bindable var state: LensState
    @State private var query: String = ""
    @State private var levelFilter: Set<LogLevel> = Set(LogLevel.allCases)

    var body: some View {
        VStack(spacing: 0) {
            levelFilterBar
            List {
                ForEach(filtered.reversed()) { entry in
                    LogRow(entry: entry)
                }
            }
            .listStyle(.plain)
            .overlay {
                if state.logs.isEmpty {
                    ContentUnavailableView("No logs yet",
                                           systemImage: "doc.text.magnifyingglass",
                                           description: Text("Emit via Logger or os_log; entries appear within ~1s."))
                }
            }
        }
        .searchable(text: $query, prompt: "Filter logs")
    }

    private var levelFilterBar: some View {
        HStack(spacing: 6) {
            ForEach(LogLevel.allCases) { level in
                Button {
                    if levelFilter.contains(level) {
                        levelFilter.remove(level)
                    } else {
                        levelFilter.insert(level)
                    }
                } label: {
                    Text(level.rawValue)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(
                            Capsule().fill(levelFilter.contains(level) ? color(for: level).opacity(0.25) : Color.gray.opacity(0.1))
                        )
                        .foregroundStyle(levelFilter.contains(level) ? color(for: level) : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private var filtered: [LogEntry] {
        state.logs.filter { entry in
            guard levelFilter.contains(entry.level) else { return false }
            guard !query.isEmpty else { return true }
            let q = query.lowercased()
            return entry.message.lowercased().contains(q)
                || entry.subsystem.lowercased().contains(q)
                || entry.category.lowercased().contains(q)
        }
    }

    func color(for level: LogLevel) -> Color {
        switch level {
        case .debug:  .gray
        case .info:   .blue
        case .notice: .teal
        case .error:  .orange
        case .fault:  .red
        }
    }
}

struct LogRow: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(entry.level.rawValue.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color(for: entry.level))
                Text(entry.subsystem.isEmpty ? entry.category : "\(entry.subsystem) · \(entry.category)")
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text(entry.date, format: .dateTime.hour().minute().second())
                    .font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
            Text(entry.message)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    func color(for level: LogLevel) -> Color {
        switch level {
        case .debug:  .gray
        case .info:   .blue
        case .notice: .teal
        case .error:  .orange
        case .fault:  .red
        }
    }
}
