import SwiftUI
import SwiftData

/// Read-only "see the whole workout" sheet, presented from the active-set
/// header. Lists every exercise in the current session and its sets, with
/// state badges (logged / current / upcoming / skipped). Highlights the
/// current cursor position. Doesn't allow jumping the cursor — keeps state
/// consistent with the in-flight rest timer + Live Activity.
struct WorkoutOverviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let session: Session
    /// ID of the SetLog the controller's cursor currently points at, used
    /// to highlight the active row.
    let currentSetID: UUID?

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        summaryBar
                        ForEach(session.orderedLogs) { log in
                            exerciseCard(log)
                        }
                        Color.clear.frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(GT.surface2))
                    .overlay(Circle().stroke(GT.line, lineWidth: 1))
                    .foregroundColor(GT.ink)
            }
            .buttonStyle(.plain)
            Spacer()
            VStack(spacing: 2) {
                Text("WORKOUT")
                    .gtMonoCaption(size: 11, tracking: 1.4)
                Text(session.templateName)
                    .font(.gtDisplay(15, weight: .semibold))
                    .foregroundColor(GT.ink)
            }
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var summaryBar: some View {
        let logs = session.orderedLogs
        let totalSets = logs.flatMap { $0.orderedSets }.count
        let loggedSets = logs.flatMap { $0.orderedSets }.filter { $0.loggedAt != nil && !$0.skipped }.count
        let progress: Double = totalSets > 0 ? Double(loggedSets) / Double(totalSets) : 0
        return HStack(spacing: 10) {
            tile("EXERCISES", value: "\(logs.count)")
            tile("SETS", value: "\(loggedSets)/\(totalSets)")
            tile("PROGRESS", value: "\(Int(progress * 100))%")
        }
    }

    private func tile(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .gtMonoCaption(size: 9, tracking: 1.3)
            Text(value)
                .font(.gtDisplay(18, weight: .semibold))
                .foregroundColor(GT.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.rMd)
    }

    private func exerciseCard(_ log: ExerciseLog) -> some View {
        let sets = log.orderedSets
        let isCurrentExercise = sets.contains { $0.id == currentSetID }
        let allDone = !sets.isEmpty && sets.allSatisfy { $0.loggedAt != nil || $0.skipped }
        let isDeferred = log.deferredAt != nil && !allDone && !isCurrentExercise
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(log.exerciseName)
                    .font(.gtDisplay(17, weight: .semibold))
                    .foregroundColor(GT.ink)
                    .lineLimit(1)
                Spacer()
                if isCurrentExercise {
                    statusPill("NOW", lime: true)
                } else if isDeferred {
                    statusPill("LATER", lime: false, dim: false)
                } else if allDone {
                    statusPill("DONE", lime: false, dim: true)
                }
            }

            if sets.isEmpty {
                Text("Sets will be built when you reach this exercise.")
                    .font(.gtMono(10))
                    .foregroundColor(GT.ink3)
            } else {
                VStack(spacing: 4) {
                    ForEach(sets) { setRow(set: $0, log: log) }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.rMd)
    }

    @ViewBuilder
    private func setRow(set: SetLog, log: ExerciseLog) -> some View {
        let sets = log.orderedSets
        let kindLabel = SetLabeler.compactLabel(forSet: set, in: sets)
        let isCurrent = set.id == currentSetID
        let logged = set.loggedAt != nil && !set.skipped
        let skipped = set.skipped

        HStack(spacing: 10) {
            Text(kindLabel)
                .font(.gtMono(9, weight: .medium))
                .tracking(1.0)
                .foregroundColor(set.kind == .load ? GT.lime : GT.ink3)
                .frame(width: 78, alignment: .leading)

            Text("\(GTMath.formatWeight(set.weight)) lb × \(set.reps)")
                .font(.gtMono(12, weight: logged || isCurrent ? .medium : .regular))
                .foregroundColor(rowTextColor(logged: logged, current: isCurrent, skipped: skipped))

            Spacer()

            if isCurrent {
                statusPill("NOW", lime: true)
            } else if logged {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(GT.lime)
            } else if skipped {
                Text("SKIP")
                    .font(.gtMono(9, weight: .semibold))
                    .tracking(1.0)
                    .foregroundColor(GT.ink3)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrent ? GT.limeWashSoft : GT.surface2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? GT.limeEdge : GT.line, lineWidth: 1)
        )
    }

    private func rowTextColor(logged: Bool, current: Bool, skipped: Bool) -> Color {
        if current { return GT.ink }
        if skipped { return GT.ink3 }
        if logged { return GT.ink }
        return GT.ink2
    }

    private func statusPill(_ text: String, lime: Bool, dim: Bool = false) -> some View {
        Text(text)
            .font(.gtMono(9, weight: .bold))
            .tracking(1.2)
            .foregroundColor(lime ? GT.limeInk : (dim ? GT.ink3 : GT.ink))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(lime ? GT.lime : GT.surface))
            .overlay(Capsule().stroke(lime ? .clear : GT.line, lineWidth: 1))
    }

}
