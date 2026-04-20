import SwiftUI
import SwiftData

struct ExerciseEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [AppSettings]
    @Query(sort: \WorkoutTemplate.order) private var templates: [WorkoutTemplate]
    @Bindable var exercise: Exercise

    private var settings: AppSettings { settingsList.first ?? AppSettings() }

    // MARK: - Derived

    private var computedSets: [SetPreview] {
        let top = exercise.topWorkingWeight
        var out: [SetPreview] = [
            SetPreview(
                kind: "COLD WARMUP",
                weight: exercise.effectiveWeight(for: .cold, settings: settings),
                reps: exercise.effectiveReps(for: .cold, settings: settings),
                rest: settings.restCold == 0 ? "—" : GTMath.mmss(settings.restCold),
                pct: Int(settings.coldPct * 100),
                primary: false
            ),
            SetPreview(
                kind: "CONTINUING WARMUP",
                weight: exercise.effectiveWeight(for: .warm, settings: settings),
                reps: exercise.effectiveReps(for: .warm, settings: settings),
                rest: GTMath.mmss(settings.restWarm),
                pct: Int(settings.warmPct * 100),
                primary: false
            ),
        ]
        for i in 0..<max(1, exercise.numLoadingSets) {
            out.append(SetPreview(
                kind: "LOADING SET \(i + 1)",
                weight: top,
                reps: exercise.effectiveReps(for: .load, loadingIndex: i, settings: settings),
                rest: GTMath.mmss(settings.plannedRest(for: .load, loadingIndex: i)),
                pct: 100,
                primary: true
            ))
        }
        return out
    }

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Top bar
                    HStack {
                        iconCircle("xmark") { dismiss() }
                        Spacer()
                        Text("EXERCISE")
                            .gtMonoCaption(size: 11, tracking: 1.4)
                        Spacer()
                        Button { dismiss() } label: {
                            Text("Save")
                                .font(.gtDisplay(14, weight: .semibold))
                                .foregroundColor(GT.lime)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 18)

                    // Name — editable
                    TextField("", text: $exercise.name, prompt:
                        Text("Exercise name").foregroundColor(GT.ink3)
                    )
                    .font(.gtDisplay(28, weight: .semibold))
                    .tracking(-0.8)
                    .foregroundColor(GT.ink)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit { try? context.save() }

                    HStack(spacing: 14) {
                        Text(exercise.equipment.display.uppercased())
                        if !exercise.muscleGroups.isEmpty {
                            Text("·")
                            Text(exercise.muscleGroups.map(\.display).joined(separator: " · ").uppercased())
                        }
                    }
                    .font(.gtMono(11))
                    .foregroundColor(GT.ink3)
                    .padding(.top, 10)

                    // Muscles
                    Text("MUSCLE GROUPS")
                        .gtMonoCaption(size: 11, tracking: 1.5)
                        .padding(.top, 22)
                        .padding(.bottom, 10)
                    muscleChips

                    // Equipment
                    Text("EQUIPMENT")
                        .gtMonoCaption(size: 11, tracking: 1.5)
                        .padding(.top, 18)
                        .padding(.bottom, 10)
                    equipmentChips

                    // Templates
                    Text("IN WORKOUTS")
                        .gtMonoCaption(size: 11, tracking: 1.5)
                        .padding(.top, 18)
                        .padding(.bottom, 10)
                    templateChips

                    // Top working weight card
                    weightCard
                        .padding(.top, 22)

                    // Warmup weight overrides
                    Text("WARMUP WEIGHTS")
                        .gtMonoCaption(size: 11, tracking: 1.5)
                        .padding(.top, 22)
                        .padding(.bottom, 10)
                    warmupWeightCard

                    // Reps per set
                    Text("REPS PER SET")
                        .gtMonoCaption(size: 11, tracking: 1.5)
                        .padding(.top, 22)
                        .padding(.bottom, 10)
                    repsCard

                    // Sets preview
                    Text("SETS · AUTO-CALCULATED")
                        .gtMonoCaption(size: 11, tracking: 1.5)
                        .padding(.top, 22)
                        .padding(.bottom, 10)
                    VStack(spacing: 8) {
                        ForEach(computedSets) { s in
                            SetEditRow(set: s)
                        }
                    }

                    // Notes
                    Text("NOTES")
                        .gtMonoCaption(size: 11, tracking: 1.5)
                        .padding(.top, 22)
                        .padding(.bottom, 10)
                    TextEditor(text: $exercise.notes)
                        .font(.gtBody(13))
                        .foregroundColor(GT.ink2)
                        .scrollContentBackground(.hidden)
                        .padding(14)
                        .frame(minHeight: 90, alignment: .topLeading)
                        .gtCard(radius: GT.rMd)
                        .italic()

                    // Danger zone
                    Button { deleteExercise() } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete exercise")
                        }
                        .font(.gtBody(14))
                        .foregroundColor(GT.warn)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: GT.rMd)
                                .stroke(GT.warn.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
    }

    // MARK: - Chip blocks

    private var muscleChips: some View {
        FlowLayout(spacing: 6) {
            ForEach(MuscleGroup.allCases) { m in
                let on = exercise.muscleGroups.contains(m)
                ChipButton(label: m.display, on: on, accent: .lime) {
                    toggleMuscle(m)
                }
            }
        }
    }

    private var equipmentChips: some View {
        FlowLayout(spacing: 6) {
            ForEach(Equipment.allCases, id: \.rawValue) { e in
                let on = exercise.equipment == e
                ChipButton(label: e.display.uppercased(), on: on, accent: .lime) {
                    exercise.equipment = e
                    try? context.save()
                }
            }
        }
    }

    private var templateChips: some View {
        FlowLayout(spacing: 6) {
            ForEach(templates) { t in
                let on = isInTemplate(t)
                ChipButton(label: t.name.uppercased(), on: on, accent: .lime) {
                    toggleTemplate(t)
                }
            }
        }
    }

    // MARK: - Weight card

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOP WORKING WEIGHT")
                        .gtMonoCaption(size: 10, tracking: 1.3)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(GTMath.formatWeight(exercise.topWorkingWeight))
                            .font(.gtDisplay(32, weight: .semibold))
                            .tracking(-1)
                            .foregroundColor(GT.ink)
                        Text(settings.units.rawValue)
                            .font(.gtMono(13))
                            .foregroundColor(GT.ink3)
                    }
                }
                Spacer()
                GTStepper(
                    value: GTMath.formatWeight(exercise.topWorkingWeight),
                    unit: settings.units.rawValue,
                    onMinus: { bumpWeight(-settings.weightStep) },
                    onPlus:  { bumpWeight(settings.weightStep) }
                )
            }

            HStack {
                Text("Est. 1RM")
                    .font(.gtBody(12))
                    .foregroundColor(GT.ink2)
                Spacer()
                Text("\(Int(GTMath.epley1RM(weight: exercise.topWorkingWeight, reps: exercise.effectiveReps(for: .load, loadingIndex: 0, settings: settings)))) \(settings.units.rawValue)")
                    .font(.gtMono(13))
                    .foregroundColor(GT.ink)
                Rectangle().fill(GT.line).frame(width: 1, height: 14).padding(.horizontal, 10)
                Text("Loading sets")
                    .font(.gtBody(12))
                    .foregroundColor(GT.ink2)
                Spacer()
                Text("\(exercise.numLoadingSets)")
                    .font(.gtMono(13))
                    .foregroundColor(GT.ink)
                HStack(spacing: 0) {
                    stepButton("−") {
                        exercise.numLoadingSets = max(1, exercise.numLoadingSets - 1); try? context.save()
                    }
                    stepButton("+") {
                        exercise.numLoadingSets = min(5, exercise.numLoadingSets + 1); try? context.save()
                    }
                }
                .padding(.leading, 8)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: GT.rMd).fill(GT.surface2))
        }
        .padding(16)
        .gtCard(radius: GT.rLg)
    }

    // MARK: - Warmup weight card

    private var warmupWeightCard: some View {
        VStack(spacing: 0) {
            warmupWeightRow(
                label: "Cold warmup",
                override: exercise.weightColdOverride,
                computed: GTMath.warmupWeight(top: exercise.topWorkingWeight, pct: settings.coldPct, step: settings.weightStep),
                pct: Int(settings.coldPct * 100)
            ) {
                bumpWeightOverride(\.weightColdOverride, by: $0)
            }
            Rectangle().fill(GT.line).frame(height: 1)
            warmupWeightRow(
                label: "Continuing warmup",
                override: exercise.weightWarmOverride,
                computed: GTMath.warmupWeight(top: exercise.topWorkingWeight, pct: settings.warmPct, step: settings.weightStep),
                pct: Int(settings.warmPct * 100),
                isLast: true
            ) {
                bumpWeightOverride(\.weightWarmOverride, by: $0)
            }
        }
        .gtCard(radius: GT.rLg)
    }

    @ViewBuilder
    private func warmupWeightRow(label: String, override: Double, computed: Double, pct: Int, isLast: Bool = false, onBump: @escaping (Double) -> Void) -> some View {
        let effective = override > 0 ? override : computed
        HStack {
            Text(label).font(.gtBody(14)).foregroundColor(GT.ink)
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(GTMath.formatWeight(effective))")
                        .font(.gtMono(13, weight: .medium))
                        .foregroundColor(override > 0 ? GT.lime : GT.ink)
                    Text(settings.units.rawValue)
                        .font(.gtMono(11))
                        .foregroundColor(GT.ink3)
                }
                Text(override > 0 ? "override" : "\(pct)% default")
                    .font(.gtMono(9))
                    .tracking(0.8)
                    .foregroundColor(override > 0 ? GT.lime : GT.ink3)
            }
            HStack(spacing: 0) {
                stepButton("−") { onBump(-settings.weightStep) }
                stepButton("+") { onBump(settings.weightStep) }
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .opacity(isLast ? 1 : 1)
    }

    private func bumpWeightOverride(_ kp: ReferenceWritableKeyPath<Exercise, Double>, by delta: Double) {
        let current = exercise[keyPath: kp]
        // When there's no override, first tap starts from the computed value.
        let computed: Double
        switch kp {
        case \Exercise.weightColdOverride:
            computed = GTMath.warmupWeight(top: exercise.topWorkingWeight, pct: settings.coldPct, step: settings.weightStep)
        case \Exercise.weightWarmOverride:
            computed = GTMath.warmupWeight(top: exercise.topWorkingWeight, pct: settings.warmPct, step: settings.weightStep)
        default:
            computed = 0
        }
        let base = current > 0 ? current : computed
        let next = base + delta
        // If bumped back to the computed value, clear the override.
        if abs(next - computed) < 0.01 {
            exercise[keyPath: kp] = 0
        } else {
            exercise[keyPath: kp] = max(0, next)
        }
        try? context.save()
    }

    // MARK: - Reps card

    private var repsCard: some View {
        VStack(spacing: 0) {
            repRow(kind: "Cold warmup", value: exercise.repsColdOverride, fallback: settings.repsCold) {
                bumpOverride(\.repsColdOverride, by: $0)
            }
            Rectangle().fill(GT.line).frame(height: 1)
            repRow(kind: "Continuing warmup", value: exercise.repsWarmOverride, fallback: settings.repsWarm) {
                bumpOverride(\.repsWarmOverride, by: $0)
            }
            Rectangle().fill(GT.line).frame(height: 1)
            repRow(kind: "Loading set 1", value: exercise.repsLoad1Override, fallback: settings.repsLoad1) {
                bumpOverride(\.repsLoad1Override, by: $0)
            }
            if exercise.numLoadingSets > 1 {
                Rectangle().fill(GT.line).frame(height: 1)
                repRow(kind: "Loading set 2", value: exercise.repsLoad2Override, fallback: settings.repsLoad2, isLast: true) {
                    bumpOverride(\.repsLoad2Override, by: $0)
                }
            }
        }
        .gtCard(radius: GT.rLg)
    }

    @ViewBuilder
    private func repRow(kind: String, value: Int, fallback: Int, isLast: Bool = false, onBump: @escaping (Int) -> Void) -> some View {
        let effective = value > 0 ? value : fallback
        HStack {
            Text(kind).font(.gtBody(14)).foregroundColor(GT.ink)
            Spacer()
            Text(value > 0 ? "\(effective) reps" : "\(effective) reps · default")
                .font(.gtMono(12))
                .foregroundColor(value > 0 ? GT.lime : GT.ink3)
                .frame(minWidth: 110, alignment: .trailing)
            HStack(spacing: 0) {
                stepButton("−") { onBump(-1) }
                stepButton("+") { onBump(+1) }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Mutators

    private func iconCircle(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 36, height: 36)
                .background(Circle().fill(GT.surface2))
                .overlay(Circle().stroke(GT.line, lineWidth: 1))
                .foregroundColor(GT.ink)
        }
        .buttonStyle(.plain)
    }

    private func stepButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.gtMono(13, weight: .medium))
                .frame(width: 26, height: 26)
                .background(Circle().fill(GT.surface))
                .overlay(Circle().stroke(GT.line, lineWidth: 1))
                .foregroundColor(GT.ink)
        }
        .buttonStyle(.plain)
    }

    private func bumpWeight(_ delta: Double) {
        exercise.topWorkingWeight = max(0, exercise.topWorkingWeight + delta)
        try? context.save()
    }

    private func bumpOverride(_ kp: ReferenceWritableKeyPath<Exercise, Int>, by delta: Int) {
        let current = exercise[keyPath: kp]
        let fallback: Int
        switch kp {
        case \Exercise.repsColdOverride: fallback = settings.repsCold
        case \Exercise.repsWarmOverride: fallback = settings.repsWarm
        case \Exercise.repsLoad1Override: fallback = settings.repsLoad1
        case \Exercise.repsLoad2Override: fallback = settings.repsLoad2
        default: fallback = 5
        }
        // If unset, first tap starts from the fallback value.
        let base = current > 0 ? current : fallback
        let next = base + delta
        // Tapping − back to fallback un-overrides; clamp at 1.
        if next == fallback {
            exercise[keyPath: kp] = 0
        } else {
            exercise[keyPath: kp] = max(1, min(30, next))
        }
        try? context.save()
    }

    private func toggleMuscle(_ m: MuscleGroup) {
        var current = exercise.muscleGroups
        if let idx = current.firstIndex(of: m) {
            current.remove(at: idx)
        } else {
            current.append(m)
        }
        exercise.muscleGroups = current
        try? context.save()
    }

    private func isInTemplate(_ t: WorkoutTemplate) -> Bool {
        t.orderedExercises.contains { $0.exercise?.id == exercise.id }
    }

    private func toggleTemplate(_ t: WorkoutTemplate) {
        let entries = (t.templateExercises ?? []).filter { $0.exercise?.id == exercise.id }
        if !entries.isEmpty {
            for e in entries { context.delete(e) }
        } else {
            let nextOrder = (t.templateExercises ?? []).map(\.order).max().map { $0 + 1 } ?? 0
            let te = TemplateExercise(template: t, exercise: exercise, order: nextOrder)
            context.insert(te)
        }
        try? context.save()
    }

    private func deleteExercise() {
        context.delete(exercise)
        try? context.save()
        dismiss()
    }
}

// MARK: - Chip button

struct ChipButton: View {
    enum Accent { case lime, ink }
    let label: String
    let on: Bool
    var accent: Accent = .lime
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.gtMono(10, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(on ? GT.limeInk : GT.ink2)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Capsule().fill(on ? GT.lime : GT.surface))
                .overlay(Capsule().stroke(on ? .clear : GT.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout (simple wrapping HStack)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? .infinity
        var rows: [CGFloat] = [0]
        var rowHeights: [CGFloat] = [0]
        var x: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                rows.append(0)
                rowHeights.append(0)
                x = 0
            }
            x += size.width + spacing
            rows[rows.count - 1] = max(rows[rows.count - 1], x)
            rowHeights[rowHeights.count - 1] = max(rowHeights[rowHeights.count - 1], size.height)
        }
        let totalHeight = rowHeights.reduce(0, +) + CGFloat(max(0, rowHeights.count - 1)) * spacing
        let totalWidth = rows.map { min($0, width) }.max() ?? 0
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let width = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            _ = width
        }
    }
}

// MARK: - Preview models

private struct SetPreview: Identifiable {
    var id: String { kind }
    let kind: String
    let weight: Double
    let reps: Int
    let rest: String
    let pct: Int
    let primary: Bool
}

private struct SetEditRow: View {
    let set: SetPreview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(set.kind)
                    .font(.gtMono(10, weight: .medium))
                    .tracking(1.4)
                    .foregroundColor(set.primary ? GT.lime : GT.ink3)
                Spacer()
                Text("REST \(set.rest)")
                    .font(.gtMono(10))
                    .foregroundColor(GT.ink3)
            }
            HStack(spacing: 10) {
                MiniField(label: "WEIGHT", value: "\(GTMath.formatWeight(set.weight))", unit: "lb", big: true)
                Text("×")
                    .font(.gtDisplay(22, weight: .regular))
                    .foregroundColor(GT.ink4)
                MiniField(label: "REPS", value: "\(set.reps)")
                Spacer()
                Text("\(set.pct)%")
                    .font(.gtMono(11))
                    .foregroundColor(GT.ink3)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 8).fill(GT.surface2))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GT.line, lineWidth: 1))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: GT.rMd).fill(set.primary ? GT.limeWashSoft : GT.surface))
        .overlay(RoundedRectangle(cornerRadius: GT.rMd).stroke(set.primary ? GT.limeEdge : GT.line, lineWidth: 1))
    }
}

private struct MiniField: View {
    let label: String
    let value: String
    var unit: String? = nil
    var big: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.gtMono(9, weight: .medium))
                .tracking(1.2)
                .foregroundColor(GT.ink3)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.gtMono(18, weight: .medium))
                    .foregroundColor(GT.ink)
                if let unit = unit {
                    Text(unit)
                        .font(.gtMono(10))
                        .foregroundColor(GT.ink3)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: big ? 110 : 80, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: GT.rSm).fill(GT.surface2))
        .overlay(RoundedRectangle(cornerRadius: GT.rSm).stroke(GT.line, lineWidth: 1))
    }
}
