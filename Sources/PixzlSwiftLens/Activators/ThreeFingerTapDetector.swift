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
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first
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
