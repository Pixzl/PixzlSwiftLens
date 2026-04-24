#if DEBUG
import Foundation

final class PixzlSwiftURLProtocol: URLProtocol, @unchecked Sendable {
    private static let handledKey = "com.pixzl.swiftlens.handled"

    /// Upper bound on captured request/response body bytes per record. Bodies larger
    /// than this are truncated in the recorder (but still forwarded in full to the
    /// client). Keeps the recorder cheap even on large downloads.
    static let maxCapturedBodyBytes = 256 * 1024

    /// Test-only seam: prepends additional URLProtocol classes onto the inner
    /// session's chain, so tests can inject a mock responder behind the recorder.
    nonisolated(unsafe) static var innerProtocols: [AnyClass] = []
    static let innerProtocolsLock = NSLock()

    private var dataTask: URLSessionDataTask?
    private var session: URLSession?
    private var recordID: UUID?
    private var startTime: Date = Date()
    private var responseBuffer = Data()
    private var responseTruncated = false

    override class func canInit(with request: URLRequest) -> Bool {
        guard URLProtocol.property(forKey: handledKey, in: request) == nil else { return false }
        let scheme = request.url?.scheme?.lowercased() ?? ""
        return scheme == "http" || scheme == "https"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let mutable = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutable)

        let id = UUID()
        recordID = id
        startTime = Date()

        let rawBody = request.httpBody ?? request.bodyStreamData()
        let cap = Self.maxCapturedBodyBytes
        let requestTruncated = (rawBody?.count ?? 0) > cap
        let capturedBody: Data? = rawBody.map { $0.count > cap ? Data($0.prefix(cap)) : $0 }
        var record = NetworkRecord(
            id: id,
            url: request.url ?? URL(string: "about:blank")!,
            method: request.httpMethod ?? "GET",
            requestHeaders: request.allHTTPHeaderFields ?? [:],
            requestBody: capturedBody,
            startedAt: startTime
        )
        record.requestBodyTruncated = requestTruncated
        Task { await NetworkRecorder.shared.append(record) }

        let delegate = PixzlSwiftProtocolDelegate(parent: self)
        // Known limitation: we proxy via a fresh .default config, so the original
        // session's auth / timeout / cookie / redirect settings are not preserved.
        // See AGENTS.md > "PixzlSwiftURLProtocol.startLoading() proxies …".
        let cfg = URLSessionConfiguration.default
        Self.innerProtocolsLock.lock()
        let extras = Self.innerProtocols
        Self.innerProtocolsLock.unlock()
        cfg.protocolClasses = extras + (cfg.protocolClasses ?? []).filter { $0 != PixzlSwiftURLProtocol.self }
        let session = URLSession(configuration: cfg, delegate: delegate, delegateQueue: nil)
        self.session = session
        let task = session.dataTask(with: mutable as URLRequest)
        dataTask = task
        task.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
        session?.invalidateAndCancel()
        session = nil
    }

    fileprivate func didReceiveResponse(_ response: URLResponse) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }

    fileprivate func didReceiveData(_ data: Data) {
        let cap = Self.maxCapturedBodyBytes
        if responseBuffer.count < cap {
            let remaining = cap - responseBuffer.count
            if data.count <= remaining {
                responseBuffer.append(data)
            } else {
                responseBuffer.append(data.prefix(remaining))
                responseTruncated = true
            }
        } else {
            responseTruncated = true
        }
        client?.urlProtocol(self, didLoad: data)
    }

    fileprivate func didComplete(error: (any Error)?) {
        let duration = Date().timeIntervalSince(startTime)
        let httpResp = dataTask?.response as? HTTPURLResponse
        let body = responseBuffer
        let truncated = responseTruncated
        let errDesc = error.map { String(describing: $0) }
        let id = recordID

        Task {
            guard let id else { return }
            await NetworkRecorder.shared.update(id: id) { rec in
                rec.statusCode = httpResp?.statusCode
                rec.responseHeaders = httpResp?.allHeaderFields.reduce(into: [String: String]()) { acc, kv in
                    if let k = kv.key as? String { acc[k] = String(describing: kv.value) }
                }
                rec.responseBody = body.isEmpty ? nil : body
                rec.responseBodyTruncated = truncated
                rec.errorDescription = errDesc
                rec.duration = duration
            }
        }

        if let error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}

private final class PixzlSwiftProtocolDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    weak var parent: PixzlSwiftURLProtocol?
    init(parent: PixzlSwiftURLProtocol) { self.parent = parent }

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        parent?.didReceiveResponse(response)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        parent?.didReceiveData(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        parent?.didComplete(error: error)
    }
}

extension URLRequest {
    /// Reads the body from `httpBodyStream` if `httpBody` is nil. Returns nil when neither is set.
    func bodyStreamData() -> Data? {
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data.isEmpty ? nil : data
    }
}
#endif

