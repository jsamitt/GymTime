import SwiftUI
import SwiftData

/// Single-select exercise picker for adding an exercise to an in-progress
/// or just-finished session. Excludes exercises already used in this
/// session to avoid accidental duplicates. Tap a row to pick — the sheet
/// dismisses and `onPick` is called.
struct SessionExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    let session: Session
    let onPick: (Exercise) -> Void

    @State private var search: String = ""
    @State private var activeFilter: MuscleGroup? = nil

    private var sessionExerciseIds: Set<UUID> {
        Set(session.orderedLogs.compactMap { $0.exercise?.id })
    }

    private var available: [Exercise] {
        allExercises.filter { !sessionExerciseIds.contains($0.id) }
    }

    private var filtered: [Exercise] {
        var out = available
        if let m = activeFilter {
            out = out.filter { $0.muscleGroups.contains(m) }
        }
        if !search.isEmpty {
            out = out.filter { $0.name.localizedCaseInsensitiveContains(search) }
        }
        return out
    }

    private var grouped: [(MuscleGroup, [Exercise])] {
        let ordered: [MuscleGroup] = [.chest, .back, .shoulders, .triceps, .biceps, .quads, .hamstrings, .glutes, .calves, .core, .forearms]
        var out: [(MuscleGroup, [Exercise])] = []
        for m in ordered {
            let items = filtered.filter { $0.primaryMuscle == m }
            if !items.isEmpty { out.append((m, items)) }
        }
        return out
    }

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(GT.ink3)
                    TextField("", text: $search, prompt:
                        Text("Search exercises").foregroundColor(GT.ink3)
                    )
                    .font(.gtBody(14))
                    .foregroundColor(GT.ink)
                    .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .gtCard(radius: GT.rMd)
                .padding(.horizontal, 20)

                filterChips
                    .padding(.vertical, 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if grouped.isEmpty {
                            emptyState
                        } else {
                            ForEach(grouped, id: \.0) { group, items in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(group.display.uppercased())
                                        .gtMonoCaption(size: 10, tracking: 1.5)
                                        .padding(.horizontal, 24)
                                    VStack(spacing: 0) {
                                        ForEach(Array(items.enumerated()), id: \.element.id) { i, ex in
                                            Button {
                                                onPick(ex)
                                                dismiss()
                                            } label: {
                                                row(ex, isLast: i == items.count - 1)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .gtCard(radius: GT.rMd)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        Color.clear.frame(height: 30)
                    }
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
                Text("ADD EXERCISE")
                    .gtMonoCaption(size: 11, tracking: 1.4)
                Text("Extend workout")
                    .font(.gtDisplay(15, weight: .semibold))
                    .foregroundColor(GT.ink)
            }
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterChip("ALL", value: nil)
                ForEach([MuscleGroup.chest, .back, .quads, .shoulders, .biceps, .triceps], id: \.self) { m in
                    filterChip(m.display.uppercased(), value: m)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func filterChip(_ label: String, value: MuscleGroup?) -> some View {
        let on = activeFilter == value
        return Button { activeFilter = value } label: {
            Text(label)
                .font(.gtMono(10, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(on ? GT.limeInk : GT.ink2)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(on ? GT.lime : GT.surface))
                .overlay(Capsule().stroke(on ? .clear : GT.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func row(_ ex: Exercise, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ex.name)
                        .font(.gtBody(14))
                        .foregroundColor(GT.ink)
                    Text(ex.equipment.display.uppercased())
                        .font(.gtMono(9))
                        .tracking(0.8)
                        .foregroundColor(GT.ink3)
                }
                Spacer()
                if ex.topWorkingWeight > 0 {
                    Text("\(GTMath.formatWeight(ex.topWorkingWeight)) top")
                        .font(.gtMono(10))
                        .foregroundColor(GT.ink3)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(GT.ink3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            if !isLast {
                Rectangle().fill(GT.line).frame(height: 1)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundColor(GT.ink3)
            Text("No more exercises available")
                .font(.gtBody(13))
                .foregroundColor(GT.ink2)
            Text("All library exercises are already in this session.")
                .font(.gtMono(10))
                .foregroundColor(GT.ink3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
}
