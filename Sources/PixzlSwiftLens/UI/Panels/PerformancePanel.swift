import SwiftUI
import Charts

struct PerformancePanel: View {
    @Bindable var state: LensState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                metricCard(title: "FPS",  current: state.fps,    series: state.fpsHistory, range: 0...60,  color: LensTheme.fpsColor(state.fps))
                metricCard(title: "RAM",  current: state.memMB,  series: state.memHistory, range: 0...max(256, (state.memHistory.max() ?? 0) + 50), color: .blue, suffix: " MB")
                metricCard(title: "CPU",  current: state.cpuPct, series: state.cpuHistory, range: 0...100, color: LensTheme.cpuColor(state.cpuPct), suffix: "%")
            }
            .padding()
        }
    }

    private func metricCard(title: String,
                            current: Int,
                            series: [Int],
                            range: ClosedRange<Int>,
                            color: Color,
                            suffix: String = "") -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text("\(current)\(suffix)")
                    .font(.system(.title2, design: .monospaced).weight(.bold))
                    .foregroundStyle(color)
            }
            Chart(Array(series.enumerated()), id: \.offset) { idx, value in
                LineMark(x: .value("t", idx), y: .value("v", value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(color.gradient)
                AreaMark(x: .value("t", idx), y: .value("v", value))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(color.opacity(0.15).gradient)
            }
            .chartYScale(domain: Double(range.lowerBound)...Double(range.upperBound))
            .chartXAxis(.hidden)
            .frame(height: 80)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.1)))
    }
}
