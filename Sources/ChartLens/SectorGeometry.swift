import Foundation
import SwiftUI

internal enum SectorMath {
    static func normalized(_ angle: Double) -> Double {
        let turn = 2 * Double.pi
        let remainder = angle.truncatingRemainder(dividingBy: turn)
        return remainder >= 0 ? remainder : remainder + turn
    }

    static func positiveDelta(from start: Double, to end: Double) -> Double {
        normalized(end - start)
    }

    static func effectiveAngles(
        for slice: SectorSlice,
        gap: Angle,
        clockwise: Bool
    ) -> (start: Double, end: Double) {
        let direction = clockwise ? 1.0 : -1.0
        let rawSpan = abs(slice.endAngle.radians - slice.startAngle.radians)
        let fullSpan = rawSpan.isFinite ? rawSpan : 0
        let rawGap = gap.radians
        let safeGap = rawGap.isFinite ? max(0, abs(rawGap)) : 0
        let gapSpan = min(safeGap, fullSpan)
        let effectiveSpan = max(0, fullSpan - gapSpan)
        let start = slice.startAngle.radians + direction * gapSpan / 2
        return (start, start + direction * effectiveSpan)
    }
}

/// Geometry and polar interaction helpers for a resolved sector chart.
public struct SectorGeometry: Sendable {
    public let frameRect: CGRect
    public let plotRect: CGRect
    public let center: CGPoint
    public let innerRadius: CGFloat
    public let outerRadius: CGFloat
    public let slices: [SectorSlice]
    public let angularGap: Angle
    public let clockwise: Bool

    public init(size: CGSize, style: SectorStyle, slices: [SectorSlice]) {
        let width = max(0, size.width.isFinite ? size.width : 0)
        let height = max(0, size.height.isFinite ? size.height : 0)
        let frameRect = CGRect(x: 0, y: 0, width: width, height: height)
        let requestedInset = max(0, style.outerRadiusInset.isFinite ? style.outerRadiusInset : 0)
        let inset = min(requestedInset, min(width, height) / 2)
        let plotWidth = max(0, width - inset * 2)
        let plotHeight = max(0, height - inset * 2)
        let plotRect = CGRect(x: inset, y: inset, width: plotWidth, height: plotHeight)
        let center = CGPoint(x: plotRect.midX, y: plotRect.midY)
        let outerRadius = max(0, min(plotRect.width, plotRect.height) / 2)
        let ratio = min(
            max(0, style.innerRadiusRatio.isFinite ? style.innerRadiusRatio : 0),
            0.999999
        )

        self.frameRect = frameRect
        self.plotRect = plotRect
        self.center = center
        self.innerRadius = outerRadius * ratio
        self.outerRadius = outerRadius
        self.slices = slices
        self.angularGap = style.angularGap
        self.clockwise = style.clockwise
    }

    /// Returns a point halfway through a slice at the midpoint of its radial band.
    public func centroid(of slice: SectorSlice) -> CGPoint {
        let direction = clockwise ? 1.0 : -1.0
        let midpoint = slice.startAngle.radians + direction * abs(slice.endAngle.radians - slice.startAngle.radians) / 2
        let radius = (innerRadius + outerRadius) / 2
        return CGPoint(
            x: center.x + cos(midpoint) * radius,
            y: center.y + sin(midpoint) * radius
        )
    }

    /// Returns the slice under a local point, or nil outside the annulus.
    public func slice(at point: CGPoint) -> SectorSlice? {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let radius = hypot(dx, dy)
        let epsilon = 0.0001

        guard radius + epsilon >= innerRadius, radius <= outerRadius + epsilon else {
            return nil
        }

        let angle = atan2(dy, dx)
        let direction = clockwise ? 1.0 : -1.0

        for slice in slices where slice.fraction > 0 {
            let effective = SectorMath.effectiveAngles(
                for: slice,
                gap: angularGap,
                clockwise: clockwise
            )
            let span = abs(effective.end - effective.start)
            guard span > epsilon else { continue }

            let delta = direction > 0
                ? SectorMath.positiveDelta(from: effective.start, to: angle)
                : SectorMath.positiveDelta(from: angle, to: effective.start)
            if delta <= span + epsilon {
                return slice
            }
        }

        return nil
    }
}
