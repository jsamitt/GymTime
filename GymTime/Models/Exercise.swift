import Foundation
import SwiftData

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, shoulders, triceps, biceps, quads, hamstrings, glutes, calves, core, forearms
    var id: String { rawValue }
    var display: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .triceps: return "Triceps"
        case .biceps: return "Biceps"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .core: return "Core"
        case .forearms: return "Forearms"
        }
    }
}

enum Equipment: String, Codable, CaseIterable {
    case barbell, dumbbell, machine, cable, bodyweight, kettlebell
    var display: String { rawValue.capitalized }
}

@Model
final class Exercise {
    var id: UUID = UUID()
    var name: String = ""
    var muscleGroupsRaw: [String] = []
    var equipmentRaw: String = Equipment.barbell.rawValue
    var notes: String = ""
    var topWorkingWeight: Double = 0
    var repTarget: Int = 5
    var numLoadingSets: Int = 2
    var isInLibrary: Bool = true
    var createdAt: Date = Date()

    // Per-exercise rep overrides. 0 = inherit from AppSettings.
    var repsColdOverride: Int = 0
    var repsWarmOverride: Int = 0
    var repsLoad1Override: Int = 0
    var repsLoad2Override: Int = 0

    // Per-exercise warmup weight overrides. 0 = use the pct formula.
    // (Loading sets always use topWorkingWeight.)
    var weightColdOverride: Double = 0
    var weightWarmOverride: Double = 0

    // Inverses required by CloudKit sync — deleting an exercise nullifies
    // references rather than cascading so history is preserved.
    @Relationship(deleteRule: .nullify, inverse: \TemplateExercise.exercise)
    var templateReferences: [TemplateExercise]? = []

    @Relationship(deleteRule: .nullify, inverse: \ExerciseLog.exercise)
    var logReferences: [ExerciseLog]? = []

    init(
        name: String,
        muscles: [MuscleGroup],
        equipment: Equipment = .barbell,
        notes: String = "",
        topWorkingWeight: Double = 0,
        repTarget: Int = 5,
        numLoadingSets: Int = 2,
        isInLibrary: Bool = true
    ) {
        self.name = name
        self.muscleGroupsRaw = muscles.map(\.rawValue)
        self.equipmentRaw = equipment.rawValue
        self.notes = notes
        self.topWorkingWeight = topWorkingWeight
        self.repTarget = repTarget
        self.numLoadingSets = numLoadingSets
        self.isInLibrary = isInLibrary
    }

    var muscleGroups: [MuscleGroup] {
        get { muscleGroupsRaw.compactMap(MuscleGroup.init(rawValue:)) }
        set { muscleGroupsRaw = newValue.map(\.rawValue) }
    }
    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .barbell }
        set { equipmentRaw = newValue.rawValue }
    }
    var primaryMuscle: MuscleGroup? { muscleGroups.first }

    /// Weight for the given set kind. Warmups use a per-exercise override if set,
    /// else the AppSettings pct formula. Loading sets always use topWorkingWeight.
    func effectiveWeight(for kind: SetKind, settings: AppSettings?) -> Double {
        let s = settings ?? AppSettings()
        switch kind {
        case .cold:
            if weightColdOverride > 0 { return weightColdOverride }
            return GTMath.warmupWeight(top: topWorkingWeight, pct: s.coldPct, step: s.weightStep)
        case .warm:
            if weightWarmOverride > 0 { return weightWarmOverride }
            return GTMath.warmupWeight(top: topWorkingWeight, pct: s.warmPct, step: s.weightStep)
        case .load:
            return topWorkingWeight
        }
    }

    /// Reps for the given set kind — per-exercise override if non-zero, else the
    /// AppSettings default. Falls back to 5 if neither is set.
    func effectiveReps(for kind: SetKind, loadingIndex: Int = 0, settings: AppSettings?) -> Int {
        let override: Int
        switch kind {
        case .cold: override = repsColdOverride
        case .warm: override = repsWarmOverride
        case .load: override = loadingIndex == 0 ? repsLoad1Override : repsLoad2Override
        }
        if override > 0 { return override }
        return settings?.defaultReps(for: kind, loadingIndex: loadingIndex) ?? 5
    }
}
