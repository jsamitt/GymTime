import SwiftUI
import SwiftData
import WatchKit

struct WatchActiveSetView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var timer = RestTimerModel()
    let session: Session
    let settings: AppSettings

    @State private var seenColdMuscles: Set<String> = []
    @State private var showPicker = false

    /// Current active (log, set) or nil if done.
    private var cursor: (ExerciseLog, SetLog)? {
        for log in session.orderedLogs {
            let sets = log.orderedSets
            if sets.isEmpty {
                buildSets(for: log)
                let rebuilt = log.orderedSets
                if let first = rebuilt.first(where: { $0.loggedAt == nil && !$0.skipped }) {
                    return (log, first)
                }
                continue
            }
            if let next = sets.first(where: { $0.loggedAt == nil && !$0.skipped }) {
                return (log, next)
            }
        }
        return nil
    }

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            if let (log, set) = cursor {
                setContent(log: log, set: set)
            } else {
                doneState
            }
        }
        .onAppear {
            // Build sets for the current exercise (if it's a fresh session started
            // on iPhone but just landed on the watch via CloudKit).
            if let (log, _) = cursor { buildSets(for: log) }
        }
        .onDisappear { timer.stop() }
        .sheet(isPresented: $showPicker) {
            WatchTemplatePicker()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func setContent(log: ExerciseLog, set: SetLog) -> some View {
        // Progress ring wraps the whole screen with the rest timer.
        ZStack {
            if timer.isRunning || timer.didFire {
                Circle()
                    .stroke(GT.surface2, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: CGFloat(timer.progress))
                    .stroke(
                        timer.didFire ? GT.lime : GT.rest,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timer.progress)
            }

            VStack(spacing: 3) {
                Text("\(kindLabel(set, in: log.orderedSets)) · \(log.exerciseName)")
                    .font(.gtMono(11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundColor(set.kind == .load ? GT.lime : GT.ink2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // Weight row: − | weight | +
                HStack(spacing: 6) {
                    adjustButton("minus") { bumpWeight(set, by: -settings.weightStep) }
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(GTMath.formatWeight(set.weight))
                            .font(.gtDisplay(34, weight: .semibold))
                            .tracking(-1.2)
                            .foregroundColor(GT.ink)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text(settings.units.rawValue)
                            .font(.gtMono(11))
                            .foregroundColor(GT.ink3)
                    }
                    .frame(maxWidth: .infinity)
                    adjustButton("plus") { bumpWeight(set, by: settings.weightStep) }
                }

                // Reps row: − | × reps | +
                HStack(spacing: 6) {
                    adjustButton("minus") { bumpReps(set, by: -1) }
                    HStack(spacing: 3) {
                        Text("×")
                            .font(.gtDisplay(16, weight: .regular))
                            .foregroundColor(GT.ink3)
                        Text("\(set.reps)")
                            .font(.gtDisplay(26, weight: .semibold))
                            .foregroundColor(GT.lime)
                    }
                    .frame(maxWidth: .infinity)
                    adjustButton("plus") { bumpReps(set, by: 1) }
                }

                if timer.isRunning || timer.didFire {
                    Text(GTMath.mmss(timer.remainingSec))
                        .font(.gtMono(13, weight: .semibold))
                        .foregroundColor(timer.didFire ? GT.lime : GT.rest)
                        .padding(.top, 1)
                }

                Spacer(minLength: 2)

                HStack(spacing: 6) {
                    Button { skip(set) } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 42, height: 34)
                            .foregroundColor(GT.ink)
                            .background(Capsule().fill(GT.surface))
                            .overlay(Capsule().stroke(GT.line2, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button { logSet(set) } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                            Text("LOG")
                                .font(.gtDisplay(15, weight: .bold))
                                .tracking(-0.2)
                        }
                        .foregroundColor(GT.limeInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Capsule().fill(GT.lime))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    private var doneState: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 34))
                    .foregroundColor(GT.lime)
                Text("NICE WORK")
                    .font(.gtMono(10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(GT.lime)
                Text("\(GTMath.formatVolume(session.totalVolume)) lb")
                    .font(.gtDisplay(18, weight: .semibold))
                    .foregroundColor(GT.ink)
                Text("total volume")
                    .font(.gtMono(9))
                    .foregroundColor(GT.ink3)
                    .padding(.bottom, 4)

                Button {
                    finish()
                    showPicker = true
                } label: {
                    Text("NEW WORKOUT")
                        .font(.gtDisplay(13, weight: .bold))
                        .tracking(0.4)
                        .foregroundColor(GT.limeInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Capsule().fill(GT.lime))
                }
                .buttonStyle(.plain)

                Button { finish() } label: {
                    Text("EXIT")
                        .font(.gtDisplay(13, weight: .semibold))
                        .tracking(0.4)
                        .foregroundColor(GT.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Capsule().fill(GT.surface))
                        .overlay(Capsule().stroke(GT.line2, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private func adjustButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 28, height: 28)
                .foregroundColor(GT.ink)
                .background(Circle().fill(GT.surface2))
                .overlay(Circle().stroke(GT.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mutations

    private func bumpWeight(_ s: SetLog, by delta: Double) {
        s.weight = max(0, s.weight + delta)
        try? context.save()
    }

    private func bumpReps(_ s: SetLog, by delta: Int) {
        s.reps = max(1, min(50, s.reps + delta))
        try? context.save()
    }

    private func logSet(_ s: SetLog) {
        s.loggedAt = Date()
        if s.kind == .cold, let muscle = s.log?.exercise?.primaryMuscle?.rawValue {
            seenColdMuscles.insert(muscle)
        }
        try? context.save()
        startRestForNext()
    }

    private func skip(_ s: SetLog) {
        s.skipped = true
        s.loggedAt = Date()
        try? context.save()
        startRestForNext()
    }

    private func startRestForNext() {
        // After logging, the cursor advances. Start the rest timer for the
        // newly-active set's planned rest value.
        if let (log, next) = cursor {
            // Build sets for a newly-active exercise if it just came into focus.
            if log.orderedSets.isEmpty { buildSets(for: log) }
            timer.start(planned: next.plannedRestSec, hapticOnEnd: settings.hapticOnRestEnd)
        } else {
            timer.stop()
        }
    }

    private func finish() {
        session.finishedAt = Date()
        try? context.save()
    }

    // MARK: - Set building (mirrors iOS SessionController.buildSets)

    private func buildSets(for log: ExerciseLog) {
        guard let ex = log.exercise else { return }
        if !(log.sets ?? []).isEmpty { return }

        let top = ex.topWorkingWeight
        let muscleKey = ex.primaryMuscle?.rawValue ?? ""
        // Derive seen muscles from already-completed cold sets in this session.
        var seen = seenColdMuscles
        for l in session.orderedLogs where l.orderedSets.contains(where: { $0.kind == .cold && $0.loggedAt != nil }) {
            if let m = l.exercise?.primaryMuscle?.rawValue { seen.insert(m) }
        }
        let shouldIncludeCold = !muscleKey.isEmpty && !seen.contains(muscleKey)
        var order = 0

        if shouldIncludeCold {
            let w = ex.effectiveWeight(for: .cold, settings: settings)
            let reps = ex.effectiveReps(for: .cold, settings: settings)
            let s = SetLog(kind: .cold, weight: w, reps: reps, plannedRestSec: settings.restCold, order: order)
            s.log = log
            context.insert(s)
            order += 1
        }
        if !muscleKey.isEmpty { seenColdMuscles.insert(muscleKey) }

        let warmW = ex.effectiveWeight(for: .warm, settings: settings)
        let warmReps = ex.effectiveReps(for: .warm, settings: settings)
        let warmSet = SetLog(kind: .warm, weight: warmW, reps: warmReps, plannedRestSec: settings.restWarm, order: order)
        warmSet.log = log
        context.insert(warmSet)
        order += 1

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

    private func kindLabel(_ s: SetLog, in sets: [SetLog]) -> String {
        switch s.kind {
        case .cold: return "COLD"
        case .warm: return "WARM"
        case .load:
            let loads = sets.filter { $0.kind == .load }
            let idx = loads.firstIndex(where: { $0.id == s.id }) ?? 0
            return "LOAD \(idx + 1)"
        }
    }
}
