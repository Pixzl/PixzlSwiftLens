import SwiftUI

extension View {
    @ViewBuilder
    func lensInlineNavigationTitle() -> some View {
        #if canImport(UIKit)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

enum LensTheme {
    static let pillFont    = Font.system(.caption, design: .monospaced).weight(.semibold)
    static let pillCorner  = 14.0
    static let panelCorner = 18.0
    /// Tint for the pill and floating button glass. Both also force the dark color
    /// scheme, so the metric colors stay bright in light mode too.
    static let glassTint   = Color.black.opacity(0.65)

    /// Colors relative to the display's maximum, so 60 FPS reads as green on a
    /// 60 Hz screen and as orange on a 120 Hz ProMotion screen.
    static func fpsColor(_ fps: Int, max maxFPS: Int) -> Color {
        let ratio = Double(fps) / Double(Swift.max(maxFPS, 1))
        switch ratio {
        case ..<0.5: return .red
        case ..<0.9: return .orange
        default:     return .green
        }
    }

    static func cpuColor(_ pct: Int) -> Color {
        switch pct {
        case ..<40: .green
        case 40..<75: .orange
        default: .red
        }
    }
}
