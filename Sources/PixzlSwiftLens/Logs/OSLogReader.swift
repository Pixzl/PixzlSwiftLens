import Foundation
import OSLog

enum LogLevel: String, Sendable, CaseIterable, Identifiable {
    case debug, info, notice, error, fault
    var id: String { rawValue }

    init(_ level: OSLogEntryLog.Level) {
        switch level {
        case .debug:  self = .debug
        case .info:   self = .info
        case .notice: self = .notice
        case .error:  self = .error
        case .fault:  self = .fault
        case .undefined: self = .info
        @unknown default: self = .info
        }
    }
}

struct LogEntry: Identifiable, Sendable, Equatable {
    let id: UUID
    let date: Date
    let subsystem: String
    let category: String
    let level: LogLevel
    let message: String
}

actor OSLogReader {
    private var lastReadDate: Date?

    func fetchSinceLast() -> [LogEntry] {
        let cutoff = lastReadDate ?? Date().addingTimeInterval(-2)
        let now = Date()
        defer { lastReadDate = now }

        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(date: cutoff)
            let entries = try store.getEntries(at: position)
            var out: [LogEntry] = []
            out.reserveCapacity(64)
            for case let log as OSLogEntryLog in entries where log.date > cutoff {
                out.append(LogEntry(
                    id: UUID(),
                    date: log.date,
                    subsystem: log.subsystem,
                    category: log.category,
                    level: LogLevel(log.level),
                    message: log.composedMessage
                ))
            }
            return out
        } catch {
            return []
        }
    }
}
