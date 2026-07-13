import Testing
import SwiftUI
@testable import ChartLens

@Suite struct BubbleRendererTests {

    private func makeGeometry() -> ChartGeometry {
        ChartGeometry(
            chartRect: CGRect(x: 0, y: 0, width: 200, height: 200),
            xMin: 0, xMax: 100, yMin: 0, yMax: 100
        )
    }

    @Test func bubbleRendererDrawsVariedRadii() {
        let renderer = BubbleRenderer()
        let points = [
            BubblePoint(x: 10, y: 20, radius: 4, value: 4),
            BubblePoint(x: 50, y: 60, radius: 12, value: 12),
            BubblePoint(x: 90, y: 90, radius: 20, value: 20),
        ]
        let geo = makeGeometry()
        let _ = Image(size: CGSize(width: 200, height: 200)) { ctx in
            renderer.render(context: &ctx, points: points, geometry: geo, style: .bars(color: .blue, opacity: 0.6))
        }
    }

    @Test func bubbleCenterMapsViaGeometry() {
        let geo = makeGeometry()
        let p = BubblePoint(x: 50, y: 50, radius: 10)
        let screen = geo.dataToPoint(x: p.x, y: p.y)
        // Center of a 200x200 plot with 0..100 domain maps to (100, 100).
        #expect(abs(screen.x - 100) < 0.001)
        #expect(abs(screen.y - 100) < 0.001)
        #expect(p.yRange.min == 50)
        #expect(p.yRange.max == 50)
    }
}
