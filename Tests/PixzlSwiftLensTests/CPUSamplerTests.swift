import Testing
@testable import PixzlSwiftLens

@Suite("CPUSampler")
struct CPUSamplerTests {

    @Test("Returns a percent in 0...100")
    func returnsValidPercent() {
        let sampler = CPUSampler()
        let pct = sampler.samplePercent()
        #expect(pct >= 0)
        #expect(pct <= 100)
    }
}
