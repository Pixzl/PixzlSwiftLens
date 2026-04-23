import Foundation

/// A summary of one tracked view's body-invalidation history, rendered in the Views panel.
struct ViewInvalidationSummary: Identifiable, Sendable, Equatable {
    var id: String { name }
    let name: String
    let total: Int
    let last: Date?
    /// Rolling rate over the last second, invalidations per second.
    let recentRate: Double
}

/// Thread-safe, lock-based counter of SwiftUI body re-evaluations per named view.
///
/// Writes happen synchronously from `LensTrackModifier.body(content:)` — a hot path that
/// can fire dozens of times per second per tracked view. An actor would require each
/// write to hop through a Task, which is too expensive; `NSLock` around a dictionary
/// is cheap enough to stay off the frame budget.
final class ViewInvalidationRecorder: @unchecked Sendable {
    static let shared = ViewInvalidationRecorder()

    private let lock = NSLock()
    private var counters: [String: Counter] = [:]

    /// Records one body invalidation for the named view. Safe to call from any thread.
    func record(name: String, at date: Date = Date()) {
        lock.lock()
        defer { lock.unlock() }
        counters[name, default: Counter()].tick(at: date)
    }

    /// Returns a snapshot of all currently tracked views, unsorted.
    func snapshot(now: Date = Date()) -> [ViewInvalidationSummary] {
        lock.lock()
        defer { lock.unlock() }
        return counters.map { name, counter in
            ViewInvalidationSummary(
                name: name,
                total: counter.total,
                last: counter.lastTick,
                recentRate: counter.rate(over: 1, now: now)
            )
        }
    }

    /// Clears all counters. Used by tests and "reset" affordances.
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        counters.removeAll()
    }

    private struct Counter {
        var total: Int = 0
        var lastTick: Date?
        /// Sliding window of recent tick timestamps, used to compute the live rate.
        /// Capped at 2 seconds of history so it stays cheap even at high invalidation rates.
        var recent: [Date] = []

        mutating func tick(at date: Date) {
            total += 1
            lastTick = date
            recent.append(date)
            let cutoff = date.addingTimeInterval(-2)
            while let first = recent.first, first < cutoff {
                recent.removeFirst()
            }
        }

        func rate(over seconds: Double, now: Date) -> Double {
            let cutoff = now.addingTimeInterval(-seconds)
            let count = recent.reversed().prefix(while: { $0 >= cutoff }).count
            return Double(count) / seconds
        }
    }
}
