import SwiftUI

/// Renders error bars: a vertical line from `low` to `high` at each `x`, with
/// horizontal end caps and an optional center marker.
public struct ErrorBarRenderer: ChartSeriesRenderer {
    public init() {}

    public func render(context: inout GraphicsContext, points: [RangePoint], geometry: ChartGeometry, style: ChartSeriesStyle) {
        guard !points.isEmpty else { return }

        let capWidth = min(geometry.scaleX * 0.3, 8)
        let color = style.color.opacity(style.strokeOpacity)
        let lineWidth = style.lineWidth > 0 ? style.lineWidth : 1.5

        for pt in points {
            let cx = geometry.chartRect.minX + (pt.x - geometry.xMin) * geometry.scaleX
            let lowY = geometry.chartRect.maxY - (pt.low - geometry.yMin) * geometry.scaleY
            let highY = geometry.chartRect.maxY - (pt.high - geometry.yMin) * geometry.scaleY
            let centerY = geometry.chartRect.maxY - (pt.center - geometry.yMin) * geometry.scaleY

            // Vertical span
            var v = Path()
            v.move(to: CGPoint(x: cx, y: lowY))
            v.addLine(to: CGPoint(x: cx, y: highY))
            context.stroke(v, with: .color(color), lineWidth: lineWidth)

            // End caps
            for y in [lowY, highY] {
                var cap = Path()
                cap.move(to: CGPoint(x: cx - capWidth, y: y))
                cap.addLine(to: CGPoint(x: cx + capWidth, y: y))
                context.stroke(cap, with: .color(color), lineWidth: lineWidth)
            }

            // Center marker
            if style.pointRadius > 0 {
                let r = style.pointRadius
                context.fill(
                    Path(ellipseIn: CGRect(x: cx - r, y: centerY - r, width: r * 2, height: r * 2)),
                    with: .color(style.color)
                )
            } else {
                var tick = Path()
                tick.move(to: CGPoint(x: cx - capWidth, y: centerY))
                tick.addLine(to: CGPoint(x: cx + capWidth, y: centerY))
                context.stroke(tick, with: .color(color), lineWidth: lineWidth)
            }
        }
    }
}
