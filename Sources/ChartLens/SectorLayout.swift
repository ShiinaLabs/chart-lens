import SwiftUI

public enum SectorLayout {
    /// Resolves caller data into ordered angular slices.
    ///
    /// Negative and non-finite values are ignored. Zero values remain in the
    /// result with a zero fraction and zero angular span, preserving the
    /// caller's ordering and identity.
    public static func slices(
        from data: [SectorDatum],
        startAngle: Angle = .degrees(-90),
        clockwise: Bool = true
    ) -> [SectorSlice] {
        let valid = data.enumerated().filter { _, datum in
            datum.value.isFinite && datum.value >= 0
        }
        let total = valid.reduce(0.0) { partialResult, entry in
            partialResult + entry.element.value
        }

        guard total.isFinite, total > 0 else {
            return valid.map { index, datum in
                SectorSlice(
                    id: datum.id,
                    index: index,
                    value: datum.value,
                    fraction: 0,
                    startAngle: startAngle,
                    endAngle: startAngle,
                    label: datum.label
                )
            }
        }

        let direction = clockwise ? 1.0 : -1.0
        var current = startAngle.radians

        return valid.map { index, datum in
            let fraction = datum.value / total
            let span = 2 * Double.pi * fraction
            let end = current + direction * span
            defer { current = end }
            return SectorSlice(
                id: datum.id,
                index: index,
                value: datum.value,
                fraction: fraction,
                startAngle: .radians(current),
                endAngle: .radians(end),
                label: datum.label
            )
        }
    }
}
