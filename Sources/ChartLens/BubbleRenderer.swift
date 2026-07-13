import SwiftUI

/// Renders bubbles — scatter points whose drawn radius encodes a third
/// (size) dimension. `radius` is in pixels (zoom-independent, like `pointRadius`).
public struct BubbleRenderer: ChartSeriesRenderer {
    public init() {}

    public func render(context: inout GraphicsContext, points: [BubblePoint], geometry: ChartGeometry, style: ChartSeriesStyle) {
        guard !points.isEmpty else { return }

        let fillColor = style.color.opacity(style.areaOpacity == 0 ? 1.0 : style.areaOpacity)
        let strokeColor = style.color.opacity(style.strokeOpacity)

        for pt in points {
            let center = geometry.dataToPoint(x: pt.x, y: pt.y)
            let r = max(1.0, pt.radius)

            let ellipse = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
            context.fill(ellipse, with: .color(fillColor))

            if style.lineWidth > 0, style.strokeOpacity > 0 {
                context.stroke(ellipse, with: .color(strokeColor), lineWidth: style.lineWidth)
            }
        }
    }
}
