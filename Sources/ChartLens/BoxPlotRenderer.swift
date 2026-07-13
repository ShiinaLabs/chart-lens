import SwiftUI

/// Renders box plots: a quartile box (q1→q3) with a median line, whiskers to
/// min/max with end caps, and optional outlier dots.
public struct BoxPlotRenderer: ChartSeriesRenderer {
    public init() {}

    public func render(context: inout GraphicsContext, points: [BoxPlotPoint], geometry: ChartGeometry, style: ChartSeriesStyle) {
        guard !points.isEmpty else { return }

        let boxWidth = max(2.0, geometry.scaleX * 0.7)
        let capWidth = min(geometry.scaleX * 0.3, 8)
        let fillColor = style.color.opacity(style.areaOpacity == 0 ? 0.15 : style.areaOpacity)
        let strokeColor = style.color.opacity(style.strokeOpacity)
        let lineWidth = style.lineWidth > 0 ? style.lineWidth : 1.5
        let outlierRadius = style.pointRadius > 0 ? style.pointRadius : 2.0

        for pt in points {
            let cx = geometry.chartRect.minX + (pt.x - geometry.xMin) * geometry.scaleX

            let y: (Double) -> CGFloat = { geometry.chartRect.maxY - ($0 - geometry.yMin) * geometry.scaleY }
            let q1Y = y(pt.q1)
            let q3Y = y(pt.q3)
            let medianY = y(pt.median)
            let minY = y(pt.min)
            let maxY = y(pt.max)

            // Box
            let boxRect = CGRect(
                x: cx - boxWidth / 2,
                y: min(q1Y, q3Y),
                width: boxWidth,
                height: max(1, abs(q3Y - q1Y))
            )
            context.fill(Path(boxRect), with: .color(fillColor))
            context.stroke(Path(boxRect), with: .color(strokeColor), lineWidth: lineWidth)

            // Median line
            var median = Path()
            median.move(to: CGPoint(x: cx - boxWidth / 2, y: medianY))
            median.addLine(to: CGPoint(x: cx + boxWidth / 2, y: medianY))
            context.stroke(median, with: .color(strokeColor), lineWidth: lineWidth)

            // Whiskers
            for (edgeY, extremeY) in [(q1Y, minY), (q3Y, maxY)] {
                var wick = Path()
                wick.move(to: CGPoint(x: cx, y: edgeY))
                wick.addLine(to: CGPoint(x: cx, y: extremeY))
                context.stroke(wick, with: .color(strokeColor), lineWidth: lineWidth)

                var cap = Path()
                cap.move(to: CGPoint(x: cx - capWidth, y: extremeY))
                cap.addLine(to: CGPoint(x: cx + capWidth, y: extremeY))
                context.stroke(cap, with: .color(strokeColor), lineWidth: lineWidth)
            }

            // Outliers
            for out in pt.outliers {
                let oy = y(out)
                context.fill(
                    Path(ellipseIn: CGRect(x: cx - outlierRadius, y: oy - outlierRadius, width: outlierRadius * 2, height: outlierRadius * 2)),
                    with: .color(style.color)
                )
            }
        }
    }
}
