#if canImport(UIKit)
import UIKit

@MainActor
final class ThreeFingerTapDetector: NSObject {
    static let shared = ThreeFingerTapDetector()
    private var installed = false
    private var attempts = 0

    func install() {
        guard !installed else { return }
        installed = true
        attach()
    }

    private func attach() {
        // With several scenes (iPad multitasking, external display) `.first` can be a
        // background scene; prefer the one the user is interacting with.
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first,
              let window = scene.keyWindow ?? scene.windows.first
        else {
            attempts += 1
            guard attempts < 20 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in self?.attach() }
            return
        }
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        recognizer.numberOfTouchesRequired = 3
        recognizer.cancelsTouchesInView = false
        window.addGestureRecognizer(recognizer)
    }

    @objc private func handleTap() {
        NotificationCenter.default.post(name: .pixzlSwiftLensDeviceShake, object: nil)
    }
}
#endif
