import Foundation

public extension URLSessionConfiguration {
    /// Returns a configuration with PixzlSwiftLens network capture enabled.
    ///
    ///     let session = URLSession(configuration: .pixzlSwiftLens())
    static func pixzlSwiftLens(base: URLSessionConfiguration = .default) -> URLSessionConfiguration {
        var protocols = base.protocolClasses ?? []
        protocols.insert(PixzlSwiftURLProtocol.self, at: 0)
        base.protocolClasses = protocols
        return base
    }
}

public enum PixzlSwiftLensNetwork {
    /// Registers PixzlSwiftLens with the global URL loading system. Required for
    /// requests using `URLSession.shared`. Idempotent; safe to call multiple times.
    @MainActor
    public static func install() {
        guard !installed else { return }
        URLProtocol.registerClass(PixzlSwiftURLProtocol.self)
        installed = true
    }

    @MainActor private static var installed = false
}
