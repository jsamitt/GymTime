import Foundation

/// Pure functions for naming and counting sets within an exercise. Total
/// count drives the split between warmup and load sets, and the labels
/// follow this mapping:
///
/// - 1 set:   `Set 1`
/// - 2 sets:  `Warmup`, `Load`
/// - 3 sets:  `Warmup`, `Load 1`, `Load 2`
/// - 4 sets:  `Warmup 1`, `Warmup 2`, `Load 1`, `Load 2`
/// - 5 sets:  `Warmup 1`, `Warmup 2`, `Load 1`, `Load 2`, `Load 3`
/// - 6+ sets: warmups capped at 2, remainder are loads.
enum SetLabeler {
    /// Number of warmup sets given a total. Capped at 2; integer half of total.
    static func warmupCount(forTotal total: Int) -> Int {
        guard total > 1 else { return 0 }
        return min(2, total / 2)
    }

    /// Number of load sets given a total.
    static func loadCount(forTotal total: Int) -> Int {
        return max(0, total - warmupCount(forTotal: total))
    }

    /// Label for a 0-indexed set position within an exercise of `totalSets`
    /// total. Returns "Set 1" for the singleton case, omits the index suffix
    /// when there's only one warmup or only one load.
    static func label(forSetAt index: Int, totalSets total: Int) -> String {
        if total <= 1 { return "Set 1" }
        let warmups = warmupCount(forTotal: total)
        let loads = loadCount(forTotal: total)
        if index < warmups {
            return warmups == 1 ? "Warmup" : "Warmup \(index + 1)"
        } else {
            let loadIndex = index - warmups
            return loads == 1 ? "Load" : "Load \(loadIndex + 1)"
        }
    }

    /// Uppercased monospaced variant for compact UI (Live Activity, watch,
    /// etc.). Currently just `.uppercased()` of `label`, but kept as a
    /// distinct call for symmetry should we want spacing/abbreviations.
    static func compactLabel(forSetAt index: Int, totalSets total: Int) -> String {
        return label(forSetAt: index, totalSets: total).uppercased()
    }
}
