import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query private var settingsList: [AppSettings]
    @State private var search: String = ""
    @State private var activeFilter: MuscleGroup? = nil
    @State private var editing: Exercise?

    private var settings: AppSettings? { settingsList.first }

    private var filteredGroups: [(MuscleGroup, [Exercise])] {
        let filtered = exercises.filter { ex in
            let matchesSearch = search.isEmpty || ex.name.localizedCaseInsensitiveContains(search)
            let matchesFilter = activeFilter == nil || ex.muscleGroups.contains(activeFilter!)
            return matchesSearch && matchesFilter
        }
        // Group by primary muscle, preserve order
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
                filterChips
                    .padding(.vertical, 12)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(filteredGroups, id: \.0) { group, items in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.display.uppercased())
                                    .gtMonoCaption(size: 10, tracking: 1.5)
                                    .padding(.horizontal, 4)
                                VStack(spacing: 0) {
                                    ForEach(Array(items.enumerated()), id: \.element.id) { i, ex in
                                        Button { editing = ex } label: {
                                            exerciseRow(ex, isLast: i == items.count - 1)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .gtCard(radius: GT.rMd)
                            }
                        }
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .sheet(item: $editing) { ex in
            ExerciseEditView(exercise: ex)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(exercises.count) EXERCISES")
                        .gtMonoCaption(size: 11, tracking: 1.4)
                    Text("Library")
                        .font(.gtDisplay(34, weight: .semibold))
                        .tracking(-1)
                        .foregroundColor(GT.ink)
                }
                Spacer()
                Button {
                    addNew()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(GT.lime))
                        .foregroundColor(GT.limeInk)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(GT.ink3)
                TextField("", text: $search, prompt: Text("Search exercises").foregroundColor(GT.ink3))
                    .font(.gtBody(14))
                    .foregroundColor(GT.ink)
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .gtCard(radius: GT.rMd)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
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

    private func exerciseRow(_ ex: Exercise, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(ex.name)
                    .font(.gtBody(14))
                    .foregroundColor(ex.isInLibrary ? GT.ink : GT.ink3)
                Spacer()
                Text("1RM \(Int(GTMath.epley1RM(weight: ex.topWorkingWeight, reps: ex.effectiveReps(for: .load, loadingIndex: 0, settings: settings))))")
                    .font(.gtMono(11))
                    .foregroundColor(GT.ink3)
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ex.isInLibrary ? GT.lime : Color.clear)
                    if !ex.isInLibrary {
                        RoundedRectangle(cornerRadius: 6).stroke(GT.line2, lineWidth: 1.5)
                    }
                    if ex.isInLibrary {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(GT.limeInk)
                    }
                }
                .frame(width: 22, height: 22)
                .onTapGesture {
                    ex.isInLibrary.toggle()
                    try? context.save()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            if !isLast {
                Rectangle().fill(GT.line).frame(height: 1)
            }
        }
    }

    private func addNew() {
        let ex = Exercise(name: "", muscles: [], equipment: .barbell, isInLibrary: true)
        context.insert(ex)
        try? context.save()
        editing = ex
    }
}
