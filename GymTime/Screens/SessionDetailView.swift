import SwiftUI
import SwiftData

/// Read-only drill-down for a finished Session. Shows each exercise with its
/// logged loading sets — weight × reps — plus template name, date, volume.
struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let session: Session

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        summaryBar
                        ForEach(session.orderedLogs) { log in
                            exerciseCard(log)
                        }
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
    }

    private var header: some View {
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
            VStack(spacing: 2) {
                Text(dayLabel())
                    .gtMonoCaption(size: 10, tracking: 1.3)
                Text(session.templateName)
                    .font(.gtDisplay(15, weight: .semibold))
                    .foregroundColor(GT.ink)
            }
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var summaryBar: some View {
        HStack(spacing: 10) {
            summaryTile("VOLUME", value: "\(GTMath.formatVolume(session.totalVolume)) lb")
            summaryTile("EXERCISES", value: "\(session.orderedLogs.count)")
            summaryTile("DURATION", value: durationString)
        }
    }

    private func summaryTile(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .gtMonoCaption(size: 9, tracking: 1.3)
            Text(value)
                .font(.gtDisplay(18, weight: .semibold))
                .foregroundColor(GT.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.rMd)
    }

    private func exerciseCard(_ log: ExerciseLog) -> some View {
        let loads = log.orderedSets.filter { $0.kind == .load && $0.loggedAt != nil && !$0.skipped }
        let warms = log.orderedSets.filter { ($0.kind == .cold || $0.kind == .warm) && $0.loggedAt != nil && !$0.skipped }
        let skipped = log.orderedSets.filter { $0.skipped }

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(log.exerciseName)
                    .font(.gtDisplay(18, weight: .semibold))
                    .foregroundColor(GT.ink)
                Spacer()
                if let last = loads.last {
                    Text("TOP \(GTMath.formatWeight(last.weight)) × \(last.reps)")
                        .font(.gtMono(10, weight: .semibold))
                        .tracking(1.0)
                        .foregroundColor(GT.lime)
                }
            }

            if loads.isEmpty && warms.isEmpty {
                Text("No sets logged")
                    .font(.gtMono(11))
                    .foregroundColor(GT.ink3)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(loads.enumerated()), id: \.element.id) { idx, set in
                        setRow(label: "LOAD \(idx + 1)", weight: set.weight, reps: set.reps, primary: true)
                    }
                    ForEach(warms) { set in
                        setRow(
                            label: set.kind == .cold ? "COLD" : "WARM",
                            weight: set.weight,
                            reps: set.reps,
                            primary: false
                        )
                    }
                }
            }

            if !skipped.isEmpty {
                Text("\(skipped.count) skipped")
                    .font(.gtMono(9))
                    .tracking(1.0)
                    .foregroundColor(GT.ink3)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.rMd)
    }

    private func setRow(label: String, weight: Double, reps: Int, primary: Bool) -> some View {
        HStack {
            Text(label)
                .font(.gtMono(10, weight: .medium))
                .tracking(1.1)
                .foregroundColor(primary ? GT.lime : GT.ink3)
                .frame(width: 64, alignment: .leading)
            Text("\(GTMath.formatWeight(weight)) lb × \(reps)")
                .font(.gtMono(13, weight: .medium))
                .foregroundColor(GT.ink)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(primary ? GT.limeWashSoft : GT.surface2))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(primary ? GT.limeEdge : GT.line, lineWidth: 1))
    }

    private func dayLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE · MMM d · h:mm a"
        return f.string(from: session.startedAt).uppercased()
    }

    private var durationString: String {
        guard let end = session.finishedAt else { return "—" }
        let mins = Int(end.timeIntervalSince(session.startedAt) / 60)
        if mins < 60 { return "\(mins)m" }
        return "\(mins / 60)h \(mins % 60)m"
    }
}
