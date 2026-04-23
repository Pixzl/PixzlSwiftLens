#if DEBUG
import Foundation
import ObjectiveC

/// Swizzles `URLSessionConfiguration.default` and `.ephemeral` so any code that
/// builds a session from one of these configurations — including `URLSession.shared`,
/// which is initialized lazily from `.default` — automatically picks up
/// `PixzlSwiftURLProtocol`.
enum URLSessionSwizzler {
    nonisolated(unsafe) private static var swizzled = false
    private static let lock = NSLock()

    static func installIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        guard !swizzled else { return }
        swizzled = true

        swap(class: URLSessionConfiguration.self,
             original: NSSelectorFromString("default"),
             replacement: #selector(URLSessionConfiguration.pixzl_swizzled_default))
        swap(class: URLSessionConfiguration.self,
             original: NSSelectorFromString("ephemeral"),
             replacement: #selector(URLSessionConfiguration.pixzl_swizzled_ephemeral))
    }

    private static func swap(class cls: AnyClass, original: Selector, replacement: Selector) {
        guard let originalMethod  = class_getClassMethod(cls, original),
              let swizzledMethod = class_getClassMethod(cls, replacement) else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension URLSessionConfiguration {
    @objc class func pixzl_swizzled_default() -> URLSessionConfiguration {
        // After the swizzle, this call lands on the *original* `default()`.
        let config = pixzl_swizzled_default()
        injectProtocol(into: config)
        return config
    }

    @objc class func pixzl_swizzled_ephemeral() -> URLSessionConfiguration {
        let config = pixzl_swizzled_ephemeral()
        injectProtocol(into: config)
        return config
    }

    fileprivate static func injectProtocol(into config: URLSessionConfiguration) {
        var classes = config.protocolClasses ?? []
        if !classes.contains(where: { $0 == PixzlSwiftURLProtocol.self }) {
            classes.insert(PixzlSwiftURLProtocol.self, at: 0)
        }
        config.protocolClasses = classes
    }
}
#endif

