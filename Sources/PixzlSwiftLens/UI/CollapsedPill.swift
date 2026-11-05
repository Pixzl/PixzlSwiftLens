import SwiftUI

struct CollapsedPill: View {
    @Bindable var state: LensState
    let style: PixzlSwiftLensPillStyle

    var body: some View {
        HStack(spacing: 8) {
            metric(value: state.fps, suffix: style == .detailed ? " FPS" : "", color: LensTheme.fpsColor(state.fps, max: state.maxFPS))
            divider
            metric(value: state.memMB, suffix: style == .detailed ? " MB" : "", color: .blue)
            divider
            metric(value: state.cpuPct, suffix: style == .detailed ? "%" : "", color: LensTheme.cpuColor(state.cpuPct))
        }
        .font(LensTheme.pillFont)
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        // Dark-tinted Liquid Glass: matches the system chrome, but the tint keeps the
        // white digits readable over bright app content.
        .glassEffect(
            .regular.tint(LensTheme.glassTint).interactive(),
            in: .rect(cornerRadius: LensTheme.pillCorner)
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
