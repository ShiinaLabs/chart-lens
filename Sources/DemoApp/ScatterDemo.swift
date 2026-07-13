import SwiftUI
import ChartLens

struct ScatterDemo: View {
    @State private var hoverPoint: (any ChartPointProtocol)?
    @State private var cursorX: CGFloat?

    private let bubbles: [BubblePoint] = (0..<24).map { _ in
        let x = Double.random(in: 0...60)
        let y = Double.random(in: 0...100)
        let size = Double.random(in: 4...22)
        return BubblePoint(x: x, y: y, radius: CGFloat(size), value: size)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 360))], spacing: 20) {
                DemoCard(title: "Scatter (Dots)") { scatterChart }
                DemoCard(title: "Bubble (Hover)") { bubbleChart }
            }
            .padding()
        }
    }

    private var scatterChart: some View {
        let points = (0..<40).map { _ in
            ChartPoint(x: Double.random(in: 0...60), y: Double.random(in: -80 ... -20))
        }
        return Chart(
            series: [ChartSeries(id: "samples", points: points, style: .dots(color: .purple, radius: 3))],
            axis: ChartAxisConfig(yMin: -90, yMax: -10, yStep: 10, xTicks: stride(from: 0, through: 60, by: 10).map { ChartAxisConfig.XTick(position: $0, label: "\(Int($0))") }, padXByHalfStep: true)
        )
    }

    private var bubbleChart: some View {
        Chart(
            series: [ChartSeries.bubbles(id: "bubbles", points: bubbles, style: .bars(color: .blue, opacity: 0.5, lineWidth: 1))],
            axis: ChartAxisConfig(yMin: 0, yMax: 100, yStep: 20, xTicks: stride(from: 0, through: 60, by: 10).map { ChartAxisConfig.XTick(position: $0, label: "\(Int($0))") }, padXByHalfStep: true),
            style: ChartStyle(marginTop: 24),
            interaction: ChartInteraction(
                onHover: { pt, _, cursor in
                    hoverPoint = pt
                    cursorX = cursor?.x
                }
            )
        ) { geo, _ in
            CrosshairOverlay(geometry: geo, hoverPoint: hoverPoint, cursorScreenX: cursorX, config: .init())
        }
    }
}
