import Foundation
import SwiftData

/// Builds per-exercise set lists from the template + settings, and
/// walks the active session. Not persisted — reads/writes SwiftData.
@MainActor
final class SessionController: ObservableObject {
    @Published var session: Session
    /// Bumped on every structural mutation (log, skip, swap, append, defer,
    /// undefer, finish). ActiveSetView observes this controller via
    /// @ObservedObject, but `session` is a stable reference whose child
    /// log/set mutations don't fire objectWillChange on their own. Bumping
    /// this @Published value forces the view to re-render → recompute the
    /// cursor → update both the on-screen UI and the Live Activity.
    ///
    /// NOTE: never bump from `buildSets`, which is invoked lazily during
    /// view body evaluation (via the `currentSet` getter) — mutating
    /// published state mid-render is illegal.
    @Published private(set) var revision = 0
    private let context: ModelContext
    private let settings: AppSettings

    init(session: Session, context: ModelContext, settings: AppSettings) {
        self.session = session
        self.context = context
        self.settings = settings
    }

    private func bumpRevision() { revision &+= 1 }

    /// Build SetLogs for a given exercise. Base total comes from the
    /// per-exercise override or the global default. SetLabeler.warmupCount
    /// /loadCount decide how the count splits between warmups and loads.
    ///
    /// When `AppSettings.coldWarmupOncePerMuscle` is on AND this exercise
    /// has 4+ base sets AND another earlier log this session already
    /// targeted the same primary muscle, the leading "Warmup 1" is dropped
    /// — total sets reduces by one and the kept warmup becomes the kind=.warm
    /// (heavier 75%) variant.
    func buildSets(for log: ExerciseLog) {
        guard let ex = log.exercise else { return }
        // Don't rebuild if already populated
        if !(log.sets ?? []).isEmpty { return }

        let baseTotal: Int = {
            let raw = ex.useDefaultTotalSets ? settings.defaultTotalSets : ex.totalSets
            return max(1, min(7, raw))
        }()
        let baseWarmups = SetLabeler.warmupCount(forTotal: baseTotal)
        let baseLoads = SetLabeler.loadCount(forTotal: baseTotal)

        let muscleKey = ex.primaryMuscle?.rawValue ?? ""
        let shouldSkipW1 = settings.coldWarmupOncePerMuscle
            && baseTotal >= 4
            && muscleAlreadyWarmedUp(muscleKey, before: log)

        let warmups = shouldSkipW1 ? max(0, baseWarmups - 1) : baseWarmups
        let loads = baseLoads
        // When skipping W1 the kept warmup is the second one — index its
        // settings via offset so we use restWarm/warmPct/repsWarm.
        let warmupKindOffset = shouldSkipW1 ? 1 : 0

        var order = 0
        for i in 0..<warmups {
            let kindIndex = i + warmupKindOffset
            let kind: SetKind = kindIndex == 0 ? .cold : .warm
            let weight = ex.effectiveWeight(for: kind, settings: settings)
            let reps = ex.effectiveReps(for: kind, settings: settings)
            let rest = kindIndex == 0 ? settings.restCold : settings.restWarm
            let s = SetLog(kind: kind, weight: weight, reps: reps, plannedRestSec: rest, order: order)
            s.log = log
            context.insert(s)
            order += 1
        }
        for i in 0..<loads {
            let rest = settings.plannedRest(for: .load, loadingIndex: i)
            let reps = ex.effectiveReps(for: .load, loadingIndex: i, settings: settings)
            let weight = ex.effectiveWeight(for: .load, loadingIndex: i, settings: settings)
            let s = SetLog(kind: .load, weight: weight, reps: reps, plannedRestSec: rest, order: order)
            s.log = log
            context.insert(s)
            order += 1
        }
        try? context.save()
    }

    /// True if any earlier log this session targets the same primary muscle
    /// AND already has built sets (i.e. the user has at least started warming
    /// up that muscle group).
    private func muscleAlreadyWarmedUp(_ muscleKey: String, before currentLog: ExerciseLog) -> Bool {
        guard !muscleKey.isEmpty else { return false }
        for other in session.orderedLogs where other.id != currentLog.id {
            // Only count exercises that come BEFORE this one in the session.
            guard other.order < currentLog.order else { continue }
            // Must have at least one built set (otherwise it hasn't "warmed
            // up" anything — could just be an empty placeholder).
            guard !other.orderedSets.isEmpty else { continue }
            if other.exercise?.primaryMuscle?.rawValue == muscleKey { return true }
        }
        return false
    }

    func logSet(_ s: SetLog) {
        s.loggedAt = Date()
        try? context.save()
        bumpRevision()
    }

    func skipSet(_ s: SetLog) {
        s.skipped = true
        s.loggedAt = Date()
        try? context.save()
        bumpRevision()
    }

    func finish() {
        consolidateExerciseWeights()
        session.finishedAt = Date()
        try? context.save()
        bumpRevision()
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

    /// Append a new exercise to the end of the active session and build its
    /// sets. Used for "extend workout" — adding an exercise from the
    /// finishedOverlay or mid-workout. Cursor naturally re-activates because
    /// the new log has unlogged sets.
    func appendExerciseToSession(_ newExercise: Exercise) {
        let nextOrder = (session.orderedLogs.map(\.order).max() ?? -1) + 1
        let log = ExerciseLog(session: session, exercise: newExercise, order: nextOrder)
        context.insert(log)
        try? context.save()
        buildSets(for: log)
        bumpRevision()
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
        bumpRevision()
    }

    /// Persist ad-hoc edits to attached models (e.g. mutating a SetLog's weight
    /// from the UI). SetLog is managed by SwiftData; this flushes the change.
    func save() {
        try? context.save()
    }

    /// Return (log, setIndex) of the currently active set, or nil if done.
    /// Logs with no sets yet are treated as "upcoming" — sets will be built
    /// on demand when this log becomes active.
    ///
    /// Two-pass: first walks non-deferred logs in template order, then
    /// returns to deferred logs in original order. A user-initiated "Skip
    /// exercise (come back later)" sets `deferredAt` on the current log;
    /// the cursor will revisit it once everything else this session is done.
    func activeCursor() -> (ExerciseLog, Int)? {
        for log in session.orderedLogs where log.deferredAt == nil {
            if let c = cursor(within: log) { return c }
        }
        for log in session.orderedLogs where log.deferredAt != nil {
            if let c = cursor(within: log) { return c }
        }
        return nil
    }

    private func cursor(within log: ExerciseLog) -> (ExerciseLog, Int)? {
        let sets = log.orderedSets
        if sets.isEmpty { return (log, 0) }
        if let idx = sets.firstIndex(where: { $0.loggedAt == nil && !$0.skipped }) {
            return (log, idx)
        }
        return nil
    }

    /// Mark the current log as deferred so the cursor jumps past it. The
    /// next time `activeCursor()` runs, it picks the next non-deferred log;
    /// once all of those are exhausted, the deferred logs come back in
    /// their original template order.
    func deferCurrentExercise() {
        guard let (log, _) = activeCursor() else { return }
        log.deferredAt = Date()
        try? context.save()
        bumpRevision()
    }

    /// Un-defer the earliest (by template order) deferred log that still
    /// has unlogged sets. Called when the user taps the "Unskip" pill — the
    /// cursor then naturally advances to that log on its next evaluation.
    /// Returns true if a log was un-deferred.
    @discardableResult
    func undeferNext() -> Bool {
        let candidates = session.orderedLogs.filter { log in
            guard log.deferredAt != nil else { return false }
            let sets = log.orderedSets
            if sets.isEmpty { return true }
            return sets.contains(where: { $0.loggedAt == nil && !$0.skipped })
        }
        guard let target = candidates.first else { return false }
        target.deferredAt = nil
        try? context.save()
        bumpRevision()
        return true
    }

    /// Whether at least one deferred log this session still has unlogged
    /// sets. Drives the "Unskip" pill visibility in ActiveSetView.
    var hasDeferredExercises: Bool {
        for log in session.orderedLogs where log.deferredAt != nil {
            let sets = log.orderedSets
            if sets.isEmpty { return true }
            if sets.contains(where: { $0.loggedAt == nil && !$0.skipped }) {
                return true
            }
        }
        return false
    }
}
