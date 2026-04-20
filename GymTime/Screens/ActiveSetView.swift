import SwiftUI
import SwiftData
import UIKit

struct ActiveSetView: View {
    @ObservedObject var controller: SessionController
    @StateObject private var timer = RestTimerModel()
    let session: Session
    let settings: AppSettings
    let onClose: () -> Void

    @State private var editingField: NumericEditField?

    private var cursor: (ExerciseLog, Int)? {
        controller.activeCursor()
    }

    private var currentSet: SetLog? {
        guard let (log, idx) = cursor else { return nil }
        if (log.sets ?? []).isEmpty {
            controller.buildSets(for: log)
        }
        let sets = log.orderedSets
        guard idx < sets.count else { return nil }
        return sets[idx]
    }

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()

            if let set = currentSet, let log = cursor?.0 {
                content(set: set, log: log)
            } else {
                finishedOverlay
            }
        }
        .onAppear {
            if let (log, _) = cursor { controller.buildSets(for: log) }
            if settings.keepAwake {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        .onDisappear {
            timer.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .sheet(item: $editingField) { field in
            NumericEditSheet(field: field, unit: settings.units.rawValue) {
                controller.save()
            }
            .presentationDetents([.fraction(0.35), .medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Live screen

    @ViewBuilder
    private func content(set: SetLog, log: ExerciseLog) -> some View {
        let sets = log.orderedSets
        let setIndex = sets.firstIndex(where: { $0.id == set.id }) ?? 0
        let setPosition = "\(setIndex + 1) of \(sets.count)"

        VStack(spacing: 0) {
            // Header
            HStack {
                iconCircle("chevron.down") { onClose() }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(session.templateName.uppercased()) · \(setPosition)")
                        .gtMonoCaption(size: 10, tracking: 1.4)
                    Text(log.exerciseName)
                        .font(.gtDisplay(15, weight: .semibold))
                        .foregroundColor(GT.ink)
                }
                Spacer()
                iconCircle("ellipsis")
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // Label pill
            Pill(accent: true) {
                Image(systemName: "scope")
                    .font(.system(size: 11))
                    .foregroundColor(GT.lime)
                Text(setLabel(set: set, loadingIndex: loadingIndex(for: set, in: sets)))
                    .font(.gtMono(11, weight: .medium))
                    .tracking(0.3)
            }
            .padding(.top, 22)

            Spacer(minLength: 0)

            // HUGE weight × reps (tap number to type; ± chips bump)
            VStack(spacing: 4) {
                Button { editingField = .weight(set) } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(GTMath.formatWeight(set.weight))
                            .font(.gtDisplay(168, weight: .semibold))
                            .tracking(-7)
                            .foregroundColor(GT.ink)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text(settings.units.rawValue)
                            .font(.gtMono(22))
                            .foregroundColor(GT.ink3)
                            .padding(.leading, 6)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    editChip("−\(GTMath.formatWeight(settings.weightStep))") {
                        bumpWeight(set, by: -settings.weightStep)
                    }
                    editChip("+\(GTMath.formatWeight(settings.weightStep))") {
                        bumpWeight(set, by: settings.weightStep)
                    }
                }
                .padding(.top, 2)

                Button { editingField = .reps(set) } label: {
                    HStack(alignment: .center, spacing: 10) {
                        Text("×")
                            .font(.gtDisplay(40, weight: .regular))
                            .foregroundColor(GT.ink3)
                        Text("\(set.reps)")
                            .font(.gtDisplay(56, weight: .semibold))
                            .tracking(-1.5)
                            .foregroundColor(GT.lime)
                        Text("reps")
                            .font(.gtMono(15))
                            .foregroundColor(GT.ink3)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 12)

                HStack(spacing: 8) {
                    editChip("−1") { bumpReps(set, by: -1) }
                    editChip("+1") { bumpReps(set, by: 1) }
                }
                .padding(.top, 2)

                // Last session chip
                HStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 11))
                    Text("LAST · \(lastSummary(for: log))")
                        .font(.gtMono(11))
                    Spark(data: trend(for: log), width: 44, height: 14)
                }
                .foregroundColor(GT.ink2)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(GT.surface))
                .overlay(Capsule().stroke(GT.line, lineWidth: 1))
                .padding(.top, 18)
            }

            Spacer(minLength: 0)

            if timer.isRunning || timer.didFire {
                restBlock
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }

            // Bottom bar
            HStack(spacing: 10) {
                Button { logButtonTapped(nil, skip: true, currentSet: set) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.end.fill")
                        Text("SKIP")
                    }
                    .font(.gtDisplay(15, weight: .semibold))
                    .foregroundColor(GT.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(GT.surface))
                    .overlay(Capsule().stroke(GT.line2, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button { logButtonTapped(set, skip: false, currentSet: set) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark")
                        Text("LOG SET")
                    }
                    .font(.gtDisplay(16, weight: .bold))
                    .tracking(-0.2)
                    .foregroundColor(GT.limeInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(GT.lime))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
    }

    private var restBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("REST REMAINING")
                    .gtMonoCaption(size: 10, tracking: 1.4)
                Spacer()
                Text("OF \(GTMath.mmss(timer.plannedSec))")
                    .font(.gtMono(10))
                    .foregroundColor(GT.ink3)
            }
            HStack(alignment: .lastTextBaseline) {
                Text(GTMath.mmss(timer.remainingSec))
                    .font(.gtMono(44, weight: .medium))
                    .tracking(-1)
                    .foregroundColor(timer.didFire ? GT.lime : GT.rest)
                Spacer()
                HStack(spacing: 6) {
                    timerChip(label: "-30s") { timer.adjust(delta: -30) }
                    timerChip(label: "+30s") { timer.adjust(delta: 30) }
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(GT.surface2)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(timer.didFire ? GT.lime : GT.rest)
                        .frame(width: max(0, geo.size.width * timer.progress))
                }
            }
            .frame(height: 4)
        }
        .padding(18)
        .gtCard(radius: GT.rLg)
    }

    private func timerChip(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.gtMono(12))
                .foregroundColor(GT.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(GT.surface2))
                .overlay(Capsule().stroke(GT.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func editChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.gtMono(11, weight: .medium))
                .foregroundColor(GT.ink2)
                .frame(minWidth: 44)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(GT.surface2))
                .overlay(Capsule().stroke(GT.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func bumpWeight(_ set: SetLog, by delta: Double) {
        set.weight = max(0, set.weight + delta)
        controller.save()
    }

    private func bumpReps(_ set: SetLog, by delta: Int) {
        set.reps = max(1, min(50, set.reps + delta))
        controller.save()
    }

    private var finishedOverlay: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(GT.lime)
            Text("WORKOUT COMPLETE")
                .gtMonoCaption(color: GT.lime, size: 11, tracking: 1.6)
            Text("Volume: \(GTMath.formatVolume(session.totalVolume)) lb")
                .font(.gtDisplay(22, weight: .semibold))
                .foregroundColor(GT.ink)
            Button {
                controller.finish()
                onClose()
            } label: {
                Text("DONE")
                    .font(.gtDisplay(16, weight: .bold))
                    .tracking(-0.2)
                    .foregroundColor(GT.limeInk)
                    .frame(width: 200, height: 52)
                    .background(Capsule().fill(GT.lime))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func iconCircle(_ systemName: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15))
                .frame(width: 36, height: 36)
                .background(Circle().fill(GT.surface2))
                .overlay(Circle().stroke(GT.line, lineWidth: 1))
                .foregroundColor(GT.ink2)
        }
        .buttonStyle(.plain)
    }

    private func setLabel(set: SetLog, loadingIndex: Int?) -> String {
        switch set.kind {
        case .cold: return "COLD WARMUP"
        case .warm: return "CONTINUING WARMUP"
        case .load: return "LOADING SET \((loadingIndex ?? 0) + 1)"
        }
    }

    private func loadingIndex(for set: SetLog, in sets: [SetLog]) -> Int? {
        guard set.kind == .load else { return nil }
        let loads = sets.filter { $0.kind == .load }
        return loads.firstIndex(where: { $0.id == set.id })
    }

    private func lastSummary(for log: ExerciseLog) -> String {
        guard let ex = log.exercise, ex.topWorkingWeight > 0 else { return "—" }
        let reps = ex.effectiveReps(for: .load, loadingIndex: 0, settings: settings)
        return "\(GTMath.formatWeight(ex.topWorkingWeight)) × \(reps)"
    }

    private func trend(for log: ExerciseLog) -> [Double] {
        guard let ex = log.exercise else { return [] }
        let top = max(50, ex.topWorkingWeight)
        return [top * 0.85, top * 0.88, top * 0.92, top * 0.95, top * 0.98, top]
    }

    private func logButtonTapped(_ set: SetLog?, skip: Bool, currentSet: SetLog) {
        // Lazy-request notification permission on first Log/Skip tap.
        RestTimerModel.requestNotificationPermission()
        if skip {
            controller.skipSet(currentSet)
        } else if let s = set {
            controller.logSet(s)
        }
        // Build sets on the new log if we crossed an exercise boundary
        if let (newLog, _) = controller.activeCursor() {
            controller.buildSets(for: newLog)
        }
        // Start the rest timer for the NEXT set's planned rest
        if let (newLog, newIdx) = controller.activeCursor(),
           newIdx < newLog.orderedSets.count {
            let nextSet = newLog.orderedSets[newIdx]
            timer.start(planned: nextSet.plannedRestSec, hapticOnEnd: settings.hapticOnRestEnd)
        } else {
            timer.stop()
        }
    }
}

// MARK: - Numeric edit sheet

enum NumericEditField: Identifiable {
    case weight(SetLog)
    case reps(SetLog)

    var id: String {
        switch self {
        case .weight(let s): return "w-\(s.id.uuidString)"
        case .reps(let s):   return "r-\(s.id.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .weight: return "Weight"
        case .reps:   return "Reps"
        }
    }

    var currentText: String {
        switch self {
        case .weight(let s): return GTMath.formatWeight(s.weight)
        case .reps(let s):   return "\(s.reps)"
        }
    }

    var isDecimal: Bool {
        if case .weight = self { return true }
        return false
    }
}

struct NumericEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let field: NumericEditField
    let unit: String
    let onSave: () -> Void
    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(field.title.uppercased())
                        .gtMonoCaption(size: 11, tracking: 1.5)
                    Spacer()
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(.gtBody(14))
                            .foregroundColor(GT.ink3)
                    }
                    .buttonStyle(.plain)
                }

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    TextField("", text: $text)
                        .font(.gtDisplay(64, weight: .semibold))
                        .tracking(-2)
                        .foregroundColor(GT.ink)
                        .keyboardType(field.isDecimal ? .decimalPad : .numberPad)
                        .textFieldStyle(.plain)
                        .focused($focused)
                        .onSubmit(commit)
                    if case .weight = field {
                        Text(unit)
                            .font(.gtMono(20))
                            .foregroundColor(GT.ink3)
                    } else {
                        Text("reps")
                            .font(.gtMono(20))
                            .foregroundColor(GT.ink3)
                    }
                }
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(GT.line2).frame(height: 1)
                }

                Button(action: commit) {
                    Text("Save")
                        .font(.gtDisplay(16, weight: .bold))
                        .tracking(-0.2)
                        .foregroundColor(GT.limeInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(GT.lime))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
        }
        .onAppear {
            text = field.currentText
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focused = true
            }
        }
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        switch field {
        case .weight(let s):
            if let v = Double(trimmed), v >= 0 {
                s.weight = v
                onSave()
            }
        case .reps(let s):
            if let v = Int(trimmed), v > 0, v <= 999 {
                s.reps = v
                onSave()
            }
        }
        dismiss()
    }
}
