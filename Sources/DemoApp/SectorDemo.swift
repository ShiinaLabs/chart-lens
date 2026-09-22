import SwiftUI
import ChartLens

struct SectorDemo: View {
    private let data = [
        SectorDatum(id: "success", value: 62, label: "Success"),
        SectorDatum(id: "pending", value: 23, label: "Pending"),
        SectorDatum(id: "failed", value: 15, label: "Failed"),
    ]

    @State private var hoveredID: String?
    @State private var selectedID: String?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 20) {
                DemoCard(title: "Basic Pie") {
                    SectorChart(data: data, style: .pie(angularGap: .degrees(2)))
                }
                DemoCard(title: "Donut") {
                    SectorChart(data: data, style: .donut(angularGap: .degrees(2)))
                }
                DemoCard(title: "Hover & Tap") {
                    interactiveChart
                }
                DemoCard(title: "Empty & Zero Data") {
                    HStack(spacing: 20) {
                        SectorChart(data: [])
                        SectorChart(data: data.map { SectorDatum(id: $0.id, value: 0, label: $0.label) }, style: .donut())
                    }
                }
            }
            .padding()
        }
    }

    private var interactiveChart: some View {
        VStack(spacing: 8) {
            SectorChart(
                data: data,
                style: .donut(innerRadiusRatio: 0.58, angularGap: .degrees(2)),
                interaction: SectorInteraction(
                    onHover: { slice in hoveredID = slice?.id },
                    onTap: { slice in selectedID = slice?.id }
                )
            ) { geometry, slices in
                if let activeID = hoveredID,
                   let activeSlice = slices.first(where: { $0.id == activeID }) {
                    Text(activeSlice.label ?? activeSlice.id)
                        .font(.caption.weight(.semibold))
                        .position(geometry.centroid(of: activeSlice))
                }
            }
            .overlay(alignment: .bottom) {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var statusText: String {
        if let selectedID,
           let selected = data.first(where: { $0.id == selectedID }) {
            return "Selected: \(selected.label ?? selected.id)"
        }
        if let hoveredID,
           let hovered = data.first(where: { $0.id == hoveredID }) {
            return "Hovering: \(hovered.label ?? hovered.id)"
        }
        return "Hover a sector or click to select"
    }
}
