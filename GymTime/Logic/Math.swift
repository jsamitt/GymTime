import Foundation

enum GTMath {
    /// Epley 1RM estimate. weight × (1 + reps/30).
    static func epley1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0, weight > 0 else { return 0 }
        return weight * (1.0 + Double(reps) / 30.0)
    }

    /// Round a weight up/down to nearest step (e.g. 2.5 lb).
    static func roundToStep(_ value: Double, step: Double) -> Double {
        guard step > 0 else { return value }
        return (value / step).rounded() * step
    }

    /// Warmup weight: top working × pct, rounded to step.
    static func warmupWeight(top: Double, pct: Double, step: Double) -> Double {
        roundToStep(top * pct, step: step)
    }

    /// mm:ss from seconds. Negative values clamp to 0:00.
    static func mmss(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    /// Short formatted weight with unit suffix.
    static func formatWeight(_ w: Double) -> String {
        if w == w.rounded() { return String(format: "%.0f", w) }
        return String(format: "%.1f", w)
    }

    /// Pretty "N.Nk" for volume totals above 1000.
    static func formatVolume(_ v: Double) -> String {
        if v >= 1000 {
            let k = v / 1000.0
            return String(format: "%.1fK", k)
        }
        return String(format: "%.0f", v)
    }

    /// Relative "2d ago" / "—" style label for a date in the past.
    static func relativeDays(from date: Date?, now: Date = Date()) -> String {
        guard let d = date else { return "—" }
        let days = Calendar.current.dateComponents([.day], from: d, to: now).day ?? 0
        if days <= 0 { return "today" }
        if days == 1 { return "1d ago" }
        return "\(days)d ago"
    }
}
