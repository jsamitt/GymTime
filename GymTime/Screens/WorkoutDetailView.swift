import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [AppSettings]

    let template: WorkoutTemplate
    let onClose: () -> Void

    @State private var activeSession: Session?
    @State private var editingExercise: Exercise?
    @State private var showAddExercise: Bool = false
    @State private var editMode: EditMode = .inactive

    private var settings: AppSettings {
        settingsList.first ?? AppSettings()
    }

    private var exercises: [Exercise] {
        template.orderedExercises.compactMap { $0.exercise }
    }

    private var estimatedMinutes: Int {
        max(25, exercises.count * 11)
    }
    private var totalSets: Int {
        exercises.reduce(0) { $0 + (1 + $1.numLoadingSets) + 1 }
    }

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    iconCircle("chevron.left") { onClose() }
                    Spacer()
                    Text("\(template.name.uppercased()) · DAY A")
                        .gtMonoCaption(size: 11, tracking: 1.4)
                    Spacer()
                    if editMode.isEditing {
                        Button {
                            editMode = .inactive
                        } label: {
                            Text("Done")
                                .font(.gtDisplay(14, weight: .semibold))
                                .foregroundColor(GT.lime)
                                .frame(height: 36)
                                .padding(.horizontal, 12)
                                .background(Capsule().fill(GT.surface2))
                                .overlay(Capsule().stroke(GT.line, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Menu {
                            Button {
                                showAddExercise = true
                            } label: {
                                Label("Add exercise", systemImage: "plus")
                            }
                            Button {
                                editMode = .active
                            } label: {
                                Label("Reorder exercises", systemImage: "arrow.up.arrow.down")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 15, weight: .medium))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(GT.surface2))
                                .overlay(Circle().stroke(GT.line, lineWidth: 1))
                                .foregroundColor(GT.ink)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)

                VStack(alignment: .leading, spacing: 6) {
                    Text(template.name)
                        .font(.gtDisplay(40, weight: .semibold))
                        .tracking(-1.4)
                        .foregroundColor(GT.ink)
                    Text(template.subtitle)
                        .font(.gtBody(14))
                        .foregroundColor(GT.ink2)
                    HStack(spacing: 16) {
                        Text("\(exercises.count) EXERCISES")
                        Text("~\(estimatedMinutes) MIN")
                        Text("\(totalSets) SETS")
                    }
                    .font(.gtMono(11))
                    .foregroundColor(GT.ink3)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Exercise list
                List {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { i, ex in
                        Button { if !editMode.isEditing { editingExercise = ex } } label: {
                            ExerciseRow(index: i + 1, exercise: ex, settings: settings)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14))
                        .contextMenu {
                            Button { editingExercise = ex } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button { editMode = .active } label: {
                                Label("Reorder exercises", systemImage: "arrow.up.arrow.down")
                            }
                            Button(role: .destructive) {
                                removeFromWorkout(ex)
                            } label: {
                                Label("Remove from \(template.name)", systemImage: "minus.circle")
                            }
                        }
                    }
                    .onMove(perform: moveExercise)
                    .onDelete(perform: deleteAtOffsets)

                    if !editMode.isEditing {
                        Button { showAddExercise = true } label: {
                            AddExerciseRow()
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14))
                    }

                    // Bottom spacer so the START WORKOUT button doesn't cover rows
                    Color.clear
                        .frame(height: 100)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, $editMode)
                .padding(.top, 8)
            }

            // Start bar
            VStack {
                Spacer()
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [GT.bg.opacity(0), GT.bg],
                        startPoint: .top, endPoint: .center
                    )
                    .frame(height: 120)
                    Button { startWorkout() } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                            Text("START WORKOUT")
                        }
                        .font(.gtDisplay(17, weight: .bold))
                        .tracking(-0.2)
                        .foregroundColor(GT.limeInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(GT.lime))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .fullScreenCover(item: $activeSession) { session in
            ActiveSessionContainer(session: session)
        }
        .sheet(item: $editingExercise) { ex in
            ExerciseEditView(exercise: ex)
        }
        .sheet(isPresented: $showAddExercise) {
            ExercisePickerView(template: template)
        }
    }

    private func iconCircle(_ systemName: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 36, height: 36)
                .background(Circle().fill(GT.surface2))
                .overlay(Circle().stroke(GT.line, lineWidth: 1))
                .foregroundColor(GT.ink)
        }
        .buttonStyle(.plain)
    }

    private func startWorkout() {
        let s = Session(templateName: template.name)
        context.insert(s)
        for (i, ex) in exercises.enumerated() {
            let log = ExerciseLog(session: s, exercise: ex, order: i)
            context.insert(log)
        }
        try? context.save()
        activeSession = s
    }

    private func removeFromWorkout(_ ex: Exercise) {
        let entries = (template.templateExercises ?? []).filter { $0.exercise?.id == ex.id }
        for e in entries { context.delete(e) }
        try? context.save()
    }

    private func moveExercise(from source: IndexSet, to destination: Int) {
        var ordered = template.orderedExercises
        ordered.move(fromOffsets: source, toOffset: destination)
        // Reassign contiguous order values so they persist.
        for (newOrder, te) in ordered.enumerated() {
            te.order = newOrder
        }
        try? context.save()
    }

    private func deleteAtOffsets(_ offsets: IndexSet) {
        let ordered = template.orderedExercises
        for i in offsets {
            context.delete(ordered[i])
        }
        try? context.save()
    }
}

struct ExerciseRow: View {
    let index: Int
    let exercise: Exercise
    let settings: AppSettings

    var body: some View {
        let load1Reps = exercise.effectiveReps(for: .load, loadingIndex: 0, settings: settings)
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(GT.surface2)
                Text("\(index)")
                    .font(.gtMono(12, weight: .semibold))
                    .foregroundColor(GT.ink2)
            }
            .frame(width: 28, height: 28)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(GT.line, lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name.isEmpty ? "—" : exercise.name)
                    .font(.gtDisplay(15, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundColor(GT.ink)
                HStack(spacing: 8) {
                    Text("\(GTMath.formatWeight(exercise.topWorkingWeight)) \(settings.units.rawValue) × \(load1Reps) · \(2 + exercise.numLoadingSets) sets")
                        .foregroundColor(GT.ink2)
                    Text("·").foregroundColor(GT.ink3)
                    Text("1RM \(Int(GTMath.epley1RM(weight: exercise.topWorkingWeight, reps: load1Reps)))")
                        .foregroundColor(GT.ink3)
                }
                .font(.gtMono(11))
            }

            Spacer()
            Spark(data: trend(for: exercise))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.rMd)
    }

    private func trend(for ex: Exercise) -> [Double] {
        let top = max(50, ex.topWorkingWeight)
        return [top * 0.85, top * 0.88, top * 0.92, top * 0.95, top * 0.98, top]
    }
}

struct AddExerciseRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.system(size: 16))
            Text("Add exercise")
                .font(.gtBody(14))
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: GT.rMd)
                .strokeBorder(GT.line2, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
        .foregroundColor(GT.ink3)
    }
}

/// Thin wrapper that builds the SessionController + provides dismiss.
struct ActiveSessionContainer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [AppSettings]
    let session: Session
    @State private var controller: SessionController?

    var body: some View {
        Group {
            if let settings = settingsList.first, let controller {
                ActiveSetView(controller: controller, session: session, settings: settings) {
                    dismiss()
                }
            } else {
                ProgressView().tint(GT.lime)
                    .onAppear { buildController() }
            }
        }
    }

    private func buildController() {
        guard controller == nil, let settings = settingsList.first else { return }
        controller = SessionController(session: session, context: context, settings: settings)
    }
}
