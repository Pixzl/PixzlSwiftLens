import Testing
import Foundation
@testable import PixzlSwiftLens

@Suite("ViewInvalidationRecorder", .serialized)
struct ViewInvalidationRecorderTests {

    @Test("Record increments total and updates lastTick")
    func recordIncrementsTotal() {
        let recorder = ViewInvalidationRecorder()
        let t = Date()
        recorder.record(name: "Cart", at: t)
        recorder.record(name: "Cart", at: t.addingTimeInterval(0.01))
        recorder.record(name: "Cart", at: t.addingTimeInterval(0.02))

        let snap = recorder.snapshot(now: t.addingTimeInterval(0.02))
        #expect(snap.count == 1)
        let cart = try! #require(snap.first)
        #expect(cart.name == "Cart")
        #expect(cart.total == 3)
        #expect(cart.last == t.addingTimeInterval(0.02))
    }

    @Test("Separate names are tracked independently")
    func separateNames() {
        let recorder = ViewInvalidationRecorder()
        let t = Date()
        recorder.record(name: "A", at: t)
        recorder.record(name: "A", at: t)
        recorder.record(name: "B", at: t)

        let snap = recorder.snapshot(now: t).sorted { $0.name < $1.name }
        #expect(snap.map(\.name) == ["A", "B"])
        #expect(snap[0].total == 2)
        #expect(snap[1].total == 1)
    }

    @Test("Rate over 1s counts ticks inside the window")
    func rateOverOneSecond() {
        let recorder = ViewInvalidationRecorder()
        let now = Date()
        // 10 ticks spread over the last 0.9 seconds → rate ≈ 10 / 1 = 10
        for i in 0..<10 {
            recorder.record(name: "Hot", at: now.addingTimeInterval(-0.9 + Double(i) * 0.09))
        }
        let snap = recorder.snapshot(now: now)
        let row = try! #require(snap.first { $0.name == "Hot" })
        #expect(row.recentRate == 10)
    }

    @Test("Ticks older than 2s do not inflate the window")
    func oldTicksPruned() {
        let recorder = ViewInvalidationRecorder()
        let now = Date()
        // 5 old ticks (3 seconds ago) — should be pruned
        for _ in 0..<5 {
            recorder.record(name: "Old", at: now.addingTimeInterval(-3))
        }
        // 2 fresh ticks in last 0.5s
        recorder.record(name: "Old", at: now.addingTimeInterval(-0.2))
        recorder.record(name: "Old", at: now.addingTimeInterval(-0.1))

        let snap = recorder.snapshot(now: now)
        let row = try! #require(snap.first { $0.name == "Old" })
        #expect(row.total == 7)
        #expect(row.recentRate == 2)
    }

    @Test("reset() clears all counters")
    func resetClears() {
        let recorder = ViewInvalidationRecorder()
        recorder.record(name: "X")
        recorder.reset()
        #expect(recorder.snapshot().isEmpty)
    }
}
