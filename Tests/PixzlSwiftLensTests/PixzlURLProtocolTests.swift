import Testing
import Foundation
@testable import PixzlSwiftLens

@Suite("PixzlSwiftURLProtocol")
struct PixzlSwiftURLProtocolTests {

    @Test("canInit accepts http and https, rejects file")
    func canInitFiltersScheme() {
        let http  = URLRequest(url: URL(string: "http://x.example/")!)
        let https = URLRequest(url: URL(string: "https://x.example/")!)
        let file  = URLRequest(url: URL(string: "file:///tmp/x")!)
        #expect(PixzlSwiftURLProtocol.canInit(with: http) == true)
        #expect(PixzlSwiftURLProtocol.canInit(with: https) == true)
        #expect(PixzlSwiftURLProtocol.canInit(with: file) == false)
    }

    @Test("Configuration helper inserts protocol class")
    func configHelperInserts() {
        let cfg = URLSessionConfiguration.pixzlSwiftLens()
        let names = (cfg.protocolClasses ?? []).map { String(describing: $0) }
        #expect(names.contains("PixzlSwiftURLProtocol"))
    }
}
