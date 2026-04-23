import Foundation
import Observation

@MainActor
@Observable
final class LensState {
    // Live performance values
    var fps: Int = 0
    var memMB: Int = 0
    var cpuPct: Int = 0

    // Per-sample series for charts (last ~60 samples = ~60s @ 1Hz)
    var fpsHistory: [Int] = []
    var memHistory: [Int] = []
    var cpuHistory: [Int] = []

    // UI state
    var isExpanded: Bool = false
    var selectedTab: LensTab = .performance

    // Mirrored from background recorders — kept on main for SwiftUI bindings
    var networkRecords: [NetworkRecord] = []
    var logs: [LogEntry] = []
    var viewInvalidations: [ViewInvalidationSummary] = []

    // Samplers
    private let fpsSampler = FPSSampler()
    private let memSampler = MemorySampler()
    private let cpuSampler = CPUSampler()
    private var aggregateTask: Task<Void, Never>?
    private var networkPollTask: Task<Void, Never>?
    private var logsPollTask: Task<Void, Never>?
    private var viewsPollTask: Task<Void, Never>?

    func toggleExpanded() {
        isExpanded.toggle()
    }

    func start(panels: PixzlSwiftLensPanels) async {
        if panels.contains(.performance) {
            fpsSampler.start { [weak self] in self?.fps = $0 }
            startAggregateLoop()
        }
        if panels.contains(.network) {
            startNetworkPolling()
        }
        if panels.contains(.logs) {
            startLogsPolling()
        }
        if panels.contains(.views) {
            startViewsPolling()
        }
    }

    func stop() {
        fpsSampler.stop()
        aggregateTask?.cancel()
        networkPollTask?.cancel()
        logsPollTask?.cancel()
        viewsPollTask?.cancel()
    }

    private func startAggregateLoop() {
        aggregateTask?.cancel()
        aggregateTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                memMB = memSampler.sampleMB()
                cpuPct = cpuSampler.samplePercent()
                appendHistory(&fpsHistory, fps)
                appendHistory(&memHistory, memMB)
                appendHistory(&cpuHistory, cpuPct)
            }
        }
    }

    private func startNetworkPolling() {
        networkPollTask?.cancel()
        networkPollTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self else { return }
                self.networkRecords = await NetworkRecorder.shared.snapshot()
            }
        }
    }

    private func startViewsPolling() {
        viewsPollTask?.cancel()
        viewsPollTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self else { return }
                self.viewInvalidations = ViewInvalidationRecorder.shared.snapshot()
            }
        }
    }

    private func startLogsPolling() {
        logsPollTask?.cancel()
        logsPollTask = Task { @MainActor [weak self] in
            let reader = OSLogReader()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                let entries = await reader.fetchSinceLast()
                if !entries.isEmpty {
                    appendLogs(entries)
                }
            }
        }
    }

    private func appendHistory(_ buffer: inout [Int], _ value: Int) {
        buffer.append(value)
        if buffer.count > 60 {
            buffer.removeFirst(buffer.count - 60)
        }
    }

    private func appendLogs(_ new: [LogEntry]) {
        logs.append(contentsOf: new)
        if logs.count > 500 {
            logs.removeFirst(logs.count - 500)
        }
    }
}

enum LensTab: String, CaseIterable, Identifiable {
    case performance, network, logs, views
    var id: String { rawValue }
    var title: String {
        switch self {
        case .performance: "Performance"
        case .network:     "Network"
        case .logs:        "Logs"
        case .views:       "Views"
        }
    }
}
