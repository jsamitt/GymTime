import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [AppSettings]

    private var settings: AppSettings? { settingsList.first }

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Settings")
                        .font(.gtDisplay(34, weight: .semibold))
                        .tracking(-1)
                        .foregroundColor(GT.ink)
                        .padding(.top, 10)
                        .padding(.bottom, 20)

                    if let s = settings {
                        Group {
                            SettingsGroup(label: "DEFAULTS") {
                                StepperRow(
                                    label: "Units",
                                    value: s.units.rawValue,
                                    onMinus: { toggleUnits(s) },
                                    onPlus: { toggleUnits(s) }
                                )
                                StepperRow(
                                    label: "Cold warmup %",
                                    value: "\(Int(s.coldPct * 100))%",
                                    onMinus: { bumpPct(\.coldPct, by: -0.05, on: s) },
                                    onPlus:  { bumpPct(\.coldPct, by:  0.05, on: s) }
                                )
                                StepperRow(
                                    label: "Continuing warmup %",
                                    value: "\(Int(s.warmPct * 100))%",
                                    onMinus: { bumpPct(\.warmPct, by: -0.05, on: s) },
                                    onPlus:  { bumpPct(\.warmPct, by:  0.05, on: s) }
                                )
                                StepperRow(
                                    label: "Weight step",
                                    value: "±\(GTMath.formatWeight(s.weightStep)) \(s.units.rawValue)",
                                    onMinus: { cycleWeightStep(s, up: false) },
                                    onPlus:  { cycleWeightStep(s, up: true) }
                                )
                                StepperRow(
                                    label: "Rep step",
                                    value: "±\(s.repStep)",
                                    isLast: true,
                                    onMinus: { bumpInt(\.repStep, by: -1, min: 1, max: 5, on: s) },
                                    onPlus:  { bumpInt(\.repStep, by:  1, min: 1, max: 5, on: s) }
                                )
                            }
                            SettingsGroup(label: "REPS PER SET") {
                                StepperRow(
                                    label: "Cold warmup",
                                    value: "\(s.repsCold) reps",
                                    onMinus: { bumpInt(\.repsCold, by: -1, min: 1, max: 30, on: s) },
                                    onPlus:  { bumpInt(\.repsCold, by:  1, min: 1, max: 30, on: s) }
                                )
                                StepperRow(
                                    label: "Continuing warmup",
                                    value: "\(s.repsWarm) reps",
                                    onMinus: { bumpInt(\.repsWarm, by: -1, min: 1, max: 30, on: s) },
                                    onPlus:  { bumpInt(\.repsWarm, by:  1, min: 1, max: 30, on: s) }
                                )
                                StepperRow(
                                    label: "Loading set 1",
                                    value: "\(s.repsLoad1) reps",
                                    onMinus: { bumpInt(\.repsLoad1, by: -1, min: 1, max: 30, on: s) },
                                    onPlus:  { bumpInt(\.repsLoad1, by:  1, min: 1, max: 30, on: s) }
                                )
                                StepperRow(
                                    label: "Loading set 2",
                                    value: "\(s.repsLoad2) reps",
                                    isLast: true,
                                    onMinus: { bumpInt(\.repsLoad2, by: -1, min: 1, max: 30, on: s) },
                                    onPlus:  { bumpInt(\.repsLoad2, by:  1, min: 1, max: 30, on: s) }
                                )
                            }
                            SettingsGroup(label: "REST TIMERS") {
                                StepperRow(
                                    label: "Cold warmup",
                                    value: GTMath.mmss(s.restCold),
                                    onMinus: { bumpRest(\.restCold, by: -15, on: s) },
                                    onPlus:  { bumpRest(\.restCold, by:  15, on: s) }
                                )
                                StepperRow(
                                    label: "Continuing warmup",
                                    value: GTMath.mmss(s.restWarm),
                                    onMinus: { bumpRest(\.restWarm, by: -15, on: s) },
                                    onPlus:  { bumpRest(\.restWarm, by:  15, on: s) }
                                )
                                StepperRow(
                                    label: "Loading set 1",
                                    value: GTMath.mmss(s.restLoad1),
                                    onMinus: { bumpRest(\.restLoad1, by: -15, on: s) },
                                    onPlus:  { bumpRest(\.restLoad1, by:  15, on: s) }
                                )
                                StepperRow(
                                    label: "Loading set 2",
                                    value: GTMath.mmss(s.restLoad2),
                                    isLast: true,
                                    onMinus: { bumpRest(\.restLoad2, by: -15, on: s) },
                                    onPlus:  { bumpRest(\.restLoad2, by:  15, on: s) }
                                )
                            }
                            SettingsGroup(label: "ACTIVE SET") {
                                ToggleRow(label: "Haptic when rest ends", isOn: binding(for: \.hapticOnRestEnd))
                                ToggleRow(label: "Auto-advance on tap", isOn: binding(for: \.autoAdvance))
                                ToggleRow(label: "Keep screen awake", isOn: binding(for: \.keepAwake), isLast: true)
                            }
                            SettingsGroup(label: "DATA") {
                                SettingsRow(label: "Export CSV", value: "Soon")
                                SettingsRow(label: "Import from Strong", value: "Soon")
                                SettingsRow(label: "Reset all data", value: "", danger: true, isLast: true)
                            }
                        }
                    }

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Mutators

    private func toggleUnits(_ s: AppSettings) {
        s.units = s.units == .lb ? .kg : .lb
        try? context.save()
    }

    private func bumpPct(_ kp: ReferenceWritableKeyPath<AppSettings, Double>, by delta: Double, on s: AppSettings) {
        let next = ((s[keyPath: kp] + delta) * 100).rounded() / 100
        s[keyPath: kp] = min(0.95, max(0.20, next))
        try? context.save()
    }

    private func bumpInt(_ kp: ReferenceWritableKeyPath<AppSettings, Int>, by delta: Int, min lo: Int, max hi: Int, on s: AppSettings) {
        s[keyPath: kp] = min(hi, max(lo, s[keyPath: kp] + delta))
        try? context.save()
    }

    private func bumpRest(_ kp: ReferenceWritableKeyPath<AppSettings, Int>, by delta: Int, on s: AppSettings) {
        s[keyPath: kp] = min(600, max(0, s[keyPath: kp] + delta))
        try? context.save()
    }

    private func cycleWeightStep(_ s: AppSettings, up: Bool) {
        let options: [Double] = [1.0, 2.5, 5.0, 10.0]
        let idx = options.firstIndex(of: s.weightStep) ?? 1
        let next = up ? min(options.count - 1, idx + 1) : max(0, idx - 1)
        s.weightStep = options[next]
        try? context.save()
    }

    private func binding(for keyPath: ReferenceWritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings?[keyPath: keyPath] ?? false },
            set: { newValue in
                settings?[keyPath: keyPath] = newValue
                try? context.save()
            }
        )
    }
}

struct SettingsGroup<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .gtMonoCaption(size: 10, tracking: 1.5)
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            VStack(spacing: 0) { content() }
                .gtCard(radius: GT.rLg)
        }
        .padding(.bottom, 18)
    }
}

/// Read-only row (used for Data group stubs + dangerous actions).
struct SettingsRow: View {
    let label: String
    let value: String
    var danger: Bool = false
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.gtBody(14))
                    .foregroundColor(danger ? GT.warn : GT.ink)
                Spacer()
                if !value.isEmpty {
                    Text(value)
                        .font(.gtMono(13))
                        .foregroundColor(GT.ink3)
                }
                if !danger {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(GT.ink4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            if !isLast {
                Rectangle().fill(GT.line).frame(height: 1)
            }
        }
    }
}

/// Editable row — label on left, value centered, − / + buttons on right.
struct StepperRow: View {
    let label: String
    let value: String
    var isLast: Bool = false
    var onMinus: () -> Void
    var onPlus: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.gtBody(14))
                    .foregroundColor(GT.ink)
                Spacer(minLength: 8)
                Text(value)
                    .font(.gtMono(13))
                    .foregroundColor(GT.ink2)
                    .frame(minWidth: 60, alignment: .trailing)
                HStack(spacing: 0) {
                    stepButton("minus", action: onMinus)
                    stepButton("plus", action: onPlus)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            if !isLast {
                Rectangle().fill(GT.line).frame(height: 1)
            }
        }
    }

    private func stepButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 32, height: 32)
                .background(Circle().fill(GT.surface2))
                .overlay(Circle().stroke(GT.line, lineWidth: 1))
                .foregroundColor(GT.ink)
        }
        .buttonStyle(.plain)
        .padding(.leading, 4)
    }
}

struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label).font(.gtBody(14)).foregroundColor(GT.ink)
                Spacer()
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(GT.lime)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            if !isLast {
                Rectangle().fill(GT.line).frame(height: 1)
            }
        }
    }
}
