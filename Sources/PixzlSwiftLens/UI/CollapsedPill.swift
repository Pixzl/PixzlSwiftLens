import SwiftUI

struct CollapsedPill: View {
    @Bindable var state: LensState
    let style: PixzlSwiftLensPillStyle

    var body: some View {
        HStack(spacing: 8) {
            metric(value: state.fps, suffix: style == .detailed ? " FPS" : "", color: LensTheme.fpsColor(state.fps))
            divider
            metric(value: state.memMB, suffix: style == .detailed ? " MB" : "", color: .blue)
            divider
            metric(value: state.cpuPct, suffix: style == .detailed ? "%" : "", color: LensTheme.cpuColor(state.cpuPct))
        }
        .font(LensTheme.pillFont)
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: LensTheme.pillCorner, style: .continuous)
                .fill(.black.opacity(0.72))
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
        )
    }

    private func metric(value: Int, suffix: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Text("\(value)").foregroundStyle(color)
            if !suffix.isEmpty { Text(suffix).foregroundStyle(.white.opacity(0.7)) }
        }
    }

    private var divider: some View {
        Text("·").foregroundStyle(.white.opacity(0.4))
    }
}
