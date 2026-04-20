import Foundation
import SwiftData

enum SetKind: String, Codable, CaseIterable {
    case cold, warm, load
    var display: String {
        switch self {
        case .cold: return "Cold warmup"
        case .warm: return "Continuing warmup"
        case .load: return "Loading set"
        }
    }
    var shortLabel: String {
        switch self {
        case .cold: return "COLD WARMUP"
        case .warm: return "CONTINUING WARMUP"
        case .load: return "LOADING SET"
        }
    }
}

@Model
final class Session {
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var finishedAt: Date?
    var templateName: String = ""

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
    var exerciseLogs: [ExerciseLog]? = []

    init(templateName: String, startedAt: Date = Date()) {
        self.templateName = templateName
        self.startedAt = startedAt
    }

    var orderedLogs: [ExerciseLog] {
        (exerciseLogs ?? []).sorted { $0.order < $1.order }
    }

    var isActive: Bool { finishedAt == nil }

    var totalVolume: Double {
        var sum: Double = 0
        for log in orderedLogs {
            for set in log.orderedSets where set.kind == .load && set.loggedAt != nil {
                sum += set.weight * Double(set.reps)
            }
        }
        return sum
    }
}

@Model
final class ExerciseLog {
    var id: UUID = UUID()
    var order: Int = 0
    var session: Session?
    var exercise: Exercise?
    var exerciseName: String = ""

    @Relationship(deleteRule: .cascade, inverse: \SetLog.log)
    var sets: [SetLog]? = []

    init(session: Session, exercise: Exercise, order: Int) {
        self.session = session
        self.exercise = exercise
        self.exerciseName = exercise.name
        self.order = order
    }

    var orderedSets: [SetLog] {
        (sets ?? []).sorted { $0.order < $1.order }
    }

    var isComplete: Bool {
        let all = orderedSets
        return !all.isEmpty && all.allSatisfy { $0.loggedAt != nil || $0.skipped }
    }
}

@Model
final class SetLog {
    var id: UUID = UUID()
    var order: Int = 0
    var kindRaw: String = SetKind.load.rawValue
    var weight: Double = 0
    var reps: Int = 0
    var plannedRestSec: Int = 150
    var loggedAt: Date?
    var skipped: Bool = false
    var log: ExerciseLog?

    init(
        kind: SetKind,
        weight: Double,
        reps: Int,
        plannedRestSec: Int,
        order: Int
    ) {
        self.kindRaw = kind.rawValue
        self.weight = weight
        self.reps = reps
        self.plannedRestSec = plannedRestSec
        self.order = order
    }

    var kind: SetKind {
        get { SetKind(rawValue: kindRaw) ?? .load }
        set { kindRaw = newValue.rawValue }
    }
}
