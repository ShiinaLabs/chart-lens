import SwiftUI
import ChartLens

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selection: DemoPage?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Chart Types") {
                    ForEach(DemoPage.chartTypePages, id: \.self) { page in
                        Label(page.title, systemImage: page.icon)
                    }
                }
                Section("Interpolation") {
                    ForEach(DemoPage.interpolationPages, id: \.self) { page in
                        Label(page.title, systemImage: page.icon)
                    }
                }
                Section("Interaction") {
                    ForEach(DemoPage.interactionPages, id: \.self) { page in
                        Label(page.title, systemImage: page.icon)
                    }
                }
                Section("Composition") {
                    ForEach(DemoPage.compositionPages, id: \.self) { page in
                        Label(page.title, systemImage: page.icon)
                    }
                }
            }
            .navigationTitle("ChartLens")
        } detail: {
            if let selection {
                selection.view
            } else {
                Text("Select a demo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

enum DemoPage: String, CaseIterable {
    // Chart Types
    case basicCharts = "Basic Charts"
    case candlestick = "Candlestick"
    case bar = "Bar"
    case rangeBox = "Range & Box"
    case scatterBubble = "Scatter & Bubble"
    case gaussian = "Gaussian Spectrum"
    case sector = "Pie & Donut"

    // Interpolation
    case interpolation = "Interpolation Modes"
    case splineOvershoot = "Spline Overshoot"

    // Interaction
    case interactions = "Hover & Tap"
    case crosshair = "Crosshair"

    // Composition
    case detailOverview = "Detail + Overview"
    case overlays = "Custom Overlays"

    var title: String { rawValue }

    var icon: String {
        switch self {
        case .basicCharts: "chart.line.uptrend.xyaxis"
        case .candlestick: "chart.bar.doc.horizontal"
        case .bar: "chart.bar.fill"
        case .rangeBox: "chart.bar.doc.horizontal"
        case .scatterBubble: "circle.grid.cross.fill"
        case .gaussian: "waveform.path.ecg"
        case .sector: "chart.pie.fill"
        case .interpolation: "waveform.path"
        case .splineOvershoot: "arrow.triangle.branch"
        case .interactions: "cursorarrow.click.2"
        case .crosshair: "scope"
        case .detailOverview: "rectangle.split.2x1"
        case .overlays: "square.on.square"
        }
    }

    // MARK: - Groups

    static let chartTypePages: [DemoPage] = [.basicCharts, .candlestick, .bar, .rangeBox, .scatterBubble, .gaussian, .sector]
    static let interpolationPages: [DemoPage] = [.interpolation, .splineOvershoot]
    static let interactionPages: [DemoPage] = [.interactions, .crosshair]
    static let compositionPages: [DemoPage] = [.detailOverview, .overlays]

    @ViewBuilder var view: some View {
        switch self {
        case .basicCharts: BasicChartsDemo()
        case .candlestick: CandlestickDemo()
        case .bar: BarDemo()
        case .rangeBox: RangeDemo()
        case .scatterBubble: ScatterDemo()
        case .gaussian: GaussianDemo()
        case .sector: SectorDemo()
        case .interpolation: InterpolationDemo()
        case .splineOvershoot: SplineOvershootDemo()
        case .interactions: InteractionsDemo()
        case .crosshair: CrosshairDemo()
        case .detailOverview: DetailOverviewDemo()
        case .overlays: OverlayDemo()
        }
    }
}
