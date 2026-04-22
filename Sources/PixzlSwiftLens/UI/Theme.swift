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

    static func fpsColor(_ fps: Int) -> Color {
        switch fps {
        case ..<30: .red
        case 30..<55: .orange
        default: .green
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
