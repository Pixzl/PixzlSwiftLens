import Testing
@testable import PixzlSwiftLens

@Suite("MemorySampler")
struct MemorySamplerTests {

    @Test("Reports a non-zero physical footprint for the running test process")
    func smokeNonZero() {
        let sampler = MemorySampler()
        let mb = sampler.sampleMB()
        #expect(mb > 0)
        #expect(mb < 100_000) // sanity ceiling
    }
}
