import SwiftUI

/// Tiny sparkline — polyline + end dot. Ported from lib/primitives.jsx.
struct Spark: View {
    let data: [Double]
    var width: CGFloat = 54
    var height: CGFloat = 18
    var color: Color = GT.lime
    var dim: Bool = false

    var body: some View {
        Canvas { ctx, size in
            guard data.count >= 2 else { return }
            let minV = data.min()!
            let maxV = data.max()!
            let range = max(0.0001, maxV - minV)
            let w = size.width
            let h = size.height
            var path = Path()
            var lastPoint: CGPoint = .zero
            for (i, v) in data.enumerated() {
                let x = CGFloat(i) / CGFloat(data.count - 1) * w
                let y = h - CGFloat((v - minV) / range) * (h - 2) - 1
                let p = CGPoint(x: x, y: y)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                lastPoint = p
            }
            let stroke = dim ? GT.ink3 : color
            ctx.stroke(path, with: .color(stroke), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            // End dot
            let dot = Path(ellipseIn: CGRect(x: lastPoint.x - 2, y: lastPoint.y - 2, width: 4, height: 4))
            ctx.fill(dot, with: .color(stroke))
        }
        .frame(width: width, height: height)
    }
}
