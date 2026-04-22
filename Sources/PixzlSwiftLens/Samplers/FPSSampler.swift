#if canImport(UIKit)
import QuartzCore

@MainActor
final class FPSSampler {
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var onUpdate: (@MainActor (Int) -> Void)?

    func start(onUpdate: @escaping @MainActor (Int) -> Void) {
        self.onUpdate = onUpdate
        stop()
        let target = ProxyTarget { [weak self] link in self?.tick(link) }
        let link = CADisplayLink(target: target, selector: #selector(ProxyTarget.handle(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = 0
        frameCount = 0
    }

    private func tick(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        frameCount += 1
        let delta = link.timestamp - lastTimestamp
        if delta >= 1.0 {
            let fps = Int(round(Double(frameCount) / delta))
            onUpdate?(fps)
            frameCount = 0
            lastTimestamp = link.timestamp
        }
    }
}

private final class ProxyTarget: NSObject {
    let handler: (CADisplayLink) -> Void
    init(_ handler: @escaping (CADisplayLink) -> Void) { self.handler = handler }
    @objc func handle(_ link: CADisplayLink) { handler(link) }
}
#else
@MainActor
final class FPSSampler {
    func start(onUpdate: @escaping @MainActor (Int) -> Void) {}
    func stop() {}
}
#endif
