import Testing
@testable import ChartLens

@Suite struct GaussianEnvelopeTests {

    private let envelope = GaussianEnvelope(
        leftX: 0,
        rightX: 8,
        peakY: -40,
        baselineY: -100,
        sigma: 1
    )

    @Test func valueUsesBaselineWhenAmplitudeIsZero() {
        let flatEnvelope = GaussianEnvelope(
            leftX: 0,
            rightX: 8,
            peakY: -100,
            baselineY: -100,
            sigma: 1
        )

        #expect(flatEnvelope.value(atX: 0) == -100)
        #expect(flatEnvelope.value(atX: 8) == -100)
    }

    @Test func valuePeaksAtMidpoint() {
        #expect(envelope.value(atX: 4) == -40)
    }

    @Test func valueIsSymmetricAroundMidpoint() {
        #expect(abs(envelope.value(atX: 3) - envelope.value(atX: 5)) < 0.000_000_1)
    }

    @Test func invalidSigmaReturnsBaseline() {
        let zeroSigma = GaussianEnvelope(leftX: 0, rightX: 8, peakY: -40, baselineY: -100, sigma: 0)
        let infiniteSigma = GaussianEnvelope(leftX: 0, rightX: 8, peakY: -40, baselineY: -100, sigma: .infinity)

        #expect(zeroSigma.value(atX: 4) == -100)
        #expect(infiniteSigma.value(atX: 4) == -100)
    }

    @Test func smallestPositiveFiniteSigmaProducesFiniteMidpointPeak() {
        let tinySigma = GaussianEnvelope(
            leftX: 0,
            rightX: 8,
            peakY: -40,
            baselineY: -100,
            sigma: .leastNonzeroMagnitude
        )

        let value = tinySigma.value(atX: 4)

        #expect(value.isFinite)
        #expect(value == -40)
    }

    @Test func sampledPointsPreserveSpectrumPointCountAndEndpoints() {
        let points = envelope.sampledPoints(count: 81)

        #expect(points.count == 81)
        #expect(points.first?.x == 0)
        #expect(points.last?.x == 8)
        #expect(points[40].x == 4)
        #expect(points[40].y == -40)
    }
}
