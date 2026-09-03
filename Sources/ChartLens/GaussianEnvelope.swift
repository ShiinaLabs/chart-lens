import Foundation

public struct GaussianEnvelope: Equatable, Sendable {
    public let leftX: Double
    public let rightX: Double
    public let peakY: Double
    public let baselineY: Double
    public let sigma: Double

    public init(leftX: Double, rightX: Double, peakY: Double, baselineY: Double, sigma: Double) {
        self.leftX = leftX
        self.rightX = rightX
        self.peakY = peakY
        self.baselineY = baselineY
        self.sigma = sigma
    }

    public func value(atX x: Double) -> Double {
        guard leftX.isFinite, rightX.isFinite, peakY.isFinite, baselineY.isFinite, sigma.isFinite, x.isFinite, sigma > 0 else {
            return baselineY
        }

        let center = (leftX + rightX) / 2.0
        let amplitude = max(0, peakY - baselineY)
        let distance = x - center
        let normalizedDistance = distance / sigma
        let gaussian = exp(-(normalizedDistance * normalizedDistance) / 2.0)
        return baselineY + amplitude * gaussian
    }

    public func sampledPoints(count: Int) -> [(x: Double, y: Double)] {
        guard count > 0 else { return [] }
        guard count > 1 else {
            let x = (leftX + rightX) / 2.0
            return [(x, value(atX: x))]
        }

        return (0..<count).map { index in
            let x = leftX + (rightX - leftX) * Double(index) / Double(count - 1)
            return (x, value(atX: x))
        }
    }
}
