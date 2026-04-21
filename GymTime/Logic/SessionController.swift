import Foundation
import SwiftData

/// Builds per-exercise set lists from the template + settings, and
/// walks the active session. Not persisted — reads/writes SwiftData.
@MainActor
final class SessionController: ObservableObject {
    @Published var session: Session
    private var seenColdMuscles: Set<String> = []
    private let context: ModelContext
    private let settings: AppSettings

    init(session: Session, context: ModelContext, settings: AppSettings) {
        self.session = session
        self.context = context
        self.settings = settings
        // Reconstruct "seen muscle groups" from already-completed logs
        // (for a resumed session).
        for log in session.orderedLogs where log.isComplete || log.orderedSets.contains(where: { $0.kind == .cold && $0.loggedAt != nil }) {
            if let muscle = log.exercise?.primaryMuscle?.rawValue {
                seenColdMuscles.insert(muscle)
            }
        }
    }

    /// Build SetLogs for a given exercise, honouring cold-warmup-once-per-muscle rule.
    func buildSets(for log: ExerciseLog) {
        guard let ex = log.exercise else { return }
        // Don't rebuild if already populated
        if !(log.sets ?? []).isEmpty { return }

        let top = ex.topWorkingWeight
        let muscleKey = ex.primaryMuscle?.rawValue ?? ""
        let shouldIncludeCold = !muscleKey.isEmpty && !seenColdMuscles.contains(muscleKey)
        var order = 0

        if shouldIncludeCold {
            let w = ex.effectiveWeight(for: .cold, settings: settings)
            let reps = ex.effectiveReps(for: .cold, settings: settings)
            let s = SetLog(kind: .cold, weight: w, reps: reps, plannedRestSec: settings.restCold, order: order)
            s.log = log
            context.insert(s)
            order += 1
        }
        if !muscleKey.isEmpty {
            seenColdMuscles.insert(muscleKey)
        }
        // One continuing-warmup set
        let warmW = ex.effectiveWeight(for: .warm, settings: settings)
        let warmReps = ex.effectiveReps(for: .warm, settings: settings)
        let warmSet = SetLog(kind: .warm, weight: warmW, reps: warmReps, plannedRestSec: settings.restWarm, order: order)
        warmSet.log = log
        context.insert(warmSet)
        order += 1

        // Loading sets
        for i in 0..<max(1, ex.numLoadingSets) {
            let rest = settings.plannedRest(for: .load, loadingIndex: i)
            let reps = ex.effectiveReps(for: .load, loadingIndex: i, settings: settings)
            let s = SetLog(kind: .load, weight: top, reps: reps, plannedRestSec: rest, order: order)
            s.log = log
            context.insert(s)
            order += 1
        }
        try? context.save()
    }

    func logSet(_ s: SetLog) {
        s.loggedAt = Date()
        if s.kind == .cold,
           let muscle = s.log?.exercise?.primaryMuscle?.rawValue {
            seenColdMuscles.insert(muscle)
        }
        try? context.save()
    }

    func skipSet(_ s: SetLog) {
        s.skipped = true
        s.loggedAt = Date()
        try? context.save()
    }

    func finish() {
        session.finishedAt = Date()
        try? context.save()
    }

    /// Delete the session entirely (cascades to ExerciseLogs and SetLogs).
    func abandon() {
        context.delete(session)
        try? context.save()
    }

    /// Persist ad-hoc edits to attached models (e.g. mutating a SetLog's weight
    /// from the UI). SetLog is managed by SwiftData; this flushes the change.
    func save() {
        try? context.save()
    }

    /// Return (log, setIndex) of the currently active set, or nil if done.
    /// Logs with no sets yet are treated as "upcoming" — sets will be built
    /// on demand when this log becomes active.
    func activeCursor() -> (ExerciseLog, Int)? {
        for log in session.orderedLogs {
            let sets = log.orderedSets
            if sets.isEmpty { return (log, 0) }
            if let idx = sets.firstIndex(where: { $0.loggedAt == nil && !$0.skipped }) {
                return (log, idx)
            }
        }
        return nil
    }
}
