import SwiftUI
import SwiftData

/// Pick an existing Library exercise to add to a template, or create a new one
/// inline. Excludes exercises already in the template.
struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    let template: WorkoutTemplate
    @State private var search: String = ""
    @State private var newlyCreated: Exercise?

    private var existingIds: Set<UUID> {
        Set((template.templateExercises ?? []).compactMap { $0.exercise?.id })
    }

    private var available: [Exercise] {
        allExercises.filter { !existingIds.contains($0.id) }
    }

    private var filtered: [Exercise] {
        guard !search.isEmpty else { return available }
        return available.filter { $0.name.localizedCaseInsensitiveContains(search) }
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
                // Top bar
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
                    Text("ADD TO \(template.name.uppercased())")
                        .gtMonoCaption(size: 11, tracking: 1.4)
                    Spacer()
                    // Same width as close button for symmetry
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 14)

                Text("Add exercise")
                    .font(.gtDisplay(28, weight: .semibold))
                    .tracking(-0.8)
                    .foregroundColor(GT.ink)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(GT.ink3)
                    TextField("", text: $search, prompt:
                        Text("Search or create").foregroundColor(GT.ink3))
                        .font(.gtBody(14))
                        .foregroundColor(GT.ink)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                    if !search.isEmpty {
                        Button { search = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(GT.ink3)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .gtCard(radius: GT.rMd)
                .padding(.horizontal, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Create new (if search doesn't match anything)
                        if !search.isEmpty && !filtered.contains(where: { $0.name.caseInsensitiveCompare(search) == .orderedSame }) {
                            Button { createAndAdd(named: search) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(GT.lime)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Create \"\(search)\"")
                                            .font(.gtDisplay(15, weight: .semibold))
                                            .foregroundColor(GT.ink)
                                        Text("New exercise · add to \(template.name)")
                                            .font(.gtMono(11))
                                            .foregroundColor(GT.ink3)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .gtCard(radius: GT.rMd, fill: GT.limeWashSoft, border: GT.limeEdge)
                            }
                            .buttonStyle(.plain)
                        }

                        if filtered.isEmpty && search.isEmpty {
                            Text("Every library exercise is already in this workout.")
                                .font(.gtBody(13))
                                .foregroundColor(GT.ink3)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .gtCard(radius: GT.rMd)
                        }

                        ForEach(grouped, id: \.0) { group, items in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.display.uppercased())
                                    .gtMonoCaption(size: 10, tracking: 1.5)
                                    .padding(.horizontal, 4)
                                VStack(spacing: 0) {
                                    ForEach(Array(items.enumerated()), id: \.element.id) { i, ex in
                                        Button { addExisting(ex) } label: {
                                            pickerRow(ex, isLast: i == items.count - 1)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .gtCard(radius: GT.rMd)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(item: $newlyCreated) { ex in
            ExerciseEditView(exercise: ex)
        }
    }

    private func pickerRow(_ ex: Exercise, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(ex.name.isEmpty ? "—" : ex.name)
                    .font(.gtBody(14))
                    .foregroundColor(GT.ink)
                Spacer()
                Text("\(ex.equipment.display.uppercased())")
                    .font(.gtMono(10))
                    .foregroundColor(GT.ink3)
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(GT.lime)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            if !isLast {
                Rectangle().fill(GT.line).frame(height: 1)
            }
        }
    }

    private func addExisting(_ ex: Exercise) {
        appendToTemplate(ex)
        dismiss()
    }

    private func createAndAdd(named name: String) {
        let ex = Exercise(name: name, muscles: [], equipment: .barbell, isInLibrary: true)
        context.insert(ex)
        appendToTemplate(ex)
        // Open edit sheet so the user can fill in muscles / weight / etc.
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            newlyCreated = ex
        }
    }

    private func appendToTemplate(_ ex: Exercise) {
        let nextOrder = (template.templateExercises ?? []).map(\.order).max().map { $0 + 1 } ?? 0
        let te = TemplateExercise(template: template, exercise: ex, order: nextOrder)
        context.insert(te)
        try? context.save()
    }
}
