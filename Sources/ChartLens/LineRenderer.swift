import SwiftUI

public struct LineRenderer: ChartSeriesRenderer<ChartPoint> {
    public init() {}

    public func render(context: inout GraphicsContext, points: [ChartPoint], geometry: ChartGeometry, style: ChartSeriesStyle) {
        guard points.count >= 2 else { return }

        switch style.interpolation {
        case .linear, .step:
            drawPolyline(context: &context, points: points, geometry: geometry, style: style, stepped: style.interpolation == .step)
        case .catmullRom:
            let pts = points.map { geometry.dataToPoint(x: $0.x, y: $0.y) }
            drawCurvePath(context: &context, curve: catmullRomSpline(points: pts), points: points, style: style, geometry: geometry)
        case .clampedCubic:
            let pts = points.map { geometry.dataToPoint(x: $0.x, y: $0.y) }
            drawCurvePath(context: &context, curve: clampedCubicSpline(points: pts), points: points, style: style, geometry: geometry)
        case .gaussian(let sigma, let baseline):
            drawGaussianCurve(context: &context, points: points, style: style, geometry: geometry, sigma: sigma, baseline: baseline)
        }
    }

    private func drawPolyline(context: inout GraphicsContext, points: [ChartPoint], geometry: ChartGeometry, style: ChartSeriesStyle, stepped: Bool) {
        var line = Path()
        var prevSY: CGFloat = 0
        for (i, pt) in points.enumerated() {
            let sx = geometry.chartRect.minX + (pt.x - geometry.xMin) * geometry.scaleX
            let sy = geometry.chartRect.maxY - (pt.y - geometry.yMin) * geometry.scaleY
            if stepped, i > 0 { line.addLine(to: CGPoint(x: sx, y: prevSY)) }
            if i == 0 { line.move(to: CGPoint(x: sx, y: sy)) } else { line.addLine(to: CGPoint(x: sx, y: sy)) }
            prevSY = sy
        }

        if style.areaOpacity > 0 {
            let fillY = style.baseline.map { geometry.chartRect.maxY - ($0 - geometry.yMin) * geometry.scaleY } ?? geometry.chartRect.maxY
            let lx = geometry.chartRect.minX + (points.last!.x - geometry.xMin) * geometry.scaleX
            let fx = geometry.chartRect.minX + (points.first!.x - geometry.xMin) * geometry.scaleX
            var fill = line
            fill.addLine(to: CGPoint(x: lx, y: fillY))
            fill.addLine(to: CGPoint(x: fx, y: fillY))
            fill.closeSubpath()
            context.fill(fill, with: .color(style.color.opacity(style.areaOpacity)))
        }
        if style.lineWidth > 0, style.strokeOpacity > 0 {
            context.stroke(line, with: .color(style.color.opacity(style.strokeOpacity)), lineWidth: style.lineWidth)
        }
        if style.pointRadius > 0 {
            let r = style.pointRadius
            for pt in points {
                let sx = geometry.chartRect.minX + (pt.x - geometry.xMin) * geometry.scaleX
                let sy = geometry.chartRect.maxY - (pt.y - geometry.yMin) * geometry.scaleY
                context.fill(Path(ellipseIn: CGRect(x: sx - r, y: sy - r, width: r * 2, height: r * 2)), with: .color(style.color))
            }
        }
    }

    private func drawCurvePath(context: inout GraphicsContext, curve: Path, points: [ChartPoint], style: ChartSeriesStyle, geometry: ChartGeometry) {
        if style.areaOpacity > 0 {
            let fillY = style.baseline.map { geometry.chartRect.maxY - ($0 - geometry.yMin) * geometry.scaleY } ?? geometry.chartRect.maxY
            let lx = geometry.chartRect.minX + (points.last!.x - geometry.xMin) * geometry.scaleX
            let fx = geometry.chartRect.minX + (points.first!.x - geometry.xMin) * geometry.scaleX
            var fill = curve
            fill.addLine(to: CGPoint(x: lx, y: fillY))
            fill.addLine(to: CGPoint(x: fx, y: fillY))
            fill.closeSubpath()
            context.fill(fill, with: .color(style.color.opacity(style.areaOpacity)))
        }
        if style.lineWidth > 0, style.strokeOpacity > 0 {
            context.stroke(curve, with: .color(style.color.opacity(style.strokeOpacity)), lineWidth: style.lineWidth)
        }
    }

    private func drawGaussianCurve(context: inout GraphicsContext, points: [ChartPoint], style: ChartSeriesStyle, geometry: ChartGeometry, sigma: Double, baseline: Double) {
        guard let first = points.first, let last = points.last else { return }
        let envelope = GaussianEnvelope(
            leftX: first.x,
            rightX: last.x,
            peakY: first.y,
            baselineY: baseline,
            sigma: sigma
        )

        // Build curve points
        var curvePts: [CGPoint] = []
        for point in envelope.sampledPoints(count: 81) {
            curvePts.append(geometry.dataToPoint(x: point.x, y: point.y))
        }

        let leftBase = geometry.dataToPoint(x: first.x, y: baseline)
        let rightBase = geometry.dataToPoint(x: last.x, y: baseline)

        // Stroke: open curve path, ends at baseline
        if style.lineWidth > 0, style.strokeOpacity > 0 {
            var stroke = Path()
            stroke.move(to: leftBase)
            for pt in curvePts { stroke.addLine(to: pt) }
            stroke.addLine(to: rightBase)
            context.stroke(stroke, with: .color(style.color.opacity(style.strokeOpacity)), lineWidth: style.lineWidth)
        }

        // Fill: closed path (curve + baseline)
        if style.areaOpacity > 0 {
            var fill = Path()
            fill.move(to: leftBase)
            for pt in curvePts { fill.addLine(to: pt) }
            fill.addLine(to: rightBase)
            fill.closeSubpath()
            context.fill(fill, with: .color(style.color.opacity(style.areaOpacity)))
        }
    }
}
