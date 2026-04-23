import Foundation

struct NetworkRecord: Identifiable, Sendable, Equatable {
    let id: UUID
    let url: URL
    let method: String
    let requestHeaders: [String: String]
    let requestBody: Data?
    let startedAt: Date

    var statusCode: Int?
    var responseHeaders: [String: String]?
    var responseBody: Data?
    /// `true` if `requestBody` was captured but truncated to the capture cap.
    var requestBodyTruncated: Bool = false
    /// `true` if `responseBody` was captured but truncated to the capture cap.
    var responseBodyTruncated: Bool = false
    var errorDescription: String?
    var duration: TimeInterval?

    var isInFlight: Bool { duration == nil && errorDescription == nil }

    var statusEmoji: String {
        if let status = statusCode {
            return (200..<300).contains(status) ? "✓" : "✗"
        }
        if errorDescription != nil { return "⚠" }
        return "⏱"
    }
}

actor NetworkRecorder {
    static let shared = NetworkRecorder()

    private var buffer: [NetworkRecord] = []
    private let capacity = 200

    func append(_ record: NetworkRecord) {
        buffer.append(record)
        trim()
    }

    func update(id: UUID, mutate: (inout NetworkRecord) -> Void) {
        guard let idx = buffer.firstIndex(where: { $0.id == id }) else { return }
        mutate(&buffer[idx])
    }

    func snapshot() -> [NetworkRecord] { buffer }

    func clear() { buffer.removeAll() }

    private func trim() {
        if buffer.count > capacity {
            buffer.removeFirst(buffer.count - capacity)
        }
    }
}
