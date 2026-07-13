# ChartLens API Reference

## Protocols

### ChartPointProtocol

```swift
public protocol ChartPointProtocol: Sendable {
    var x: Double { get }
    var yRange: (min: Double, max: Double) { get }
    var displayY: Double { get }  // default: yRange.min
    var xLabel: String? { get }   // default: nil (categorical x-axis label)
}
```

All data points conform to this protocol. `yRange` defines the Y extent for auto-ranging; `displayY` is the representative Y used for hit-test screen positioning. `xLabel`, when set, is drawn on the x-axis at the point's `x` (an evenly-spaced categorical tick), so bars/boxes/error bars can carry text labels instead of numeric x values.

### ChartSeriesRenderer

```swift
public protocol ChartSeriesRenderer<Point>: Sendable {
    associatedtype Point: ChartPointProtocol
    func render(context: inout GraphicsContext, points: [Point], geometry: ChartGeometry, style: ChartSeriesStyle)
}
```

One implementation per chart type. Receives pre-computed geometry (includes data↔pixel mapping).

### ChartSeriesProtocol

```swift
public protocol ChartSeriesProtocol<Point>: Sendable {
    associatedtype Point: ChartPointProtocol
    var id: String { get }
    var points: [Point] { get }
    var style: ChartSeriesStyle { get }
    func render(context: inout GraphicsContext, geometry: ChartGeometry)
}
```

The erased protocol used by `Chart<Overlay>` to store mixed series types as `[any ChartSeriesProtocol]`.

## Data Types

### ChartPoint

```swift
public struct ChartPoint: ChartPointProtocol {
    public var x: Double
    public var y: Double
    public var color: Color?   // nil → fall back to style.color; used by bar renderer
    public var xLabel: String? // nil → no x-axis tick; set for a categorical label
    // yRange → (y, y), displayY → y
}
```

Standard 2D data point for line/area/dot charts. `color` lets individual bars override the series `style.color`.

### CandlestickPoint

```swift
public struct CandlestickPoint: ChartPointProtocol {
    public let x: Double
    public let open, high, low, close: Double
    // yRange → (low, high), displayY → close
}
```

OHLC data point for K-line / candlestick charts.

### RangePoint

```swift
public struct RangePoint: ChartPointProtocol {
    public let x: Double
    public let center, low, high: Double
    public let xLabel: String?  // nil → no x-axis tick
    // yRange → (low, high), displayY → center
}
```

Center value with a `[low, high]` interval, for error bars.

### BoxPlotPoint

```swift
public struct BoxPlotPoint: ChartPointProtocol {
    public let x: Double
    public let min, q1, median, q3, max: Double
    public let xLabel: String?  // nil → no x-axis tick
    public var outliers: [Double] = []
    // yRange → (min, max), displayY → median
}
```

Quartiles, whiskers, and outliers for a full box plot.

### BubblePoint

```swift
public struct BubblePoint: ChartPointProtocol {
    public let x: Double
    public let y: Double
    public let radius: CGFloat   // pixel radius (zoom-independent)
    public var value: Double = 0 // payload for tooltips
    // yRange → (y, y), displayY → y
}
```

Scatter point whose drawn radius encodes a third (size) dimension.

### ChartSeries\<Point\>

```swift
public struct ChartSeries<Point: ChartPointProtocol>: ChartSeriesProtocol {
    public let id: String
    public var points: [Point]
    public var style: ChartSeriesStyle
    public var renderer: any ChartSeriesRenderer<Point>
}

// Convenience init (uses LineRenderer)
extension ChartSeries where Point == ChartPoint {
    public init(id: String, points: [ChartPoint], style: ChartSeriesStyle)
}

// Chart-type factories
extension ChartSeries where Point == ChartPoint {
    public static func bars(id: String, points: [ChartPoint], color: Color = .blue, opacity: Double = 1.0, lineWidth: CGFloat = 0) -> ChartSeries<ChartPoint>
}
extension ChartSeries where Point == RangePoint {
    public static func errorBars(id: String, points: [RangePoint], style: ChartSeriesStyle = .line(color: .primary)) -> ChartSeries<RangePoint>
}
extension ChartSeries where Point == BoxPlotPoint {
    public static func boxPlot(id: String, points: [BoxPlotPoint], style: ChartSeriesStyle = .bars(color: .blue, opacity: 0.15, lineWidth: 1)) -> ChartSeries<BoxPlotPoint>
}
extension ChartSeries where Point == BubblePoint {
    public static func bubbles(id: String, points: [BubblePoint], style: ChartSeriesStyle = .bars(color: .blue, opacity: 0.6)) -> ChartSeries<BubblePoint>
}
```

### ChartSeriesStyle

```swift
public struct ChartSeriesStyle: Sendable {
    public var color: Color          // .blue
    public var lineWidth: CGFloat    // 1.5
    public var areaOpacity: Double   // 0 (no fill)
    public var pointRadius: CGFloat  // 0 (no dots)
    public var strokeOpacity: Double // 1.0
    public var interpolation: Interpolation  // .linear
    public var baseline: Double?     // nil (fill to bottom)

    // Factory methods
    public static func area(color:opacity:lineWidth:) -> ChartSeriesStyle
    public static func line(color:lineWidth:) -> ChartSeriesStyle
    public static func dots(color:radius:) -> ChartSeriesStyle
}
```

### Interpolation

```swift
public enum Interpolation: Equatable, Sendable {
    case linear
    case catmullRom
    case clampedCubic
    case step
    case gaussian(sigma: Double, baseline: Double)
}
```

## Renderers

Each chart type is a `ChartSeriesRenderer<Point>` that draws into a `GraphicsContext` using `geometry.dataToPoint(x:y:)`.

```swift
public struct LineRenderer: ChartSeriesRenderer<ChartPoint>        // line / area / dot / step / gaussian
public struct CandlestickRenderer: ChartSeriesRenderer<CandlestickPoint>
public struct BarRenderer: ChartSeriesRenderer<ChartPoint>        // vertical bars, baseline-aware; per-point color overrides series color
public struct ErrorBarRenderer: ChartSeriesRenderer<RangePoint>   // center ± low/high with caps
public struct BoxPlotRenderer: ChartSeriesRenderer<BoxPlotPoint>  // quartiles + whiskers + outliers
public struct BubbleRenderer: ChartSeriesRenderer<BubblePoint>    // per-point radius
```

`BarRenderer` resolves the baseline from `style.baseline`, defaulting to `0` when visible (otherwise the nearest axis bound). `BubbleRenderer` draws each point at its pixel `radius` (zoom-independent, like `pointRadius`).

## Layout Types

### ChartStyle

```swift
public struct ChartStyle {
    public var leftAxisWidth: CGFloat   // 36
    public var bottomAxisHeight: CGFloat // 20
    public var marginTop: CGFloat       // 8
    public var marginRight: CGFloat     // 8
    public var marginBottom: CGFloat    // 4
    // ...
    public func regions(size:) -> ChartRegions
    public func chartRect(size:) -> CGRect
}
```

Controls plot area margins. `leftAxisWidth` is automatically expanded to fit Y-axis labels.

### ChartAxisConfig

```swift
public struct ChartAxisConfig {
    public var yAxisPosition: YAxisPosition  // .left or .right
    public var yMin, yMax: Double?           // nil = auto
    public var xMin, xMax: Double?           // nil = auto
    public var yStep: Double                 // 10
    public var xTicks: [XTick]               // []  (when empty, ticks are auto-built from each point's xLabel)
    public var showYGrid: Bool               // true
    public var clipToRect: Bool              // true
    public var padXByHalfStep: Bool          // false (pad auto x-bounds by half the min x-gap)
    public var yTickLabel: (Double) -> String  // "\(Int($0))"
    // ...
}
```

### ChartGeometry

```swift
public struct ChartGeometry: Sendable {
    public let plotRect: CGRect       // (aka chartRect)
    public let xMin, xMax, yMin, yMax: Double
    public var scaleX, scaleY: CGFloat

    public func dataToPoint(x:y:) -> CGPoint
    public func pointToData(screenPoint:) -> (x: Double, y: Double)
}
```

Coordinate mapping between data space and screen pixels.

## Chart View

### Chart\<Overlay\>

```swift
public struct Chart<Overlay: View>: View {
    // No overlay variant
    public init(series: [any ChartSeriesProtocol], axis: ..., style: ..., interaction: ...)

    // With overlay
    public init(
        series: [any ChartSeriesProtocol],
        ...,
        @ViewBuilder overlay: (ChartGeometry, [any ChartSeriesProtocol]) -> Overlay
    )
}
```

### ChartInteraction

```swift
public struct ChartInteraction: @unchecked Sendable {
    public var onHover: (@MainActor ((any ChartPointProtocol)?, CGPoint?, CGPoint?) -> Void)?
    public var onTap: (@MainActor ((any ChartPointProtocol)?) -> Void)?
    public var onZoom: (@MainActor (Double, Double) -> Void)?
    public var zoomGestureEnabled: Bool  // false
}
```

Callbacks fire on `@MainActor`. `onHover` receives (point, screenPoint, cursorLocation). `onTap` receives the nearest point by X. `onZoom` receives the selected X range.

## Crosshair

### CrosshairConfig

```swift
public struct CrosshairConfig {
    public var lineColor, pointColor, valueLabelColor, xLabelColor: Color
    public var lineWidth: CGFloat, pointRadius: CGFloat
    public var showValueLabel, showXLabel: Bool
    public var valueLabelFont, xLabelFont: Font
    public var valueLabelFormatter: (Double) -> String  // default: "%.3f"
    public var valueLabelBackgroundColor: Color          // default: .black
}
```

### CrosshairOverlay

```swift
public struct CrosshairOverlay: View {
    public init(
        geometry: ChartGeometry,
        hoverPoint: (any ChartPointProtocol)?,
        cursorScreenX: CGFloat? = nil,
        config: CrosshairConfig = .init()
    )
}
```

Renders a vertical line at cursor X, a highlighted data-point circle, and gradient-background value/X labels. The consumer wires up `ChartInteraction.onHover` to pass live state.

## Other Utilities

- `drawAxes(context:chartRect:color:lineWidth:)` — draw X/Y axis lines
- `drawYAxisGrid(context:chartRect:yMin:yMax:scaleY:step:gridColor:lineWidth:labelColor:)` — grid + labels
- `drawAreaAndLine(context:areaPath:linePath:fillColor:strokeColor:lineWidth:)` — fill area + stroke edge
- `evenlySpacedTickIndices(count:targetCount:)` — compute tick indices
- `chartDurationLabel(_:)` — format time duration for axis labels
- `catmullRomSpline(points:)` / `clampedCubicSpline(points:)` — spline path generation
