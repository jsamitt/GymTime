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
        consolidateExerciseWeights()
        session.finishedAt = Date()
        try? context.save()
    }

    /// After a workout, carry the final loading-set weight forward to the
    /// exercise definition so the next session starts at the new top weight.
    /// Warmup math still flows from AppSettings percentages.
    private func consolidateExerciseWeights() {
        for log in session.orderedLogs {
            guard let ex = log.exercise else { continue }
            let loggedLoads = log.orderedSets.filter {
                $0.kind == .load && $0.loggedAt != nil && !$0.skipped
            }
            guard let last = loggedLoads.last, last.weight > 0 else { continue }
            ex.topWorkingWeight = last.weight
        }
    }

    /// Delete the session entirely (cascades to ExerciseLogs and SetLogs).
    func abandon() {
        context.delete(session)
        try? context.save()
    }

    /// Swap the current in-progress exercise with a different one (ad-hoc, does
    /// not modify the underlying template). Preserves any already-logged sets
    /// from the original exercise for history, marks remaining unlogged sets
    /// as skipped, and inserts a new ExerciseLog right after the current one.
    /// If nothing was logged yet in the current log, the exercise is just
    /// replaced in place so the log order stays clean.
    func swapCurrentExercise(to newExercise: Exercise) {
        guard let (currentLog, _) = activeCursor() else { return }
        let hasLoggedProgress = currentLog.orderedSets.contains {
            $0.loggedAt != nil && !$0.skipped
        }

        if hasLoggedProgress {
            // Skip remaining planned sets on original so it's visually complete.
            for set in currentLog.orderedSets where set.loggedAt == nil {
                set.skipped = true
                set.loggedAt = Date()
            }
            // Shift subsequent logs down by one so the new log slots in next.
            let insertAt = currentLog.order + 1
            for other in session.orderedLogs where other.order >= insertAt && other.id != currentLog.id {
                other.order += 1
            }
            let fresh = ExerciseLog(session: session, exercise: newExercise, order: insertAt)
            context.insert(fresh)
            try? context.save()
            buildSets(for: fresh)
        } else {
            // Nothing logged — clean in-place replace.
            for s in currentLog.orderedSets {
                context.delete(s)
            }
            currentLog.exercise = newExercise
            currentLog.exerciseName = newExercise.name
            try? context.save()
            buildSets(for: currentLog)
        }
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
