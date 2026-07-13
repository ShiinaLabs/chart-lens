import SwiftUI
import ChartLens

struct RangeDemo: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 360))], spacing: 20) {
                DemoCard(title: "Error Bars") { errorBars }
                DemoCard(title: "Box Plot") { boxPlot }
            }
            .padding()
        }
    }

    private var errorBars: some View {
        let weeks = ["W1", "W2", "W3", "W4", "W5", "W6", "W7", "W8"]
        let ranges = weeks.enumerated().map { i, w in
            let center = 50 + 30 * sin(Double(i) / 2)
            return RangePoint(
                x: Double(i),
                center: center,
                low: center - Double.random(in: 8...18),
                high: center + Double.random(in: 8...18),
                xLabel: w
            )
        }
        return Chart(
            series: [ChartSeries.errorBars(id: "error", points: ranges, style: .line(color: .indigo, lineWidth: 1.5))],
            axis: ChartAxisConfig(yMin: 0, yMax: 100, yStep: 20, padXByHalfStep: true)
        )
    }

    private var boxPlot: some View {
        let labels = ["Jan", "Feb", "Mar", "Apr", "May"]
        let boxes = labels.enumerated().map { i, m in
            switch i {
            case 0: BoxPlotPoint(x: 0, min: 20, q1: 35, median: 50, q3: 62, max: 78, outliers: [12, 85], xLabel: m)
            case 1: BoxPlotPoint(x: 1, min: 30, q1: 42, median: 55, q3: 70, max: 82, outliers: [22], xLabel: m)
            case 2: BoxPlotPoint(x: 2, min: 18, q1: 30, median: 44, q3: 58, max: 74, outliers: [10, 90], xLabel: m)
            case 3: BoxPlotPoint(x: 3, min: 40, q1: 52, median: 63, q3: 75, max: 88, outliers: [], xLabel: m)
            default: BoxPlotPoint(x: 4, min: 25, q1: 38, median: 48, q3: 60, max: 72, outliers: [15, 80], xLabel: m)
            }
        }
        return Chart(
            series: [ChartSeries.boxPlot(id: "box", points: boxes)],
            axis: ChartAxisConfig(yMin: 0, yMax: 100, yStep: 20, padXByHalfStep: true)
        )
    }
}
