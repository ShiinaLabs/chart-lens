import Testing
import SwiftUI
@testable import ChartLens

@Suite struct BarRendererTests {

    private func makeGeometry() -> ChartGeometry {
        ChartGeometry(
            chartRect: CGRect(x: 0, y: 0, width: 300, height: 200),
            xMin: 0, xMax: 10, yMin: 0, yMax: 100
        )
    }

    private let samplePoints = (0..<5).map { i in ChartPoint(x: Double(i), y: Double((i + 1) * 10)) }

    @Test func barRendererDrawsSolidBars() {
        let renderer = BarRenderer()
        let style = ChartSeriesStyle.bars(color: .blue, opacity: 0.85)
        let geo = makeGeometry()
        let _ = Image(size: CGSize(width: 300, height: 200)) { ctx in
            renderer.render(context: &ctx, points: samplePoints, geometry: geo, style: style)
        }
    }

    @Test func barRendererHandlesSinglePoint() {
        let renderer = BarRenderer()
        let geo = makeGeometry()
        let _ = Image(size: CGSize(width: 100, height: 100)) { ctx in
            renderer.render(context: &ctx, points: [ChartPoint(x: 0, y: 40)], geometry: geo, style: .bars(color: .green))
        }
    }

    @Test func barRendererHandlesNegativeValues() {
        let renderer = BarRenderer()
        let points = [ChartPoint(x: 0, y: -50), ChartPoint(x: 1, y: -30), ChartPoint(x: 2, y: -70)]
        let geo = ChartGeometry(
            chartRect: CGRect(x: 0, y: 0, width: 300, height: 200),
            xMin: 0, xMax: 2, yMin: -80, yMax: -20
        )
        let _ = Image(size: CGSize(width: 300, height: 200)) { ctx in
            renderer.render(context: &ctx, points: points, geometry: geo, style: .bars(color: .green))
        }
    }

    @Test func barChartPointYRangeIsSingleton() {
        let p = ChartPoint(x: 3, y: 42)
        #expect(p.yRange.min == 42)
        #expect(p.yRange.max == 42)
    }
}
