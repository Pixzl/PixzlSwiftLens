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
    /// Cursor into the OSLogStore, expressed as seconds-since-latest-boot. Using
    /// uptime (monotonic) instead of a wall-clock `Date` makes the reader immune
    /// to NTP syncs and manual clock adjustments — previously those could drop
    /// logs (clock jumps forward) or duplicate them (clock jumps backward).
    private var lastReadUptime: TimeInterval?

    func fetchSinceLast() -> [LogEntry] {
        let nowUptime = ProcessInfo.processInfo.systemUptime
        // On first call, reach back ~2s to pick up warmup logs.
        let cutoffUptime = max(0, lastReadUptime ?? (nowUptime - 2))
        defer { lastReadUptime = nowUptime }

        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(timeIntervalSinceLatestBoot: cutoffUptime)
            let entries = try store.getEntries(at: position)
            var out: [LogEntry] = []
            out.reserveCapacity(64)
            for case let log as OSLogEntryLog in entries {
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
