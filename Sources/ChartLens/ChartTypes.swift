import SwiftUI

// MARK: - Protocols

public protocol ChartPointProtocol: Sendable {
    var x: Double { get }
    var yRange: (min: Double, max: Double) { get }
    /// The Y value used for hit-test screen positioning. Defaults to yRange.min.
    var displayY: Double { get }
    /// Optional text drawn on the x-axis at this point's x (categorical axis).
    /// Defaults to `nil`; when set and `axis.xTicks` is empty, the chart draws
    /// an evenly-spaced tick with this label under the point.
    var xLabel: String? { get }
}

extension ChartPointProtocol {
    public var displayY: Double { yRange.min }
    public var xLabel: String? { nil }
}

public protocol ChartSeriesRenderer<Point>: Sendable {
    associatedtype Point: ChartPointProtocol
    func render(context: inout GraphicsContext, points: [Point], geometry: ChartGeometry, style: ChartSeriesStyle)
}

public protocol ChartSeriesProtocol<Point>: Sendable {
    associatedtype Point: ChartPointProtocol
    var id: String { get }
    var points: [Point] { get }
    var style: ChartSeriesStyle { get }
    func render(context: inout GraphicsContext, geometry: ChartGeometry)
}

// MARK: - Chart Point

/// A single data point in chart data-space coordinates.
public struct ChartPoint: ChartPointProtocol {
    public var x: Double
    public var y: Double
    /// Optional per-point color. When set, bar/dot renderers use it instead of
    /// `style.color`. Defaults to `nil` (fall back to the series color).
    public var color: Color?
    /// Optional categorical x-axis label drawn under the bar.
    public var xLabel: String?

    public var yRange: (min: Double, max: Double) { (y, y) }

    public init(x: Double, y: Double, color: Color? = nil, xLabel: String? = nil) {
        self.x = x
        self.y = y
        self.color = color
        self.xLabel = xLabel
    }
}

// MARK: - Candlestick Point

public struct CandlestickPoint: ChartPointProtocol {
    public let x: Double
    public let open: Double
    public let high: Double
    public let low: Double
    public let close: Double

    public var yRange: (min: Double, max: Double) { (low, high) }
    public var displayY: Double { close }

    public init(x: Double, open: Double, high: Double, low: Double, close: Double) {
        self.x = x
        self.open = open
        self.high = high
        self.low = low
        self.close = close
    }
}

// MARK: - Range Point (Error Bar)

/// A data point with a center value and a [low, high] interval, for error bars.
public struct RangePoint: ChartPointProtocol {
    public let x: Double
    public let center: Double
    public let low: Double
    public let high: Double
    /// Optional categorical x-axis label drawn under the error bar.
    public let xLabel: String?

    public var yRange: (min: Double, max: Double) { (low, high) }
    public var displayY: Double { center }

    public init(x: Double, center: Double, low: Double, high: Double, xLabel: String? = nil) {
        self.x = x
        self.center = center
        self.low = low
        self.high = high
        self.xLabel = xLabel
    }
}

// MARK: - Box Plot Point

/// A data point describing a full box plot: quartiles, whiskers, and outliers.
public struct BoxPlotPoint: ChartPointProtocol {
    public let x: Double
    public let min: Double
    public let q1: Double
    public let median: Double
    public let q3: Double
    public let max: Double
    public var outliers: [Double]
    /// Optional categorical x-axis label drawn under the box plot.
    public let xLabel: String?

    public var yRange: (min: Double, max: Double) { (min, max) }
    public var displayY: Double { median }

    public init(
        x: Double,
        min: Double,
        q1: Double,
        median: Double,
        q3: Double,
        max: Double,
        outliers: [Double] = [],
        xLabel: String? = nil
    ) {
        self.x = x
        self.min = min
        self.q1 = q1
        self.median = median
        self.q3 = q3
        self.max = max
        self.outliers = outliers
        self.xLabel = xLabel
    }
}

// MARK: - Bubble Point

/// A scatter point whose drawn radius encodes a third (size) dimension.
public struct BubblePoint: ChartPointProtocol {
    public let x: Double
    public let y: Double
    /// Pixel radius of the drawn bubble (zoom-independent, like `pointRadius`).
    public let radius: CGFloat
    /// Optional payload surfaced in tooltips / hit-testing.
    public var value: Double

    public var yRange: (min: Double, max: Double) { (y, y) }

    public init(x: Double, y: Double, radius: CGFloat, value: Double = 0) {
        self.x = x
        self.y = y
        self.radius = radius
        self.value = value
    }
}

// MARK: - Chart Series Style

public struct ChartSeriesStyle: Sendable {
    public var color: Color = .blue
    public var lineWidth: CGFloat = 1.5
    public var areaOpacity: Double = 0
    public var pointRadius: CGFloat = 0
    public var strokeOpacity: Double = 1.0
    public var interpolation: Interpolation = .linear
    public var baseline: Double? = nil

    public init(
        color: Color = .blue,
        lineWidth: CGFloat = 1.5,
        areaOpacity: Double = 0,
        pointRadius: CGFloat = 0,
        strokeOpacity: Double = 1.0,
        interpolation: Interpolation = .linear,
        baseline: Double? = nil
    ) {
        self.color = color
        self.lineWidth = lineWidth
        self.areaOpacity = areaOpacity
        self.pointRadius = pointRadius
        self.strokeOpacity = strokeOpacity
        self.interpolation = interpolation
        self.baseline = baseline
    }

    public static func area(color: Color, opacity: Double = 0.12, lineWidth: CGFloat = 1.5) -> ChartSeriesStyle {
        ChartSeriesStyle(color: color, lineWidth: lineWidth, areaOpacity: opacity, interpolation: .linear)
    }

    public static func line(color: Color, lineWidth: CGFloat = 1.5) -> ChartSeriesStyle {
        ChartSeriesStyle(color: color, lineWidth: lineWidth, areaOpacity: 0, interpolation: .linear)
    }

    public static func dots(color: Color, radius: CGFloat = 2) -> ChartSeriesStyle {
        ChartSeriesStyle(color: color, lineWidth: 0, areaOpacity: 0, pointRadius: radius, interpolation: .linear)
    }

    public static func bars(color: Color, opacity: Double = 1.0, lineWidth: CGFloat = 0) -> ChartSeriesStyle {
        ChartSeriesStyle(color: color, lineWidth: lineWidth, areaOpacity: opacity, interpolation: .linear)
    }
}

public enum Interpolation: Equatable, Sendable {
    case linear
    case catmullRom
    case clampedCubic
    case step
    case gaussian(sigma: Double, baseline: Double)
}

// MARK: - Chart Series

/// One renderable series — points + how to draw them.
public struct ChartSeries<Point: ChartPointProtocol>: ChartSeriesProtocol {
    public let id: String
    public var points: [Point]
    public var style: ChartSeriesStyle
    public var renderer: any ChartSeriesRenderer<Point>

    public init(id: String, points: [Point], style: ChartSeriesStyle, renderer: any ChartSeriesRenderer<Point>) {
        self.id = id
        self.points = points
        self.style = style
        self.renderer = renderer
    }

    public func render(context: inout GraphicsContext, geometry: ChartGeometry) {
        renderer.render(context: &context, points: points, geometry: geometry, style: style)
    }
}

// Backward compatibility
extension ChartSeries where Point == ChartPoint {
    public init(id: String, points: [ChartPoint], style: ChartSeriesStyle) {
        self.init(id: id, points: points, style: style, renderer: LineRenderer())
    }

    /// Convenience for a single-series vertical bar chart.
    public static func bars(
        id: String,
        points: [ChartPoint],
        color: Color = .blue,
        opacity: Double = 1.0,
        lineWidth: CGFloat = 0
    ) -> ChartSeries<ChartPoint> {
        ChartSeries(id: id, points: points, style: .bars(color: color, opacity: opacity, lineWidth: lineWidth), renderer: BarRenderer())
    }
}

extension ChartSeries where Point == RangePoint {
    public static func errorBars(
        id: String,
        points: [RangePoint],
        style: ChartSeriesStyle = .line(color: .primary)
    ) -> ChartSeries<RangePoint> {
        ChartSeries(id: id, points: points, style: style, renderer: ErrorBarRenderer())
    }
}

extension ChartSeries where Point == BoxPlotPoint {
    public static func boxPlot(
        id: String,
        points: [BoxPlotPoint],
        style: ChartSeriesStyle = .bars(color: .blue, opacity: 0.15, lineWidth: 1)
    ) -> ChartSeries<BoxPlotPoint> {
        ChartSeries(id: id, points: points, style: style, renderer: BoxPlotRenderer())
    }
}

extension ChartSeries where Point == BubblePoint {
    public static func bubbles(
        id: String,
        points: [BubblePoint],
        style: ChartSeriesStyle = .bars(color: .blue, opacity: 0.6)
    ) -> ChartSeries<BubblePoint> {
        ChartSeries(id: id, points: points, style: style, renderer: BubbleRenderer())
    }
}

extension ChartSeries {
    public typealias ChartSeriesStyle = ChartLens.ChartSeriesStyle
    public typealias Interpolation = ChartLens.Interpolation
}

// MARK: - Y Axis Position

public enum YAxisPosition: Equatable {
    case left
    case right
}

// MARK: - Chart Axis Config

public struct ChartAxisConfig {
    public var yAxisPosition: YAxisPosition = .left
    public var yMin: Double? = nil       // nil = auto-compute from data
    public var yMax: Double? = nil       // nil = auto-compute from data
    public var xMin: Double? = nil       // nil = auto-compute from data
    public var xMax: Double? = nil       // nil = auto-compute from data
    public var yStep: Double = 10        // grid line interval
    public var xTicks: [XTick] = []
    public var showYGrid: Bool = true
    public var showXGrid: Bool = false
    public var showYAxis: Bool = true
    public var showXAxis: Bool = true
    public var clipToRect: Bool = true
    /// When true and x bounds are auto-computed, pad each edge by half the
    /// minimum x-gap so elements drawn centered on an x value (bars, boxes,
    /// error bars) are not clipped at the plot edges.
    public var padXByHalfStep: Bool = false
    public var yTickLabelOffset: CGFloat = 14   // pixels left of the axis line
    public var xTickLabelOffset: CGFloat = 10   // pixels below the axis line
    public var gridColor: Color = .gray.opacity(0.15)
    public var axisColor: Color = .secondary
    public var yTickFont: Font = .caption2
    public var xTickFont: Font = .caption2
    public var yTickColor: Color = .secondary
    public var xTickColor: Color = .secondary
    public var yTickLabel: (Double) -> String = { "\(Int($0))" }
    public var minXTickSpacing: CGFloat = 32   // skip labels closer than this; 0 = draw all
    public var minYTickSpacing: CGFloat = 24   // skip labels closer than this; 0 = draw all

    public init(
        yAxisPosition: YAxisPosition = .left,
        yMin: Double? = nil,
        yMax: Double? = nil,
        xMin: Double? = nil,
        xMax: Double? = nil,
        yStep: Double = 10,
        xTicks: [XTick] = [],
        showYGrid: Bool = true,
        showXGrid: Bool = false,
        showYAxis: Bool = true,
        showXAxis: Bool = true,
        clipToRect: Bool = true,
        yTickLabelOffset: CGFloat = 14,
        xTickLabelOffset: CGFloat = 10,
        gridColor: Color = .gray.opacity(0.15),
        axisColor: Color = .secondary,
        yTickFont: Font = .caption2,
        xTickFont: Font = .caption2,
        yTickColor: Color = .secondary,
        xTickColor: Color = .secondary,
        yTickLabel: @escaping (Double) -> String = { "\(Int($0))" },
        minXTickSpacing: CGFloat = 32,
        minYTickSpacing: CGFloat = 24,
        padXByHalfStep: Bool = false
    ) {
        self.yAxisPosition = yAxisPosition
        self.yMin = yMin
        self.yMax = yMax
        self.xMin = xMin
        self.xMax = xMax
        self.yStep = yStep
        self.xTicks = xTicks
        self.showYGrid = showYGrid
        self.showXGrid = showXGrid
        self.showYAxis = showYAxis
        self.showXAxis = showXAxis
        self.clipToRect = clipToRect
        self.yTickLabelOffset = yTickLabelOffset
        self.xTickLabelOffset = xTickLabelOffset
        self.gridColor = gridColor
        self.axisColor = axisColor
        self.yTickFont = yTickFont
        self.xTickFont = xTickFont
        self.yTickColor = yTickColor
        self.xTickColor = xTickColor
        self.yTickLabel = yTickLabel
        self.minXTickSpacing = minXTickSpacing
        self.minYTickSpacing = minYTickSpacing
        self.padXByHalfStep = padXByHalfStep
    }

    public struct XTick {
        public var position: Double    // data-space x
        public var label: String

        public init(position: Double, label: String) {
            self.position = position
            self.label = label
        }
    }
}

// MARK: - Chart Style (Layout)

public struct ChartStyle {
    public var leftAxisWidth: CGFloat = 36
    public var bottomAxisHeight: CGFloat = 20
    public var marginTop: CGFloat = 8
    public var marginRight: CGFloat = 8
    public var marginBottom: CGFloat = 4
    public var annotationPadding: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    public var annotationAvoidsAxisLabels: Bool = true

    public init(
        leftAxisWidth: CGFloat = 36,
        bottomAxisHeight: CGFloat = 20,
        marginTop: CGFloat = 8,
        marginRight: CGFloat = 8,
        marginBottom: CGFloat = 4,
        annotationPadding: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0),
        annotationAvoidsAxisLabels: Bool = true
    ) {
        self.leftAxisWidth = leftAxisWidth
        self.bottomAxisHeight = bottomAxisHeight
        self.marginTop = marginTop
        self.marginRight = marginRight
        self.marginBottom = marginBottom
        self.annotationPadding = annotationPadding
        self.annotationAvoidsAxisLabels = annotationAvoidsAxisLabels
    }

    public func chartRect(size: CGSize) -> CGRect {
        regions(size: size).plotRect
    }

    public func regions(size: CGSize) -> ChartRegions {
        let frameRect = CGRect(
            origin: .zero,
            size: CGSize(width: max(0, size.width), height: max(0, size.height))
        )
        let plotRect = CGRect(
            x: leftAxisWidth,
            y: marginTop,
            width: max(0, frameRect.width - leftAxisWidth - marginRight),
            height: max(0, frameRect.height - bottomAxisHeight - marginTop - marginBottom)
        )
        let yAxisRect = CGRect(
            x: frameRect.minX,
            y: plotRect.minY,
            width: max(0, plotRect.minX - frameRect.minX),
            height: plotRect.height
        )
        let xAxisRect = CGRect(
            x: plotRect.minX,
            y: plotRect.maxY,
            width: plotRect.width,
            height: max(0, frameRect.maxY - plotRect.maxY)
        )
        let baseAnnotationRect = annotationAvoidsAxisLabels ? plotRect : frameRect
        let annotationMinX = min(
            max(baseAnnotationRect.minX + annotationPadding.leading, frameRect.minX),
            frameRect.maxX
        )
        let annotationMinY = min(
            max(baseAnnotationRect.minY + annotationPadding.top, frameRect.minY),
            frameRect.maxY
        )
        let annotationMaxX = min(
            max(baseAnnotationRect.maxX - annotationPadding.trailing, annotationMinX),
            frameRect.maxX
        )
        let annotationMaxY = min(
            max(baseAnnotationRect.maxY - annotationPadding.bottom, annotationMinY),
            frameRect.maxY
        )
        let adjustedAnnotationRect = CGRect(
            x: annotationMinX,
            y: annotationMinY,
            width: annotationMaxX - annotationMinX,
            height: annotationMaxY - annotationMinY
        )

        return ChartRegions(
            frameRect: frameRect,
            plotRect: plotRect,
            annotationRect: adjustedAnnotationRect,
            axisLabelRects: ChartAxisLabelRects(yAxis: yAxisRect, xAxis: xAxisRect)
        )
    }
}

// MARK: - Chart Interaction

/// Interaction callbacks for Chart. All closures run on @MainActor.
public struct ChartInteraction: @unchecked Sendable {
    public var onHover: (@MainActor ((any ChartPointProtocol)?, CGPoint?, CGPoint?) -> Void)?
    public var onTap: (@MainActor ((any ChartPointProtocol)?) -> Void)?
    public var onZoom: (@MainActor (Double, Double) -> Void)?
    public var zoomGestureEnabled: Bool = false

    public init(
        onHover: (@MainActor ((any ChartPointProtocol)?, CGPoint?, CGPoint?) -> Void)? = nil,
        onTap: (@MainActor ((any ChartPointProtocol)?) -> Void)? = nil,
        onZoom: (@MainActor (Double, Double) -> Void)? = nil,
        zoomGestureEnabled: Bool = false
    ) {
        self.onHover = onHover
        self.onTap = onTap
        self.onZoom = onZoom
        self.zoomGestureEnabled = zoomGestureEnabled
    }
}
