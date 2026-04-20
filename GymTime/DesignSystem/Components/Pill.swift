import SwiftUI

/// Rounded chip used for accented tags. Matches lib/primitives.jsx Pill.
struct Pill<Content: View>: View {
    var accent: Bool = false
    let content: () -> Content

    init(accent: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.accent = accent
        self.content = content
    }

    var body: some View {
        HStack(spacing: 6) { content() }
            .padding(.horizontal, 9)
            .frame(height: 22)
            .background(
                Capsule().fill(accent ? GT.limeWash : Color.white.opacity(0.06))
            )
            .overlay(
                Capsule().stroke(accent ? GT.limeEdge : GT.line, lineWidth: 1)
            )
            .font(.gtMono(11))
            .foregroundColor(accent ? GT.lime : GT.ink2)
    }
}
