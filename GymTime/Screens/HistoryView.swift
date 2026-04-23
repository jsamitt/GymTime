import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Session.startedAt, order: .reverse) private var sessions: [Session]
    @State private var selectedSession: Session?
    @State private var pendingDelete: Session?

    private var finished: [Session] { sessions.filter { $0.finishedAt != nil } }

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(weekCount) WEEKS · \(finished.count) SESSIONS")
                        .gtMonoCaption(size: 11, tracking: 1.4)
                        .padding(.bottom, 6)
                    Text("History")
                        .font(.gtDisplay(34, weight: .semibold))
                        .tracking(-1)
                        .foregroundColor(GT.ink)
                        .padding(.bottom, 20)

                    heatmap.padding(.bottom, 20)

                    Text("RECENT PRS")
                        .gtMonoCaption(size: 11, tracking: 1.5)
                        .padding(.bottom, 10)
                    VStack(spacing: 8) {
                        ForEach(recentPRs) { pr in
                            prRow(pr)
                        }
                    }
                    .padding(.bottom, 20)

                    Text("SESSIONS")
                        .gtMonoCaption(size: 11, tracking: 1.5)
                        .padding(.bottom, 10)
                    VStack(spacing: 8) {
                        ForEach(finished) { s in
                            SessionSwipeRow(session: s) {
                                selectedSession = s
                            } onDelete: {
                                pendingDelete = s
                            } content: {
                                sessionRow(s)
                            }
                        }
                        if finished.isEmpty {
                            emptyState
                        }
                    }

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .sheet(item: $selectedSession) { s in
            SessionDetailView(session: s)
        }
        .confirmationDialog(
            "Delete this session?",
            isPresented: .constant(pendingDelete != nil),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { s in
            Button("Delete", role: .destructive) {
                context.delete(s)
                try? context.save()
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { s in
            Text("\(s.templateName) · \(GTMath.formatVolume(s.totalVolume)) lb. This can't be undone.")
        }
    }

    private var emptyState: some View {
        Text("No finished sessions yet. Start a workout to fill this in.")
            .font(.gtBody(13))
            .foregroundColor(GT.ink3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .gtCard(radius: GT.rMd)
    }

    private var heatmap: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("CONSISTENCY")
                    .gtMonoCaption(size: 10, tracking: 1.3)
                Spacer()
                Text("\(streakDays) day streak")
                    .font(.gtMono(11))
                    .foregroundColor(GT.lime)
            }

            let cells = last14DaysIntensity()
            HStack(spacing: 4) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, v in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(cellColor(v))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            HStack {
                Text("2 WKS AGO").font(.gtMono(9)).foregroundColor(GT.ink3)
                Spacer()
                Text("TODAY").font(.gtMono(9)).foregroundColor(GT.ink3)
            }
        }
        .padding(16)
        .gtCard(radius: GT.rLg)
    }

    private func sessionRow(_ s: Session) -> some View {
        let parts = sessionDateParts(s.startedAt)
        return HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(parts.0).font(.gtMono(10)).foregroundColor(GT.ink3)
                Text(parts.1).font(.gtDisplay(14, weight: .semibold)).foregroundColor(GT.ink)
            }
            Rectangle().fill(GT.line).frame(width: 1, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(s.templateName).font(.gtDisplay(15, weight: .semibold)).foregroundColor(GT.ink)
                Text("\(s.orderedLogs.count) ex · \(GTMath.formatVolume(s.totalVolume)) lb")
                    .font(.gtMono(11))
                    .foregroundColor(GT.ink3)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(GT.ink3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .gtCard(radius: GT.rMd)
    }

    private func prRow(_ pr: PR) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .foregroundColor(GT.lime)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text(pr.name).font(.gtDisplay(14, weight: .semibold)).foregroundColor(GT.ink)
                Text("\(GTMath.formatWeight(pr.weight)) lb × \(pr.reps)").font(.gtMono(11)).foregroundColor(GT.ink3)
            }
            Spacer()
            Text(pr.delta)
                .font(.gtMono(12))
                .foregroundColor(GT.lime)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 6).fill(GT.limeWashSoft))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(GT.limeEdge, lineWidth: 1))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .gtCard(radius: GT.rMd)
    }

    // Data derivations

    private struct PR: Identifiable {
        let id = UUID()
        let name: String
        let weight: Double
        let reps: Int
        let delta: String
    }

    private var recentPRs: [PR] {
        // Pull best sets per exercise from the last 14 days.
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        var best: [String: (Double, Int)] = [:]
        for s in finished where (s.finishedAt ?? s.startedAt) >= cutoff {
            for log in s.orderedLogs {
                for set in log.orderedSets where set.kind == .load && set.loggedAt != nil {
                    let key = log.exerciseName
                    if let (w, _) = best[key] {
                        if set.weight > w { best[key] = (set.weight, set.reps) }
                    } else {
                        best[key] = (set.weight, set.reps)
                    }
                }
            }
        }
        return best.sorted { $0.value.0 > $1.value.0 }.prefix(5).map { name, v in
            PR(name: name, weight: v.0, reps: v.1, delta: "+\(Int(v.0 * 0.03)) lb")
        }
    }

    private var streakDays: Int {
        let cal = Calendar.current
        let done = Set(finished.compactMap { $0.finishedAt.map { cal.startOfDay(for: $0) } })
        var d = cal.startOfDay(for: Date())
        var n = 0
        for _ in 0..<30 {
            if done.contains(d) { n += 1 }
            else if n > 0 { break }
            guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
        }
        return n
    }

    private var weekCount: Int {
        let cal = Calendar.current
        guard let first = finished.map(\.startedAt).min() else { return 0 }
        return max(1, (cal.dateComponents([.weekOfYear], from: first, to: Date()).weekOfYear ?? 0) + 1)
    }

    private func last14DaysIntensity() -> [Int] {
        let cal = Calendar.current
        var out: [Int] = []
        for i in (0..<14).reversed() {
            guard let day = cal.date(byAdding: .day, value: -i, to: cal.startOfDay(for: Date())) else {
                out.append(0); continue
            }
            let dayEnd = cal.date(byAdding: .day, value: 1, to: day) ?? day
            let count = finished.filter { ($0.finishedAt ?? $0.startedAt) >= day && ($0.finishedAt ?? $0.startedAt) < dayEnd }
                                .count
            out.append(min(3, count > 0 ? count + 1 : 0))
        }
        return out
    }

    private func cellColor(_ v: Int) -> Color {
        switch v {
        case 0: return GT.surface2
        case 1: return GT.lime.opacity(0.22)
        case 2: return GT.lime.opacity(0.5)
        default: return GT.lime
        }
    }

    private func sessionDateParts(_ d: Date) -> (String, String) {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        let day = f.string(from: d).uppercased()
        f.dateFormat = "d"
        return (day, f.string(from: d))
    }
}
