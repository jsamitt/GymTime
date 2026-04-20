import SwiftUI

/// Three-up stat tile row on Home. Matches lib/screens-a.jsx.
struct StatTile: View {
    let label: String
    let value: String
    let unit: String
    var accent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.gtMono(10, weight: .medium))
                .tracking(1.2)
                .foregroundColor(accent ? GT.lime : GT.ink3)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.gtDisplay(24, weight: .semibold))
                    .tracking(-0.8)
                    .foregroundColor(accent ? GT.lime : GT.ink)
                Text(unit)
                    .font(.gtMono(11))
                    .foregroundColor(accent ? GT.lime : GT.ink3)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(
            radius: GT.rMd,
            fill: accent ? GT.limeWashSoft : GT.surface,
            border: accent ? GT.limeEdge : GT.line
        )
    }
}
