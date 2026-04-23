import SwiftUI
import SwiftData

/// Mid-workout ad-hoc swap: pick another exercise from the same primary muscle
/// group to substitute for the current one. Excludes exercises already used in
/// this session to avoid accidental duplicates.
struct ExerciseSwapPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    let currentExercise: Exercise
    let sessionLog: ExerciseLog
    let onSelect: (Exercise) -> Void

    private var muscle: MuscleGroup? { currentExercise.primaryMuscle }

    private var sessionExerciseIds: Set<UUID> {
        let logs = sessionLog.session?.orderedLogs ?? []
        return Set(logs.compactMap { $0.exercise?.id })
    }

    private var candidates: [Exercise] {
        guard let m = muscle else { return [] }
        return allExercises.filter { ex in
            ex.id != currentExercise.id
            && ex.primaryMuscle == m
            && !sessionExerciseIds.contains(ex.id)
        }
    }

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header
                if candidates.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(candidates) { ex in
                                Button {
                                    onSelect(ex)
                                    dismiss()
                                } label: {
                                    row(ex)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                Text("SWAP EXERCISE")
                    .gtMonoCaption(size: 11, tracking: 1.4)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Replace")
                    .gtMonoCaption(size: 10, tracking: 1.3)
                Text(currentExercise.name)
                    .font(.gtDisplay(22, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundColor(GT.ink)
                if let m = muscle {
                    Text("ANY \(m.display.uppercased())")
                        .font(.gtMono(10, weight: .medium))
                        .tracking(1.0)
                        .foregroundColor(GT.lime)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }

    private func row(_ ex: Exercise) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ex.name)
                    .font(.gtDisplay(16, weight: .semibold))
                    .foregroundColor(GT.ink)
                HStack(spacing: 8) {
                    Text(ex.equipment.display.uppercased())
                    if ex.topWorkingWeight > 0 {
                        Text("·")
                        Text("\(GTMath.formatWeight(ex.topWorkingWeight)) top")
                    }
                }
                .font(.gtMono(10))
                .foregroundColor(GT.ink3)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(GT.ink3)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .gtCard(radius: GT.rMd)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 32))
                .foregroundColor(GT.ink3)
            Text("No other \(muscle?.display.lowercased() ?? "muscle") exercises available")
                .font(.gtBody(13))
                .foregroundColor(GT.ink2)
                .multilineTextAlignment(.center)
            Text("Add more in Library.")
                .font(.gtMono(10))
                .foregroundColor(GT.ink3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
