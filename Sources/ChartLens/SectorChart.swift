import SwiftUI

/// A native pie or donut chart for part-to-whole data.
public struct SectorChart<Overlay: View>: View {
    private let data: [SectorDatum]
    public var style: SectorStyle
    public var interaction: SectorInteraction
    private let overlay: (SectorGeometry, [SectorSlice]) -> Overlay

    public init(
        data: [SectorDatum],
        style: SectorStyle = .pie(),
        interaction: SectorInteraction = .init()
    ) where Overlay == EmptyView {
        self.init(data: data, style: style, interaction: interaction) { _, _ in
            EmptyView()
        }
    }

    public init(
        data: [SectorDatum],
        style: SectorStyle = .pie(),
        interaction: SectorInteraction = .init(),
        @ViewBuilder overlay: @escaping (SectorGeometry, [SectorSlice]) -> Overlay
    ) {
        self.data = data
        self.style = style
        self.interaction = interaction
        self.overlay = overlay
    }

    public var body: some View {
        GeometryReader { proxy in
            let slices = SectorLayout.slices(
                from: data,
                startAngle: style.startAngle,
                clockwise: style.clockwise
            )
            let geometry = SectorGeometry(size: proxy.size, style: style, slices: slices)

            ZStack {
                Canvas { context, _ in
                    SectorRendering.draw(context: &context, geometry: geometry, style: style)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(accessibilitySummary(for: slices)))

                overlay(geometry, slices)
            }
            .contentShape(Rectangle())
            .onContinuousHover(coordinateSpace: .local) { phase in
                switch phase {
                case .active(let location):
                    interaction.onHover?(geometry.slice(at: location))
                case .ended:
                    interaction.onHover?(nil)
                }
            }
            .onTapGesture(coordinateSpace: .local) { location in
                interaction.onTap?(geometry.slice(at: location))
            }
        }
    }

    private func accessibilitySummary(for slices: [SectorSlice]) -> String {
        let visibleSlices = slices.filter { $0.fraction > 0 && $0.fraction.isFinite }
        guard !visibleSlices.isEmpty else { return "Empty chart" }

        let descriptions = visibleSlices.map { slice in
            let label = slice.label ?? "Sector \(slice.index + 1)"
            let percentage = Int((slice.fraction * 100).rounded())
            return "\(label) \(percentage)%"
        }
        return "Chart with \(visibleSlices.count) sectors. \(descriptions.joined(separator: ", "))."
    }
}
