import Testing
import Foundation
@testable import PixzlSwiftLens

@Suite("End-to-end network capture", .serialized)
struct EndToEndCaptureTests {

    @Test("PixzlSwiftURLProtocol records a successful GET roundtrip")
    func capturesSuccessfulGET() async throws {
        await NetworkRecorder.shared.clear()
        installMock()
        defer { uninstallMock() }

        MockResponderURLProtocol.register { request in
            let resp = HTTPURLResponse(url: request.url!,
                                       statusCode: 200,
                                       httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": "text/plain"])!
            return (resp, "ok".data(using: .utf8)!)
        }
        defer { MockResponderURLProtocol.reset() }

        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [PixzlSwiftURLProtocol.self]
        let session = URLSession(configuration: cfg)

        let url = URL(string: "https://e2e.test/hello")!
        let (data, response) = try await session.data(from: url)

        #expect(String(data: data, encoding: .utf8) == "ok")
        #expect((response as? HTTPURLResponse)?.statusCode == 200)

        try await waitForRecord(matching: url)
        let records = await NetworkRecorder.shared.snapshot()
        let record = try #require(records.first { $0.url == url })
        #expect(record.method == "GET")
        #expect(record.statusCode == 200)
        #expect(record.responseBody.flatMap { String(data: $0, encoding: .utf8) } == "ok")
        #expect(record.duration != nil)
    }

    @Test("Records a 404 response with status code")
    func capturesNotFound() async throws {
        await NetworkRecorder.shared.clear()
        installMock()
        defer { uninstallMock() }

        MockResponderURLProtocol.register { request in
            let resp = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (resp, Data())
        }
        defer { MockResponderURLProtocol.reset() }

        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [PixzlSwiftURLProtocol.self]
        let session = URLSession(configuration: cfg)

        let url = URL(string: "https://e2e.test/missing")!
        _ = try? await session.data(from: url)

        try await waitForRecord(matching: url)
        let records = await NetworkRecorder.shared.snapshot()
        let record = try #require(records.first { $0.url == url })
        #expect(record.statusCode == 404)
    }

    private func installMock() {
        PixzlSwiftURLProtocol.innerProtocolsLock.lock()
        PixzlSwiftURLProtocol.innerProtocols = [MockResponderURLProtocol.self]
        PixzlSwiftURLProtocol.innerProtocolsLock.unlock()
    }

    private func uninstallMock() {
        PixzlSwiftURLProtocol.innerProtocolsLock.lock()
        PixzlSwiftURLProtocol.innerProtocols = []
        PixzlSwiftURLProtocol.innerProtocolsLock.unlock()
    }

    private func waitForRecord(matching url: URL, timeout: Duration = .seconds(2)) async throws {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while ContinuousClock.now < deadline {
            let snap = await NetworkRecorder.shared.snapshot()
            if snap.contains(where: { $0.url == url && $0.duration != nil }) { return }
            try await Task.sleep(for: .milliseconds(25))
        }
    }
}

/// Test-only protocol that returns canned responses. Lives behind PixzlSwiftURLProtocol
/// in the protocol chain so PixzlSwiftURLProtocol gets first crack at the request,
/// then proxies it via its own URLSession — which routes here.
final class MockResponderURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) private static var responder: ((URLRequest) -> (HTTPURLResponse, Data))?
    private static let lock = NSLock()

    static func register(_ responder: @escaping (URLRequest) -> (HTTPURLResponse, Data)) {
        lock.lock(); defer { lock.unlock() }
        self.responder = responder
    }

    static func reset() {
        lock.lock(); defer { lock.unlock() }
        responder = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "e2e.test"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        let responder = Self.responder
        Self.lock.unlock()
        guard let responder else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        let (response, data) = responder(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
