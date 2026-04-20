import SwiftUI

/// Pill-shaped [−  value  +] stepper — ported from lib/primitives.jsx.
struct GTStepper: View {
    let value: String
    var unit: String? = nil
    var size: Size = .md
    var onMinus: () -> Void = {}
    var onPlus: () -> Void = {}

    enum Size { case sm, md, lg
        var h: CGFloat { self == .lg ? 52 : self == .sm ? 34 : 44 }
        var fs: CGFloat { self == .lg ? 28 : self == .sm ? 15 : 20 }
        var minW: CGFloat { self == .lg ? 110 : 72 }
    }

    var body: some View {
        let h = size.h
        HStack(spacing: 0) {
            button(symbol: "minus", accent: false)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.gtMono(size.fs, weight: .medium))
                    .foregroundColor(GT.ink)
                if let unit = unit {
                    Text(unit)
                        .font(.gtMono(size.fs * 0.55))
                        .foregroundColor(GT.ink3)
                }
            }
            .padding(.horizontal, 10)
            .frame(minWidth: size.minW)
            button(symbol: "plus", accent: true)
        }
        .padding(4)
        .frame(height: h)
        .background(
            Capsule().fill(GT.surface2)
        )
        .overlay(
            Capsule().stroke(GT.line, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func button(symbol: String, accent: Bool) -> some View {
        let d = size.h - 8
        Button(action: symbol == "minus" ? onMinus : onPlus) {
            Image(systemName: symbol)
                .font(.system(size: d * 0.42, weight: .medium))
                .frame(width: d, height: d)
                .foregroundColor(accent ? GT.ink : GT.ink2)
        }
        .buttonStyle(.plain)
    }
}
