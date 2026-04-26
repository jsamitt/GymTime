import Foundation
import SwiftData

enum Units: String, Codable { case lb, kg }

@Model
final class AppSettings {
    var id: UUID = UUID()
    var unitsRaw: String = Units.lb.rawValue
    var coldPct: Double = 0.50
    var warmPct: Double = 0.75
    var weightStep: Double = 5.0
    var repStep: Int = 1
    /// Default number of total sets per exercise (warmups + loads combined).
    /// SetLabeler.warmupCount(forTotal:) splits this between warmup and load
    /// kinds, and SetLabeler.label(forSetAt:totalSets:) names them.
    /// Default 4 corresponds to "Warmup 1, Warmup 2, Load 1, Load 2".
    var defaultTotalSets: Int = 4

    var restCold: Int = 0
    var restWarm: Int = 90
    var restLoad1: Int = 150
    var restLoad2: Int = 210

    // Reps per set kind (defaults applied to new exercises; overridable per-exercise).
    var repsCold: Int = 10
    var repsWarm: Int = 8
    var repsLoad1: Int = 6
    var repsLoad2: Int = 5

    var hapticOnRestEnd: Bool = true
    var autoAdvance: Bool = true
    var keepAwake: Bool = true

    /// When true, the very first warmup ("Warmup 1") is dropped on any
    /// 4-set-or-larger exercise after the first one targeting the same
    /// primary muscle in a session. Default off.
    var coldWarmupOncePerMuscle: Bool = false

    init() {}

    var units: Units {
        get { Units(rawValue: unitsRaw) ?? .lb }
        set { unitsRaw = newValue.rawValue }
    }

    func plannedRest(for kind: SetKind, loadingIndex: Int) -> Int {
        switch kind {
        case .cold: return restCold
        case .warm: return restWarm
        case .load: return loadingIndex == 0 ? restLoad1 : restLoad2
        }
    }

    func defaultReps(for kind: SetKind, loadingIndex: Int) -> Int {
        switch kind {
        case .cold: return repsCold
        case .warm: return repsWarm
        case .load: return loadingIndex == 0 ? repsLoad1 : repsLoad2
        }
    }
}
