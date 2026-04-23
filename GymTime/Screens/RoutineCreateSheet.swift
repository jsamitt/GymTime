import SwiftUI
import SwiftData

/// Two-screen flow for creating a routine from scratch:
/// 1. Name + subtitle form → tap Save → persists a new WorkoutTemplate
/// 2. Exercise multi-picker → tap any exercise row to toggle inclusion →
///    tap Done to dismiss the sheet (changes persist live).
///
/// Closing the sheet on screen 1 cancels without creating anything. Closing
/// on screen 2 keeps whatever exercises were already selected (the template
/// is already saved).
struct RoutineCreateSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutTemplate.order) private var allTemplates: [WorkoutTemplate]

    @State private var draftName: String = ""
    @State private var draftSubtitle: String = ""
    @State private var createdTemplate: WorkoutTemplate?
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if let t = createdTemplate {
                    RoutineExercisePicker(template: t) {
                        dismiss()
                    }
                } else {
                    formStep
                }
            }
            .background(GT.bg.ignoresSafeArea())
        }
    }

    // MARK: - Form step

    private var formStep: some View {
        VStack(alignment: .leading, spacing: 18) {
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
                Text("NEW ROUTINE")
                    .gtMonoCaption(size: 11, tracking: 1.4)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Create")
                    .font(.gtDisplay(34, weight: .semibold))
                    .tracking(-1)
                    .foregroundColor(GT.ink)
                Text("Give it a name and a short description. You'll add exercises on the next step.")
                    .font(.gtBody(13))
                    .foregroundColor(GT.ink3)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("NAME")
                    .gtMonoCaption(size: 10, tracking: 1.3)
                TextField("", text: $draftName, prompt:
                    Text("e.g. Push, Pull, Legs").foregroundColor(GT.ink3)
                )
                .font(.gtDisplay(22, weight: .semibold))
                .tracking(-0.4)
                .foregroundColor(GT.ink)
                .textInputAutocapitalization(.words)
                .focused($nameFocused)
                .padding(12)
                .gtCard(radius: GT.rMd)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("DESCRIPTION (OPTIONAL)")
                    .gtMonoCaption(size: 10, tracking: 1.3)
                TextField("", text: $draftSubtitle, prompt:
                    Text("e.g. chest · shoulders · triceps").foregroundColor(GT.ink3)
                )
                .font(.gtBody(14))
                .foregroundColor(GT.ink2)
                .textInputAutocapitalization(.none)
                .padding(12)
                .gtCard(radius: GT.rMd)
            }

            Spacer()

            Button { saveAndContinue() } label: {
                Text("SAVE + ADD EXERCISES")
                    .font(.gtDisplay(15, weight: .bold))
                    .tracking(0.4)
                    .foregroundColor(canSave ? GT.limeInk : GT.ink3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(canSave ? GT.lime : GT.surface))
                    .overlay(Capsule().stroke(canSave ? .clear : GT.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 28)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                nameFocused = true
            }
        }
    }

    private var canSave: Bool {
        !draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveAndContinue() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let nextOrder = (allTemplates.map(\.order).max() ?? -1) + 1
        let t = WorkoutTemplate(
            name: name,
            subtitle: draftSubtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            order: nextOrder
        )
        context.insert(t)
        try? context.save()
        createdTemplate = t
    }
}

// MARK: - Multi-select exercise picker

/// Used as the second step of routine creation (and reusable for editing
/// a routine's exercise list from anywhere). Tap any row to toggle whether
/// that exercise is in the routine. Creates or removes TemplateExercise
/// rows live, preserving insertion order.
struct RoutineExercisePicker: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    let template: WorkoutTemplate
    let onDone: () -> Void

    @State private var search: String = ""

    private var includedIds: Set<UUID> {
        Set((template.templateExercises ?? []).compactMap { $0.exercise?.id })
    }

    private var filtered: [Exercise] {
        guard !search.isEmpty else { return allExercises }
        return allExercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
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
        VStack(alignment: .leading, spacing: 0) {
            header

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(GT.ink3)
                TextField("", text: $search, prompt:
                    Text("Filter exercises").foregroundColor(GT.ink3)
                )
                .font(.gtBody(14))
                .foregroundColor(GT.ink)
                .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .gtCard(radius: GT.rMd)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(grouped, id: \.0) { group, items in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(group.display.uppercased())
                                .gtMonoCaption(size: 10, tracking: 1.5)
                                .padding(.horizontal, 24)
                            VStack(spacing: 0) {
                                ForEach(Array(items.enumerated()), id: \.element.id) { i, ex in
                                    Button {
                                        toggle(ex)
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
                    Color.clear.frame(height: 20)
                }
            }
        }
        .padding(.top, 10)
    }

    private var header: some View {
        HStack {
            Spacer()
                .frame(width: 36, height: 36)
            Spacer()
            VStack(spacing: 2) {
                Text("ADD EXERCISES")
                    .gtMonoCaption(size: 11, tracking: 1.4)
                Text(template.name)
                    .font(.gtDisplay(18, weight: .semibold))
                    .foregroundColor(GT.ink)
                Text("\(includedIds.count) selected")
                    .font(.gtMono(10))
                    .foregroundColor(GT.ink3)
            }
            Spacer()
            Button { onDone() } label: {
                Text("Done")
                    .font(.gtDisplay(14, weight: .semibold))
                    .foregroundColor(GT.lime)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(Capsule().fill(GT.surface2))
                    .overlay(Capsule().stroke(GT.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func row(_ ex: Exercise, isLast: Bool) -> some View {
        let on = includedIds.contains(ex.id)
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(on ? GT.lime : Color.clear)
                    if !on {
                        RoundedRectangle(cornerRadius: 6).stroke(GT.line2, lineWidth: 1.5)
                    }
                    if on {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(GT.limeInk)
                    }
                }
                .frame(width: 22, height: 22)

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
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if !isLast {
                Rectangle().fill(GT.line).frame(height: 1)
            }
        }
    }

    private func toggle(_ ex: Exercise) {
        let existing = (template.templateExercises ?? []).filter { $0.exercise?.id == ex.id }
        if !existing.isEmpty {
            for e in existing { context.delete(e) }
        } else {
            let nextOrder = (template.templateExercises ?? []).map(\.order).max().map { $0 + 1 } ?? 0
            let te = TemplateExercise(template: template, exercise: ex, order: nextOrder)
            context.insert(te)
        }
        try? context.save()
    }
}
