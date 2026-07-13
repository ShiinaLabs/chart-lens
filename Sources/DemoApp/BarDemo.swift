import SwiftUI
import ChartLens

struct BarDemo: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 360))], spacing: 20) {
                DemoCard(title: "Basic Columns") { basicColumns }
                DemoCard(title: "Negative Values (Signal)") { negativeBars }
                DemoCard(title: "Baseline-Anchored") { baselineBars }
                DemoCard(title: "Per-bar Color") { coloredBars }
            }
            .padding()
        }
    }

    private var basicColumns: some View {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let points = days.enumerated().map { i, d in
            ChartPoint(x: Double(i), y: Double.random(in: 20...90), xLabel: d)
        }
        return Chart(
            series: [ChartSeries.bars(id: "bars", points: points, color: .blue, opacity: 0.85)],
            axis: ChartAxisConfig(yMin: 0, yMax: 100, yStep: 20, padXByHalfStep: true)
        )
    }

    private var negativeBars: some View {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let points = days.enumerated().map { i, d in
            ChartPoint(x: Double(i), y: -50 - 20 * sin(Double(i) / 1.5), xLabel: d)
        }
        return Chart(
            series: [ChartSeries.bars(id: "signal", points: points, color: .green, opacity: 0.85)],
            axis: ChartAxisConfig(yMin: -80, yMax: -10, yStep: 10, padXByHalfStep: true)
        )
    }

    private var baselineBars: some View {
        let labels = ["A", "B", "C", "D", "E", "F"]
        let values = [-60, -40, -55, -30, -45, -35]
        let points = labels.enumerated().map { i, l in
            ChartPoint(x: Double(i), y: Double(values[i]), xLabel: l)
        }
        // Explicit non-zero baseline (-50) to show anchoring above/below it.
        let style = ChartSeriesStyle(color: .orange, lineWidth: 1, areaOpacity: 0.85, baseline: -50)
        return Chart(
            series: [ChartSeries(id: "levels", points: points, style: style, renderer: BarRenderer())],
            axis: ChartAxisConfig(yMin: -70, yMax: -20, yStep: 10, padXByHalfStep: true)
        )
    }

    private var coloredBars: some View {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let palette: [Color] = [.red, .orange, .yellow, .green, .blue, .indigo, .purple]
        let points = days.enumerated().map { i, d in
            ChartPoint(
                x: Double(i),
                y: Double.random(in: 20...90),
                color: palette[i % palette.count],
                xLabel: d
            )
        }
        // Per-point `color` overrides `style.color` (kept as a fallback).
        return Chart(
            series: [ChartSeries.bars(id: "colored", points: points, color: .gray, opacity: 0.9)],
            axis: ChartAxisConfig(yMin: 0, yMax: 100, yStep: 20, padXByHalfStep: true)
        )
    }
}
