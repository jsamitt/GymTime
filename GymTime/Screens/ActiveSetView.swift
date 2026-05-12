import SwiftUI
import SwiftData
import UIKit

struct ActiveSetView: View {
    @ObservedObject var controller: SessionController
    @StateObject private var timer = RestTimerModel()
    let session: Session
    let settings: AppSettings
    /// True only when the user just tapped START WORKOUT — drives a one-
    /// shot "Weights re-based" toast that auto-fades. Resume-banner path
    /// passes false.
    var freshStart: Bool = false
    let onClose: () -> Void

    @State private var editingField: NumericEditField?
    @State private var showExitConfirm = false
    @State private var showSwapPicker = false
    @State private var showWorkoutOverview = false
    @State private var showAddExercisePicker = false
    @State private var showSummary = false
    @State private var showRebaseToast = false
    /// Set when the in-process timer fires; pushed into LA so the widget
    /// can render its flash window. Cleared on next set/cursor change.
    @State private var lastRestEndedAt: Date?

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
        ZStack(alignment: .top) {
            GT.bg.ignoresSafeArea()

            if let set = currentSet, let log = cursor?.0 {
                content(set: set, log: log)
            } else {
                finishedOverlay
            }

            if showRebaseToast {
                rebaseToast
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .onAppear {
            if let (log, _) = cursor { controller.buildSets(for: log) }
            if settings.keepAwake {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            pushLiveActivityState(starting: true)
            if freshStart {
                withAnimation(.easeOut(duration: 0.25)) { showRebaseToast = true }
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    withAnimation(.easeIn(duration: 0.4)) { showRebaseToast = false }
                }
            }
        }
        .onDisappear {
            timer.stop()
            UIApplication.shared.isIdleTimerDisabled = false
            LiveActivityController.shared.end()
        }
        // Reactive Live-Activity refresh. Drives a single push site whenever
        // any LA-relevant state changes — guarantees the widget never shows
        // stale data regardless of which gesture triggered the underlying
        // mutation. Replaces the previous scattered imperative push calls.
        // Exercise-boundary observer. Fires whenever the cursor's LOG
        // changes (independent of the set), so a swap/append/skip that
        // jumps to a different ExerciseLog forces a build + push even if
        // the new log's sets haven't surfaced via the .id observer yet.
        .onChange(of: cursor?.0.id) { _, _ in
            if let (log, _) = cursor, (log.sets ?? []).isEmpty {
                controller.buildSets(for: log)
            }
            lastRestEndedAt = nil
            pushLiveActivityState()
        }
        .onChange(of: currentSet?.id) { _, _ in
            // New set/exercise — clear any stale flash state from prior rest.
            lastRestEndedAt = nil
            pushLiveActivityState()
        }
        .onChange(of: currentSet?.weight) { _, _ in pushLiveActivityState() }
        .onChange(of: currentSet?.reps) { _, _ in pushLiveActivityState() }
        .onChange(of: timer.plannedSec) { _, _ in pushLiveActivityState() }
        .onChange(of: timer.isRunning) { _, _ in pushLiveActivityState() }
        .onChange(of: timer.didFire) { _, fired in
            if fired {
                lastRestEndedAt = Date()
                pushLiveActivityState()
            }
        }
        .sheet(item: $editingField) { field in
            NumericEditSheet(field: field, unit: settings.units.rawValue) {
                controller.save()
            }
            .presentationDetents([.fraction(0.35), .medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSwapPicker) {
            if let (currentLog, _) = cursor, let currentEx = currentLog.exercise {
                let sessionIds = Set(session.orderedLogs.compactMap { $0.exercise?.id })
                ExerciseSwapPicker(
                    currentExercise: currentEx,
                    excludedIds: sessionIds
                ) { newExercise in
                    controller.swapCurrentExercise(to: newExercise)
                    // Belt + suspenders alongside .onChange: synchronously
                    // push the new state so the LA flips immediately, even
                    // if the @Observation pass hasn't fired yet.
                    pushLiveActivityState()
                }
            }
        }
        .sheet(isPresented: $showWorkoutOverview) {
            WorkoutOverviewSheet(
                session: session,
                currentSetID: currentSet?.id
            )
        }
        .sheet(isPresented: $showAddExercisePicker) {
            SessionExercisePickerSheet(session: session) { picked in
                controller.appendExerciseToSession(picked)
                // Explicit push so the LA reflects the appended exercise
                // immediately (including the extend-from-finishedOverlay
                // path, where the view also needs to flip from completion
                // back to the active set).
                pushLiveActivityState()
            }
        }
        .confirmationDialog("Exit workout?", isPresented: $showExitConfirm, titleVisibility: .visible) {
            Button("Save & Exit") {
                controller.save()
                onClose()
            }
            Button("Exit Without Saving", role: .destructive) {
                controller.abandon()
                onClose()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Save progress to resume later, or discard this workout entirely.")
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
            HStack(spacing: 6) {
                iconCircle("chevron.down") { showExitConfirm = true }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(session.templateName.uppercased()) · \(setPosition)")
                        .gtMonoCaption(size: 10, tracking: 1.4)
                    Text(log.exerciseName)
                        .font(.gtDisplay(15, weight: .semibold))
                        .foregroundColor(GT.ink)
                    if let next = nextExerciseName(after: log) {
                        Text("NEXT · \(next.uppercased())")
                            .font(.gtMono(9, weight: .medium))
                            .tracking(1.0)
                            .foregroundColor(GT.ink3)
                            .lineLimit(1)
                            .padding(.top, 1)
                    }
                }
                Spacer()
                // VIEW — see the entire workout in a sheet without exiting.
                Button { showWorkoutOverview = true } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(GT.surface2))
                        .overlay(Circle().stroke(GT.line, lineWidth: 1))
                        .foregroundColor(GT.ink2)
                }
                .buttonStyle(.plain)
                Menu {
                    Button {
                        showSwapPicker = true
                    } label: {
                        Label("Swap exercise", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Button {
                        showAddExercisePicker = true
                    } label: {
                        Label("Add exercise to workout", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(GT.surface2))
                        .overlay(Circle().stroke(GT.line, lineWidth: 1))
                        .foregroundColor(GT.ink2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // Label row — Unskip pill (when something's deferred) sits to
            // the left of the set-kind pill. Tapping Unskip un-defers the
            // earliest queued exercise so the cursor returns to it; the
            // current in-progress exercise stays partial and the cursor
            // will come back to it after the un-deferred one finishes.
            HStack(spacing: 8) {
                if controller.hasDeferredExercises {
                    Button {
                        controller.undeferNext()
                        pushLiveActivityState()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 10, weight: .semibold))
                            Text("UNSKIP")
                                .font(.gtMono(11, weight: .semibold))
                                .tracking(0.6)
                        }
                        .foregroundColor(GT.limeInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(GT.lime))
                    }
                    .buttonStyle(.plain)
                }
                Pill(accent: true) {
                    Image(systemName: "scope")
                        .font(.system(size: 11))
                        .foregroundColor(GT.lime)
                    Text(setLabel(set: set, in: sets))
                        .font(.gtMono(11, weight: .medium))
                        .tracking(0.3)
                }
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

            // Bottom bar: three equal-width capsule buttons.
            // Skip Ex (defer the entire exercise), Skip Set (skip current
            // set only), Log Set (primary lime action).
            HStack(spacing: 8) {
                bottomBarButton(
                    title: "Skip Ex",
                    icon: "arrow.uturn.forward",
                    isPrimary: false,
                    accessibility: "Skip exercise (come back later)"
                ) {
                    controller.deferCurrentExercise()
                    pushLiveActivityState()
                }

                bottomBarButton(
                    title: "Skip Set",
                    icon: "forward.end.fill",
                    isPrimary: false
                ) {
                    logButtonTapped(nil, skip: true, currentSet: set)
                }

                bottomBarButton(
                    title: "Log Set",
                    icon: "checkmark",
                    isPrimary: true
                ) {
                    logButtonTapped(set, skip: false, currentSet: set)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
    }

    /// Equal-width bottom-bar button. `isPrimary` switches between the
    /// lime "log set" fill and the surface "secondary action" style.
    @ViewBuilder
    private func bottomBarButton(
        title: String,
        icon: String,
        isPrimary: Bool,
        accessibility: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: isPrimary ? .bold : .semibold))
                Text(title)
                    .font(.gtDisplay(15, weight: isPrimary ? .bold : .semibold))
                    .tracking(isPrimary ? -0.2 : 0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isPrimary ? GT.limeInk : GT.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Capsule().fill(isPrimary ? GT.lime : GT.surface))
            .overlay(
                Capsule().stroke(isPrimary ? Color.clear : GT.line2, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility ?? title)
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

    /// One-shot banner shown on a fresh workout start. Mentions that the
    /// app re-based weights using the most recent top working weight; the
    /// recalculation itself happened silently in `buildSets`.
    private var rebaseToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "scalemass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(GT.limeInk)
            Text("Weights re-based on your last top working weight")
                .font(.gtMono(11, weight: .medium))
                .tracking(0.4)
                .foregroundColor(GT.limeInk)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(GT.lime.opacity(0.95)))
        .padding(.horizontal, 18)
    }

    private func bumpWeight(_ set: SetLog, by delta: Double) {
        set.weight = max(0, set.weight + delta)
        set.log?.enforceLoadingProgression()
        controller.save()
        // .onChange(of: currentSet?.weight) handles the LA push.
    }

    private func bumpReps(_ set: SetLog, by delta: Int) {
        set.reps = max(1, min(50, set.reps + delta))
        controller.save()
        // .onChange(of: currentSet?.reps) handles the LA push.
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

            // Extend the workout with another exercise. Picking one
            // re-activates the cursor since the new log has unlogged sets.
            Button {
                showAddExercisePicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("ADD EXERCISE")
                }
                .font(.gtDisplay(14, weight: .bold))
                .tracking(0.4)
                .foregroundColor(GT.ink)
                .frame(width: 220, height: 46)
                .background(Capsule().fill(GT.surface))
                .overlay(Capsule().stroke(GT.line2, lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Visual summary — same view History uses for past sessions,
            // re-presented here so the user can review the lift breakdown
            // before tapping DONE. Session is unfinished at this point but
            // SessionDetailView reads orderedLogs/orderedSets directly so
            // it works fine.
            Button {
                showSummary = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                    Text("VIEW SUMMARY")
                }
                .font(.gtDisplay(14, weight: .bold))
                .tracking(0.4)
                .foregroundColor(GT.ink)
                .frame(width: 220, height: 46)
                .background(Capsule().fill(GT.surface))
                .overlay(Capsule().stroke(GT.line2, lineWidth: 1))
            }
            .buttonStyle(.plain)

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
        .sheet(isPresented: $showSummary) {
            SessionDetailView(session: session)
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

    /// Compact uppercased label for the current set (e.g. "WARMUP 1",
    /// "LOAD 2", "SET 1"). Uses the kind-aware variant so the "skipped
    /// Warmup 1" case (1W + 3L instead of 2W + 2L) renders correctly.
    private func setLabel(set: SetLog, in sets: [SetLog]) -> String {
        return SetLabeler.compactLabel(forSet: set, in: sets)
    }

    /// First exercise log after `currentLog` that still has unlogged sets.
    /// Returns nil if there's no next exercise (we're on the last one) so
    /// the caller can hide the hint.
    private func nextExerciseName(after currentLog: ExerciseLog) -> String? {
        let logs = session.orderedLogs
        guard let i = logs.firstIndex(where: { $0.id == currentLog.id }) else { return nil }
        for j in (i + 1)..<logs.count {
            let log = logs[j]
            // If the log has built sets, only show it as "next" if it still
            // has work remaining. If sets aren't built yet, it's clearly
            // upcoming.
            let sets = log.orderedSets
            if sets.isEmpty || sets.contains(where: { $0.loggedAt == nil && !$0.skipped }) {
                return log.exerciseName
            }
        }
        return nil
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
        // The various .onChange modifiers in body push the LA state — no
        // explicit push needed here.
    }

    // MARK: - Live Activity bridge

    private func pushLiveActivityState(starting: Bool = false) {
        guard let (log, idx) = controller.activeCursor() else {
            LiveActivityController.shared.end()
            return
        }
        // Defensive: when the cursor just crossed onto a fresh log (swap
        // or append), its sets may not be built yet. Build synchronously
        // here so we never push (or end) with an empty sets array. If sets
        // STILL look empty after the build attempt — SwiftData relationship
        // hasn't surfaced this render — skip the push entirely rather than
        // ending the activity. The next reactive trigger will retry.
        if (log.sets ?? []).isEmpty {
            controller.buildSets(for: log)
        }
        let sets = log.orderedSets
        guard idx < sets.count else { return }
        let currentSet = sets[idx]
        let state = GymTimeActivityAttributes.ContentState(
            exerciseName: log.exerciseName,
            setLabel: SetLabeler.compactLabel(forSet: currentSet, in: sets),
            setPosition: "\(idx + 1) of \(sets.count)",
            weight: currentSet.weight,
            reps: currentSet.reps,
            restStartedAt: timer.isRunning ? timer.startDate : nil,
            restPlannedSec: timer.isRunning ? timer.plannedSec : 0,
            templateName: session.templateName,
            unit: settings.units.rawValue,
            restEndedAt: lastRestEndedAt
        )
        if starting {
            LiveActivityController.shared.start(state: state)
        } else {
            LiveActivityController.shared.update(state: state)
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
                s.log?.enforceLoadingProgression()
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
