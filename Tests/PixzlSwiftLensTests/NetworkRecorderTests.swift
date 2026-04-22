import Testing
import Foundation
@testable import PixzlSwiftLens

@Suite("NetworkRecorder")
struct NetworkRecorderTests {

    @Test("Snapshot reflects appended records")
    func snapshotReflectsAppends() async {
        let recorder = NetworkRecorder()
        let r1 = makeRecord(method: "GET")
        let r2 = makeRecord(method: "POST")
        await recorder.append(r1)
        await recorder.append(r2)
        let snap = await recorder.snapshot()
        #expect(snap.count == 2)
        #expect(snap.first?.method == "GET")
        #expect(snap.last?.method == "POST")
    }

    @Test("Update mutates in place")
    func updateMutates() async {
        let recorder = NetworkRecorder()
        let record = makeRecord(method: "GET")
        await recorder.append(record)
        await recorder.update(id: record.id) { rec in
            rec.statusCode = 201
            rec.duration = 0.123
        }
        let snap = await recorder.snapshot()
        #expect(snap.first?.statusCode == 201)
        #expect(snap.first?.duration == 0.123)
    }

    @Test("Ring buffer caps at capacity")
    func ringBufferCaps() async {
        let recorder = NetworkRecorder()
        for _ in 0..<250 {
            await recorder.append(makeRecord(method: "GET"))
        }
        let snap = await recorder.snapshot()
        #expect(snap.count == 200)
    }

    private func makeRecord(method: String) -> NetworkRecord {
        NetworkRecord(
            id: UUID(),
            url: URL(string: "https://x.example/")!,
            method: method,
            requestHeaders: [:],
            requestBody: nil,
            startedAt: Date()
        )
    }
}
