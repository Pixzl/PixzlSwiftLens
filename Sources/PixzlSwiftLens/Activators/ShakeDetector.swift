import SwiftUI

/// Posted whenever a configured activator (shake, three-finger tap, programmatic toggle)
/// wants the HUD to expand. Cross-platform so the modifier can subscribe unconditionally.
extension Notification.Name {
    static let pixzlSwiftLensDeviceShake = Notification.Name("com.pixzl.swiftlens.deviceShake")
}

#if canImport(UIKit)
import UIKit

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: .pixzlSwiftLensDeviceShake, object: nil)
        }
    }
}

extension View {
    func onShake(enabled: Bool, perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .pixzlSwiftLensDeviceShake)) { _ in
            guard enabled else { return }
            action()
        }
    }
}
#else
extension View {
    func onShake(enabled: Bool, perform action: @escaping () -> Void) -> some View { self }
}
#endif
