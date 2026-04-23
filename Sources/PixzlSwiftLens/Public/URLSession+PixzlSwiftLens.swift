import Foundation

public extension URLSessionConfiguration {
    /// Returns a configuration with PixzlSwiftLens network capture enabled.
    ///
    ///     let session = URLSession(configuration: .pixzlSwiftLens())
    ///
    /// In Release builds this returns `base` unchanged — zero runtime overhead.
    static func pixzlSwiftLens(base: URLSessionConfiguration = .default) -> URLSessionConfiguration {
        #if DEBUG
        var protocols = base.protocolClasses ?? []
        protocols.insert(PixzlSwiftURLProtocol.self, at: 0)
        base.protocolClasses = protocols
        #endif
        return base
    }
}

public enum PixzlSwiftLensNetwork {
    /// Registers PixzlSwiftLens globally and swizzles `URLSessionConfiguration.default`
    /// / `.ephemeral` so sessions built from either automatically pick up the recorder,
    /// including `URLSession.shared`. Idempotent; safe to call multiple times.
    ///
    /// In Release builds this is a no-op.
    @MainActor
    public static func install() {
        #if DEBUG
        guard !installed else { return }
        URLProtocol.registerClass(PixzlSwiftURLProtocol.self)
        URLSessionSwizzler.installIfNeeded()
        installed = true
        #endif
    }

    /// Unregisters the URLProtocol hook. Note: the configuration-method swizzle
    /// installed by `install()` is process-global and not reverted here — once on,
    /// it stays on for the life of the process.
    ///
    /// In Release builds this is a no-op.
    @MainActor
    public static func uninstall() {
        #if DEBUG
        guard installed else { return }
        URLProtocol.unregisterClass(PixzlSwiftURLProtocol.self)
        installed = false
        #endif
    }

    #if DEBUG
    @MainActor private static var installed = false
    #endif
}
