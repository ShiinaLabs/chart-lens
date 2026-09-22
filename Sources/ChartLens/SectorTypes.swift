import SwiftUI

/// Domain data for a part-to-whole chart.
///
/// ChartLens owns normalization, angular layout, rendering, and hit-testing.
/// Callers only provide stable identity, a non-negative value, and an optional
/// display label.
public struct SectorDatum: Identifiable, Sendable {
    public let id: String
    public let value: Double
    public let label: String?

    public init(id: String, value: Double, label: String? = nil) {
        self.id = id
        self.value = value
        self.label = label
    }
}

/// A resolved sector produced by SectorLayout.
public struct SectorSlice: Identifiable, Sendable {
    public let id: String
    public let index: Int
    public let value: Double
    public let fraction: Double
    public let startAngle: Angle
    public let endAngle: Angle
    public let label: String?
}

/// Presentation configuration shared by pie and donut charts.
public struct SectorStyle: Sendable {
    public var innerRadiusRatio: CGFloat
    public var outerRadiusInset: CGFloat
    public var angularGap: Angle
    public var startAngle: Angle
    public var clockwise: Bool
    public var colors: [Color]

    public static let defaultColors: [Color] = [
        .blue,
        .green,
        .orange,
        .purple,
        .pink,
        .teal,
    ]

    public init(
        innerRadiusRatio: CGFloat = 0,
        outerRadiusInset: CGFloat = 4,
        angularGap: Angle = .degrees(1),
        startAngle: Angle = .degrees(-90),
        clockwise: Bool = true,
        colors: [Color] = SectorStyle.defaultColors
    ) {
        self.innerRadiusRatio = innerRadiusRatio
        self.outerRadiusInset = outerRadiusInset
        self.angularGap = angularGap
        self.startAngle = startAngle
        self.clockwise = clockwise
        self.colors = colors
    }

    public static func pie(
        outerRadiusInset: CGFloat = 4,
        angularGap: Angle = .degrees(1),
        startAngle: Angle = .degrees(-90),
        clockwise: Bool = true,
        colors: [Color] = SectorStyle.defaultColors
    ) -> SectorStyle {
        SectorStyle(
            innerRadiusRatio: 0,
            outerRadiusInset: outerRadiusInset,
            angularGap: angularGap,
            startAngle: startAngle,
            clockwise: clockwise,
            colors: colors
        )
    }

    public static func donut(
        innerRadiusRatio: CGFloat = 0.6,
        outerRadiusInset: CGFloat = 4,
        angularGap: Angle = .degrees(1),
        startAngle: Angle = .degrees(-90),
        clockwise: Bool = true,
        colors: [Color] = SectorStyle.defaultColors
    ) -> SectorStyle {
        SectorStyle(
            innerRadiusRatio: innerRadiusRatio,
            outerRadiusInset: outerRadiusInset,
            angularGap: angularGap,
            startAngle: startAngle,
            clockwise: clockwise,
            colors: colors
        )
    }
}

/// Polar hit-testing callbacks for SectorChart.
public struct SectorInteraction: @unchecked Sendable {
    public var onHover: (@MainActor (SectorSlice?) -> Void)?
    public var onTap: (@MainActor (SectorSlice?) -> Void)?

    public init(
        onHover: (@MainActor (SectorSlice?) -> Void)? = nil,
        onTap: (@MainActor (SectorSlice?) -> Void)? = nil
    ) {
        self.onHover = onHover
        self.onTap = onTap
    }
}
