import SwiftUI

internal enum SectorRendering {
    static func path(
        center: CGPoint,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        startAngle: Double,
        endAngle: Double
    ) -> Path {
        let span = abs(endAngle - startAngle)
        let steps = min(1800, max(8, Int(ceil(span * Double(max(outerRadius, 1)) / 8))))
        let outerPoints = (0 ... steps).map { step in
            let progress = Double(step) / Double(steps)
            let angle = startAngle + (endAngle - startAngle) * progress
            return CGPoint(
                x: center.x + cos(angle) * outerRadius,
                y: center.y + sin(angle) * outerRadius
            )
        }

        var path = Path()
        guard let firstOuter = outerPoints.first else { return path }

        if innerRadius <= 0.0001 {
            path.move(to: center)
            path.addLine(to: firstOuter)
            for point in outerPoints.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
            return path
        }

        path.move(to: firstOuter)
        for point in outerPoints.dropFirst() {
            path.addLine(to: point)
        }

        let innerEnd = CGPoint(
            x: center.x + cos(endAngle) * innerRadius,
            y: center.y + sin(endAngle) * innerRadius
        )
        path.addLine(to: innerEnd)

        for step in stride(from: steps - 1, through: 0, by: -1) {
            let progress = Double(step) / Double(steps)
            let angle = startAngle + (endAngle - startAngle) * progress
            path.addLine(to: CGPoint(
                x: center.x + cos(angle) * innerRadius,
                y: center.y + sin(angle) * innerRadius
            ))
        }
        path.closeSubpath()
        return path
    }

    static func draw(
        context: inout GraphicsContext,
        geometry: SectorGeometry,
        style: SectorStyle
    ) {
        let colors = style.colors.isEmpty ? [.blue] : style.colors
        for slice in geometry.slices where slice.fraction > 0 && slice.fraction.isFinite {
            let angles = SectorMath.effectiveAngles(
                for: slice,
                gap: style.angularGap,
                clockwise: style.clockwise
            )
            guard abs(angles.end - angles.start) > 0.0001 else { continue }

            let path = self.path(
                center: geometry.center,
                innerRadius: geometry.innerRadius,
                outerRadius: geometry.outerRadius,
                startAngle: angles.start,
                endAngle: angles.end
            )
            context.fill(path, with: .color(colors[slice.index % colors.count]))
        }
    }
}
