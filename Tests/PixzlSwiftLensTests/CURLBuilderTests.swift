import Testing
import Foundation
@testable import PixzlSwiftLens

@Suite("CURLBuilder")
struct CURLBuilderTests {

    @Test("Basic GET produces minimal cURL")
    func basicGET() {
        let record = NetworkRecord(
            id: UUID(),
            url: URL(string: "https://api.example.com/users")!,
            method: "GET",
            requestHeaders: ["Accept": "application/json"],
            requestBody: nil,
            startedAt: Date()
        )
        let curl = CURLBuilder.build(record)
        #expect(curl.contains("curl -X GET"))
        #expect(curl.contains("-H 'Accept: application/json'"))
        #expect(curl.contains("'https://api.example.com/users'"))
    }

    @Test("POST with body includes --data-raw")
    func postWithBody() {
        let body = #"{"name":"alice"}"#.data(using: .utf8)!
        let record = NetworkRecord(
            id: UUID(),
            url: URL(string: "https://api.example.com/users")!,
            method: "POST",
            requestHeaders: ["Content-Type": "application/json"],
            requestBody: body,
            startedAt: Date()
        )
        let curl = CURLBuilder.build(record)
        #expect(curl.contains("curl -X POST"))
        #expect(curl.contains(#"--data-raw '{"name":"alice"}'"#))
    }

    @Test("Single quotes in body are escaped")
    func singleQuoteEscaping() {
        let body = "it's fine".data(using: .utf8)!
        let record = NetworkRecord(
            id: UUID(),
            url: URL(string: "https://x.example/")!,
            method: "POST",
            requestHeaders: [:],
            requestBody: body,
            startedAt: Date()
        )
        let curl = CURLBuilder.build(record)
        #expect(curl.contains(#"'it'\''s fine'"#))
    }

    @Test("Headers are sorted alphabetically for stable output")
    func sortedHeaders() {
        let record = NetworkRecord(
            id: UUID(),
            url: URL(string: "https://x.example/")!,
            method: "GET",
            requestHeaders: ["Z-Header": "1", "A-Header": "2"],
            requestBody: nil,
            startedAt: Date()
        )
        let curl = CURLBuilder.build(record)
        let aIndex = curl.range(of: "A-Header")!.lowerBound
        let zIndex = curl.range(of: "Z-Header")!.lowerBound
        #expect(aIndex < zIndex)
    }
}
