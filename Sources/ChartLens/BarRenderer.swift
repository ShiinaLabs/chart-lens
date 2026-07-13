import SwiftUI

/// Renders single-series vertical bars from a baseline to each point's `y`.
/// Reuses `ChartPoint` (x, y); the bar fills from `style.baseline` (or zero when
/// visible, otherwise the nearest axis bound) up to `y`.
public struct BarRenderer: ChartSeriesRenderer {
    public init() {}

    public func render(context: inout GraphicsContext, points: [ChartPoint], geometry: ChartGeometry, style: ChartSeriesStyle) {
        guard !points.isEmpty else { return }

        let barWidth = max(2.0, geometry.scaleX * 0.7)
        let baseline = resolveBaseline(style: style, geometry: geometry)

        let baselineY = geometry.chartRect.maxY - (baseline - geometry.yMin) * geometry.scaleY

        let fillOpacity = style.areaOpacity == 0 ? 1.0 : style.areaOpacity
        let strokeColor = style.color.opacity(style.strokeOpacity)

        for pt in points {
            let cx = geometry.chartRect.minX + (pt.x - geometry.xMin) * geometry.scaleX
            let topY = geometry.chartRect.maxY - (pt.y - geometry.yMin) * geometry.scaleY

            let rect = CGRect(
                x: cx - barWidth / 2,
                y: min(topY, baselineY),
                width: barWidth,
                height: max(1, abs(topY - baselineY))
            )
            // Per-point color overrides the series color when present.
            let fillColor = (pt.color ?? style.color).opacity(fillOpacity)
            context.fill(Path(rect), with: .color(fillColor))

            if style.lineWidth > 0, style.strokeOpacity > 0 {
                context.stroke(Path(rect), with: .color(strokeColor), lineWidth: style.lineWidth)
            }
        }
    }

    private func resolveBaseline(style: ChartSeriesStyle, geometry: ChartGeometry) -> Double {
        if let baseline = style.baseline {
            return baseline
        }
        // Zero-based when 0 sits inside the visible range; otherwise clamp to nearest bound.
        return Swift.max(geometry.yMin, Swift.min(geometry.yMax, 0))
    }
}
