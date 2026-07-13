import SwiftUI

/// Universal chart component. Renders grid, axes, curves, fills, and dots from a
/// `[ChartSeries]` array. All business-specific overlays (tooltips, labels, heatmaps)
/// are injected via an overlay ViewBuilder that receives the computed ChartGeometry.
public struct Chart<Overlay: View>: View {
    let series: [any ChartSeriesProtocol]
    public var axis: ChartAxisConfig = .init()
    public var style: ChartStyle = .init()
    public var interaction: ChartInteraction = .init()
    @ViewBuilder var overlay: (ChartGeometry, [any ChartSeriesProtocol]) -> Overlay

    public init(
        series: [any ChartSeriesProtocol],
        axis: ChartAxisConfig = .init(),
        style: ChartStyle = .init(),
        interaction: ChartInteraction = .init()
    ) where Overlay == EmptyView {
        self.series = series
        self.axis = axis
        self.style = style
        self.interaction = interaction
        self.overlay = { _, _ in EmptyView() }
    }

    public init(
        series: [any ChartSeriesProtocol],
        axis: ChartAxisConfig = .init(),
        style: ChartStyle = .init(),
        interaction: ChartInteraction = .init(),
        @ViewBuilder overlay: @escaping (ChartGeometry, [any ChartSeriesProtocol]) -> Overlay
    ) {
        self.series = series
        self.axis = axis
        self.style = style
        self.interaction = interaction
        self.overlay = overlay
    }

    @State private var hoverPoint: (any ChartPointProtocol)?
    @State private var cursorScreenPt: CGPoint?
    @State private var internalTapPoint: (any ChartPointProtocol)?

    private var accessibilityDescription: String {
        let visibleSeries = series.filter { !$0.points.isEmpty }
        guard !visibleSeries.isEmpty else { return "Empty chart" }
        let seriesCount = visibleSeries.count
        let pointCount = visibleSeries.reduce(0) { $0 + $1.points.count }
        let allRanges = visibleSeries.flatMap { $0.points.map(\.yRange) }
        guard let minY = allRanges.map(\.min).min(),
              let maxY = allRanges.map(\.max).max() else {
            return "Chart with \(seriesCount) series"
        }
        return "Chart with \(seriesCount) series, \(pointCount) data points, values from \(Int(minY)) to \(Int(maxY))"
    }

    public var body: some View {
        GeometryReader { geometry in
            let geo = computeGeo(size: geometry.size)

            ZStack {
                Canvas { context, _ in
                    drawContent(context: &context, geo: geo)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityDescription)

                overlay(geo, series)
            }
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                guard let (pt, _) = hitTest(location: location, geo: geo) else { return }
                interaction.onTap?(pt)
            }
            .onContinuousHover(coordinateSpace: .local) { phase in
                switch phase {
                case .active(let location):
                    if let (pt, screenPt) = hitTest(location: location, geo: geo) {
                        hoverPoint = pt
                        cursorScreenPt = location
                        interaction.onHover?(pt, screenPt, location)
                    } else {
                        hoverPoint = nil
                        cursorScreenPt = nil
                        interaction.onHover?(nil, nil, nil)
                    }
                case .ended:
                    hoverPoint = nil
                    cursorScreenPt = nil
                    interaction.onHover?(nil, nil, nil)
                }
            }
            .simultaneousGesture(
                interaction.zoomGestureEnabled && interaction.onZoom != nil
                    ? zoomGesture(geo: geo)
                    : nil
            )
        }
    }

    // MARK: - Geometry

    private func computeGeo(size: CGSize) -> ChartGeometry {
        var adjustedStyle = style
        if axis.showYGrid {
            let (yMin, yMax) = computeYRange()
            let step = max(1e-6, axis.yStep)
            let count = Int(((yMax - yMin) / step).rounded())
            var maxWidth: CGFloat = 0
            let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10)]
            for i in 0...count {
                let val = yMin + Double(i) * step
                let w = (axis.yTickLabel(val) as NSString).size(withAttributes: attrs).width
                maxWidth = max(maxWidth, w)
            }
            if axis.yAxisPosition == .right {
                adjustedStyle.marginRight = max(style.marginRight, maxWidth + axis.yTickLabelOffset + 8)
            } else {
                adjustedStyle.leftAxisWidth = max(style.leftAxisWidth, maxWidth + axis.yTickLabelOffset + 8)
            }
        }
        let regions = adjustedStyle.regions(size: size)
        let (yMin, yMax) = computeYRange()
        let xMin = computeXMin()
        let xMax = computeXMax()
        return ChartGeometry(
            frameRect: regions.frameRect,
            plotRect: regions.plotRect,
            annotationRect: regions.annotationRect,
            axisLabelRects: regions.axisLabelRects,
            xMin: xMin,
            xMax: xMax,
            yMin: yMin,
            yMax: yMax
        )
    }

    private func computeYRange() -> (Double, Double) {
        let allRanges = series.flatMap { $0.points.map(\.yRange) }
        let dataMin = allRanges.map(\.min).min() ?? -100
        let dataMax = allRanges.map(\.max).max() ?? 0
        let rawMin = axis.yMin ?? dataMin
        let rawMax = axis.yMax ?? dataMax
        let step = max(1e-6, axis.yStep)
        let yMin = floor(rawMin / step) * step
        let yMax = ceil(rawMax / step) * step
        return (yMin, yMax)
    }

    private func computeXMin() -> Double {
        if let xMin = axis.xMin { return xMin }
        let xs = series.flatMap { $0.points.map(\.x) }
        return axis.padXByHalfStep && xs.count >= 2 ? (xs.min() ?? 0) - halfXStep(xs: xs) : (xs.min() ?? 0)
    }

    private func computeXMax() -> Double {
        if let xMax = axis.xMax { return xMax }
        let xs = series.flatMap { $0.points.map(\.x) }
        return axis.padXByHalfStep && xs.count >= 2 ? (xs.max() ?? 1) + halfXStep(xs: xs) : (xs.max() ?? 1)
    }

    /// Half the smallest gap between sorted x values — used to pad auto x-bounds
    /// so elements drawn centered on an x value aren't clipped at the edges.
    private func halfXStep(xs: [Double]) -> Double {
        let sorted = xs.sorted()
        var minGap = Double.infinity
        for i in 1..<sorted.count {
            let g = sorted[i] - sorted[i - 1]
            if g > 0 { minGap = min(minGap, g) }
        }
        if minGap.isFinite, minGap > 0 { return minGap / 2 }
        let span = (sorted.last ?? 1) - (sorted.first ?? 0)
        return max(1e-6, span / 2)
    }

    /// Builds x-axis ticks from each point's `xLabel` when `axis.xTicks` is empty.
    /// Placing a tick at the point's own x keeps the label centered under the
    /// element (bar, box, error bar), mirroring a categorical axis.
    private func autoXTicks() -> [ChartAxisConfig.XTick] {
        var seen = Set<Double>()
        var ticks: [ChartAxisConfig.XTick] = []
        for s in series {
            for pt in s.points {
                if let label = pt.xLabel, !seen.contains(pt.x) {
                    seen.insert(pt.x)
                    ticks.append(ChartAxisConfig.XTick(position: pt.x, label: label))
                }
            }
        }
        return ticks.sorted { $0.position < $1.position }
    }

    // MARK: - Canvas Content

    private func drawContent(context: inout GraphicsContext, geo: ChartGeometry) {
        let rect = geo.chartRect

        // Y-axis grid + labels
        if axis.showYGrid {
            let step = max(1e-6, axis.yStep)
            let count = Int(((geo.yMax - geo.yMin) / step).rounded())
            var lastLabelY: CGFloat = -.greatestFiniteMagnitude
            for i in 0...count {
                let val = geo.yMin + Double(i) * step
                let y = rect.maxY - (val - geo.yMin) * geo.scaleY
                var line = Path()
                line.move(to: CGPoint(x: rect.minX, y: y))
                line.addLine(to: CGPoint(x: rect.maxX, y: y))
                context.stroke(line, with: .color(axis.gridColor), lineWidth: 1)
                if axis.minYTickSpacing > 0, abs(y - lastLabelY) < axis.minYTickSpacing { continue }
                lastLabelY = y
                let label = Text(axis.yTickLabel(val)).font(axis.yTickFont).foregroundColor(axis.yTickColor)
                let w = context.resolve(label).measure(in: CGSize(width: 200, height: 30)).width
                let labelX: CGFloat
                if axis.yAxisPosition == .right {
                    labelX = rect.maxX + axis.yTickLabelOffset + w / 2
                } else {
                    labelX = max(w / 2 + 4, rect.minX - axis.yTickLabelOffset - w / 2)
                }
                context.draw(label, at: CGPoint(x: labelX, y: y))
            }
        }

        // X-axis ticks + labels
        let xTicks = axis.xTicks.isEmpty ? autoXTicks() : axis.xTicks
        var lastLabelX: CGFloat = -.greatestFiniteMagnitude
        for tick in xTicks where tick.position >= geo.xMin && tick.position <= geo.xMax {
            let x = rect.minX + (tick.position - geo.xMin) * geo.scaleX
            if axis.minXTickSpacing > 0, abs(x - lastLabelX) < axis.minXTickSpacing { continue }
            lastLabelX = x
            context.draw(
                Text(tick.label).font(axis.xTickFont).foregroundColor(axis.xTickColor),
                at: CGPoint(x: x, y: rect.maxY + axis.xTickLabelOffset)
            )
        }

        // Axis lines
        if axis.showXAxis {
            var p = Path(); p.move(to: CGPoint(x: rect.minX, y: rect.maxY)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            context.stroke(p, with: .color(axis.axisColor), lineWidth: 1)
        }
        if axis.showYAxis {
            let axisX = axis.yAxisPosition == .right ? rect.maxX : rect.minX
            var p = Path(); p.move(to: CGPoint(x: axisX, y: rect.minY)); p.addLine(to: CGPoint(x: axisX, y: rect.maxY))
            context.stroke(p, with: .color(axis.axisColor), lineWidth: 1)
        }

        // Clip
        if axis.clipToRect { context.clip(to: Path(rect)) }

        // Series
        for s in series {
            s.render(context: &context, geometry: geo)
        }
    }

    // MARK: - Hit Testing

    private func hitTest(location: CGPoint, geo: ChartGeometry) -> (any ChartPointProtocol, CGPoint)? {
        guard geo.chartRect.contains(location) else { return nil }
        var best: (any ChartPointProtocol, CGPoint)?
        var bestDx: CGFloat = .greatestFiniteMagnitude

        for s in series {
            for pt in s.points {
                let screen = geo.dataToPoint(x: pt.x, y: pt.displayY)
                let dx = abs(screen.x - location.x)
                if dx < bestDx { bestDx = dx; best = (pt, screen) }
            }
        }
        return best
    }

    // MARK: - Zoom Gesture

    private func zoomGesture(geo: ChartGeometry) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onEnded { value in
                let startX = min(value.startLocation.x, value.location.x)
                let endX = max(value.startLocation.x, value.location.x)
                guard endX - startX > 20 else { return }
                let relStart = Swift.max(0.0, startX - geo.chartRect.minX)
                let relEnd = Swift.min(geo.chartRect.width, endX - geo.chartRect.minX)
                let lo = geo.xMin + (relStart / geo.chartRect.width) * (geo.xMax - geo.xMin)
                let hi = geo.xMin + (relEnd / geo.chartRect.width) * (geo.xMax - geo.xMin)
                interaction.onZoom?(lo, hi)
            }
    }
}

extension Chart where Overlay == CrosshairOverlay {
    /// Convenience init that creates a crosshair overlay with no internal hover state.
    /// The caller is responsible for wiring up hover state via ChartInteraction.onHover
    /// and passing hoverPoint/cursorScreenX to CrosshairOverlay.
    public init(
        series: [any ChartSeriesProtocol],
        axis: ChartAxisConfig = .init(),
        style: ChartStyle = .init(),
        interaction: ChartInteraction = .init(),
        crosshair: CrosshairConfig
    ) {
        self.series = series
        self.axis = axis
        self.style = style
        self.interaction = interaction
        self.overlay = { geo, _ in
            CrosshairOverlay(geometry: geo, hoverPoint: nil, config: crosshair)
        }
    }
}
