import ActivityKit
import WidgetKit
import SwiftUI

/// Lock-screen + Dynamic Island presentation of the current workout.
struct GymTimeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GymTimeActivityAttributes.self) { context in
            // Lock screen / banner
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.9))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.setLabel)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.green)
                        Text(context.state.exerciseName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(formatWeight(context.state.weight)) \(context.state.unit)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("× \(context.state.reps) reps")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let ends = context.state.restEndsAt {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.blue)
                            Text("Rest")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                            Text(timerInterval: Date()...ends, countsDown: true)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.blue)
                                .monospacedDigit()
                            Spacer()
                            Text(context.state.setPosition)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    } else {
                        HStack {
                            Text(context.state.templateName.uppercased())
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text(context.state.setPosition)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.green)
            } compactTrailing: {
                if let ends = context.state.restEndsAt {
                    Text(timerInterval: Date()...ends, countsDown: true)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.blue)
                        .monospacedDigit()
                        .frame(maxWidth: 48)
                } else {
                    Text("\(formatWeight(context.state.weight))")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
            } minimal: {
                if context.state.restEndsAt != nil {
                    Image(systemName: "timer")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.green)
                }
            }
        }
    }

    private func formatWeight(_ v: Double) -> String {
        if v == v.rounded() { return "\(Int(v))" }
        return String(format: "%.1f", v)
    }
}

/// Lock-screen presentation — shows current set info and the rest timer
/// counting down with `Text(timerInterval:)` (ticks automatically without
/// any update push from the app).
struct LockScreenView: View {
    let state: GymTimeActivityAttributes.ContentState

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Left: big weight + reps
            VStack(alignment: .leading, spacing: 2) {
                Text(state.setLabel)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(1.1)
                    .foregroundColor(.green)
                Text(state.exerciseName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatWeight(state.weight))
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(state.unit)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                    Text("× \(state.reps)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.leading, 6)
                }
            }

            Spacer(minLength: 8)

            // Right: rest timer or template label
            VStack(alignment: .trailing, spacing: 4) {
                Text(state.templateName.uppercased() + " · " + state.setPosition)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(1.0)
                    .foregroundColor(.white.opacity(0.55))
                if let ends = state.restEndsAt {
                    Text("REST")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(1.0)
                        .foregroundColor(.blue)
                    Text(timerInterval: Date()...ends, countsDown: true)
                        .font(.system(size: 28, weight: .semibold, design: .monospaced))
                        .foregroundColor(.blue)
                        .monospacedDigit()
                        .frame(minWidth: 92, alignment: .trailing)
                } else {
                    Text("READY")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(1.0)
                        .foregroundColor(.green)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private func formatWeight(_ v: Double) -> String {
        if v == v.rounded() { return "\(Int(v))" }
        return String(format: "%.1f", v)
    }
}
