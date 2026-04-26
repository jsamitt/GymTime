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

    // MARK: - Kind-aware (used at runtime when the actual stored set list
    //         may not follow the default warmup/load split — e.g. when the
    //         "Perform Warmup 1 only on first exercise per muscle" setting
    //         dropped the leading warmup).

    /// Label given an explicit (warmups, loads) split. Use when the caller
    /// already knows the split because it built the sets.
    static func label(forSetAt index: Int, warmups: Int, loads: Int) -> String {
        let total = warmups + loads
        if total <= 1 { return "Set 1" }
        if index < warmups {
            return warmups == 1 ? "Warmup" : "Warmup \(index + 1)"
        } else {
            let loadIndex = index - warmups
            return loads == 1 ? "Load" : "Load \(loadIndex + 1)"
        }
    }

    /// Label for `set` within `sets` based on each set's stored `kind`. This
    /// handles the "skipped Warmup 1" case correctly: if there are 1 warmup
    /// and 3 loads, labels are "Warmup, Load 1, Load 2, Load 3" regardless
    /// of what the original total was.
    static func label(forSet set: SetLog, in sets: [SetLog]) -> String {
        let (warmups, loads) = warmupAndLoadCounts(in: sets)
        let index = sets.firstIndex(where: { $0.id == set.id }) ?? 0
        return label(forSetAt: index, warmups: warmups, loads: loads)
    }

    static func compactLabel(forSet set: SetLog, in sets: [SetLog]) -> String {
        return label(forSet: set, in: sets).uppercased()
    }

    static func compactLabel(forSetAt index: Int, in sets: [SetLog]) -> String {
        let (warmups, loads) = warmupAndLoadCounts(in: sets)
        return label(forSetAt: index, warmups: warmups, loads: loads).uppercased()
    }

    /// Counts warmup-kind (.cold or .warm) vs load-kind sets in the given
    /// list, preserving the assumption that warmups come before loads in
    /// the ordered list (which is how buildSets emits them).
    static func warmupAndLoadCounts(in sets: [SetLog]) -> (warmups: Int, loads: Int) {
        var w = 0, l = 0
        for s in sets {
            if s.kind == .load { l += 1 } else { w += 1 }
        }
        return (w, l)
    }
}
