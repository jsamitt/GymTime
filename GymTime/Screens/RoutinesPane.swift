import SwiftUI
import SwiftData

/// Routines drawer contents — list of workout templates with:
/// - Tap row to open WorkoutDetailView (add/remove/reorder exercises, rename)
/// - Swipe row left to reveal Delete (with confirmation)
/// - Long-press / Menu on a row for Clone
/// - "+ New routine" button for scratch creation
///
/// Drag-to-reorder is exposed via an "Edit" toggle in the drawer header. The
/// `order` field on WorkoutTemplate drives both the drawer list order and the
/// Home tab's primary-vs-alternate split.
struct RoutinesPane: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutTemplate.order) private var templates: [WorkoutTemplate]

    @State private var editMode: EditMode = .inactive
    @State private var pendingDelete: WorkoutTemplate?
    @State private var showCreateSheet = false
    @State private var cloneSource: WorkoutTemplate?
    @State private var cloneName: String = ""
    @State private var openingTemplate: WorkoutTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Action bar
            HStack(spacing: 10) {
                Button { showCreateSheet = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("NEW ROUTINE")
                            .font(.gtMono(11, weight: .bold))
                            .tracking(0.8)
                    }
                    .foregroundColor(GT.limeInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(GT.lime))
                }
                .buttonStyle(.plain)

                Spacer()

                if templates.count > 1 {
                    Button {
                        withAnimation {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
                    } label: {
                        Text(editMode.isEditing ? "Done" : "Reorder")
                            .font(.gtMono(11, weight: .semibold))
                            .tracking(0.8)
                            .foregroundColor(editMode.isEditing ? GT.lime : GT.ink2)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(GT.surface))
                            .overlay(Capsule().stroke(GT.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 12)

            if editMode.isEditing {
                // Reorder mode uses a List so drag handles work natively.
                List {
                    ForEach(templates) { t in
                        reorderRow(t)
                            .listRowBackground(GT.bg)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                    .onMove(perform: moveTemplates)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, $editMode)
                .frame(minHeight: 200)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        if templates.isEmpty {
                            emptyState
                        } else {
                            ForEach(templates) { t in
                                SwipeToDeleteRow(
                                    onTap: { openingTemplate = t },
                                    onDelete: { pendingDelete = t }
                                ) {
                                    templateCard(t)
                                }
                                .contextMenu {
                                    Button {
                                        cloneName = "\(t.name) Copy"
                                        cloneSource = t
                                    } label: {
                                        Label("Clone as variant…", systemImage: "doc.on.doc")
                                    }
                                    Button(role: .destructive) {
                                        pendingDelete = t
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        Color.clear.frame(height: 40)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            RoutineCreateSheet()
        }
        .sheet(item: $openingTemplate) { t in
            WorkoutDetailView(template: t) { openingTemplate = nil }
        }
        .alert("Clone routine", isPresented: .constant(cloneSource != nil), presenting: cloneSource) { src in
            TextField("Name", text: $cloneName)
            Button("Clone") {
                performClone(source: src, name: cloneName)
                cloneSource = nil
            }
            Button("Cancel", role: .cancel) {
                cloneSource = nil
            }
        } message: { src in
            Text("Create a variant of \(src.name). You can modify its exercises afterward.")
        }
        .confirmationDialog(
            "Delete this routine?",
            isPresented: .constant(pendingDelete != nil),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { t in
            Button("Delete", role: .destructive) {
                deleteTemplate(t)
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { t in
            Text("\(t.name) · \(t.orderedExercises.count) exercises. Past sessions using this routine will stay in History. This can't be undone.")
        }
    }

    // MARK: - Row renderers

    private func templateCard(_ t: WorkoutTemplate) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(t.name)
                    .font(.gtDisplay(18, weight: .semibold))
                    .foregroundColor(GT.ink)
                    .lineLimit(1)
                if !t.subtitle.isEmpty {
                    Text(t.subtitle)
                        .font(.gtBody(12))
                        .foregroundColor(GT.ink2)
                        .lineLimit(1)
                }
                Text("\(t.orderedExercises.count) exercises")
                    .font(.gtMono(10))
                    .tracking(0.8)
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

    private func reorderRow(_ t: WorkoutTemplate) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(t.name)
                    .font(.gtDisplay(15, weight: .semibold))
                    .foregroundColor(GT.ink)
                Text("\(t.orderedExercises.count) ex")
                    .font(.gtMono(10))
                    .foregroundColor(GT.ink3)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.rMd)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 32))
                .foregroundColor(GT.ink3)
            Text("No routines yet")
                .font(.gtDisplay(14, weight: .semibold))
                .foregroundColor(GT.ink2)
            Text("Tap NEW ROUTINE to build your first one.")
                .font(.gtMono(10))
                .foregroundColor(GT.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Mutations

    private func moveTemplates(from source: IndexSet, to destination: Int) {
        var ordered = templates
        ordered.move(fromOffsets: source, toOffset: destination)
        for (idx, t) in ordered.enumerated() {
            t.order = idx
        }
        try? context.save()
    }

    private func performClone(source: WorkoutTemplate, name rawName: String) {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? "\(source.name) Copy" : trimmed
        let nextOrder = (templates.map(\.order).max() ?? -1) + 1

        let clone = WorkoutTemplate(name: finalName, subtitle: source.subtitle, order: nextOrder)
        context.insert(clone)

        // Re-create TemplateExercise links in the same order, referencing the
        // same Exercise records (they're shared library records, not copies).
        for (i, te) in source.orderedExercises.enumerated() {
            if let ex = te.exercise {
                let newLink = TemplateExercise(template: clone, exercise: ex, order: i)
                context.insert(newLink)
            }
        }
        try? context.save()
        // Open the new clone so the user can tweak it.
        openingTemplate = clone
    }

    private func deleteTemplate(_ t: WorkoutTemplate) {
        context.delete(t) // cascades to TemplateExercise rows
        try? context.save()
    }
}
