#if canImport(UIKit)
import QuartzCore
import UIKit

@MainActor
final class FPSSampler {
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var onUpdate: (@MainActor (Int) -> Void)?

    /// Highest rate a display link can fire at in this app. ProMotion screens run at
    /// 120 Hz, but iPhone caps display links at 60 Hz unless the host app sets
    /// `CADisableMinimumFrameDurationOnPhone` in its Info.plist. iPad needs no key.
    static func maximumFPS() -> Int {
        let screenMax = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen.maximumFramesPerSecond }
            .max() ?? 60
        if UIDevice.current.userInterfaceIdiom == .phone,
           Bundle.main.object(forInfoDictionaryKey: "CADisableMinimumFrameDurationOnPhone") as? Bool != true {
            return min(screenMax, 60)
        }
        return max(screenMax, 1)
    }

    func start(onUpdate: @escaping @MainActor (Int) -> Void) {
        self.onUpdate = onUpdate
        stop()
        let target = ProxyTarget { [weak self] link in self?.tick(link) }
        let link = CADisplayLink(target: target, selector: #selector(ProxyTarget.handle(_:)))
        // Without an explicit range the system may throttle the link below the
        // screen's maximum, and the HUD would report that throttle as dropped frames.
        let maxFPS = Float(Self.maximumFPS())
        link.preferredFrameRateRange = CAFrameRateRange(minimum: min(30, maxFPS), maximum: maxFPS, preferred: maxFPS)
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
    static func maximumFPS() -> Int { 60 }
    func start(onUpdate: @escaping @MainActor (Int) -> Void) {}
    func stop() {}
}
#endif
