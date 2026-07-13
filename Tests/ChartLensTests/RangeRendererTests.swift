import Testing
import SwiftUI
@testable import ChartLens

@Suite struct RangeRendererTests {

    private func makeGeometry() -> ChartGeometry {
        ChartGeometry(
            chartRect: CGRect(x: 0, y: 0, width: 300, height: 200),
            xMin: 0, xMax: 4, yMin: 0, yMax: 100
        )
    }

    @Test func errorBarRendererDraws() {
        let renderer = ErrorBarRenderer()
        let points = [
            RangePoint(x: 0, center: 50, low: 30, high: 70),
            RangePoint(x: 1, center: 60, low: 45, high: 80),
            RangePoint(x: 2, center: 40, low: 20, high: 65),
        ]
        let geo = makeGeometry()
        let _ = Image(size: CGSize(width: 300, height: 200)) { ctx in
            renderer.render(context: &ctx, points: points, geometry: geo, style: .line(color: .indigo, lineWidth: 1.5))
        }
    }

    @Test func boxPlotRendererDraws() {
        let renderer = BoxPlotRenderer()
        let points = [
            BoxPlotPoint(x: 0, min: 20, q1: 35, median: 50, q3: 62, max: 78, outliers: [12, 85]),
            BoxPlotPoint(x: 1, min: 30, q1: 42, median: 55, q3: 70, max: 82, outliers: []),
            BoxPlotPoint(x: 2, min: 18, q1: 30, median: 44, q3: 58, max: 74, outliers: [10]),
        ]
        let geo = makeGeometry()
        let _ = Image(size: CGSize(width: 300, height: 200)) { ctx in
            renderer.render(context: &ctx, points: points, geometry: geo, style: .bars(color: .blue, opacity: 0.15, lineWidth: 1))
        }
    }

    @Test func rangePointSemantics() {
        let p = RangePoint(x: 1, center: 55, low: 40, high: 70)
        #expect(p.yRange.min == 40)
        #expect(p.yRange.max == 70)
        #expect(p.displayY == 55)
    }

    @Test func boxPlotPointSemantics() {
        let p = BoxPlotPoint(x: 0, min: 20, q1: 35, median: 50, q3: 62, max: 78, outliers: [12])
        #expect(p.yRange.min == 20)
        #expect(p.yRange.max == 78)
        #expect(p.displayY == 50)
        #expect(p.outliers == [12])
    }
}
