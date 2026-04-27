import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutTemplate.order) private var templates: [WorkoutTemplate]
    @Query private var sessions: [Session]
    @Query private var settingsList: [AppSettings]

    @State private var activeTemplate: WorkoutTemplate?
    @State private var resumingSession: Session?

    private var activeSession: Session? {
        sessions
            .filter { $0.finishedAt == nil }
            .max(by: { $0.startedAt < $1.startedAt })
    }

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            // Pinned area (header + resume banner + stats) lives outside
            // the ScrollView so it stays put while routines scroll.
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                if let s = activeSession {
                    Button { resumingSession = s } label: {
                        resumeBanner(for: s)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                HStack(spacing: 10) {
                    StatTile(label: "Streak", value: "\(streakDays)", unit: "d", accent: true)
                    StatTile(label: "Days this wk", value: "\(daysTrainedThisWeek)", unit: "/7")
                    StatTile(label: "Volume", value: GTMath.formatVolume(weekVolume), unit: "")
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 4)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("ROUTINES")
                            .gtMonoCaption(size: 11, tracking: 1.6)
                            .padding(.top, 18)
                            .padding(.bottom, 12)

                        if templates.isEmpty {
                            emptyTemplatesHint
                        } else {
                            VStack(spacing: 10) {
                                ForEach(templates) { t in
                                    Button { activeTemplate = t } label: {
                                        WorkoutCard(template: t, lastLabel: lastLabel(for: t))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .fullScreenCover(item: $activeTemplate) { t in
            WorkoutDetailView(template: t) { activeTemplate = nil }
        }
        .fullScreenCover(item: $resumingSession) { s in
            ActiveSessionContainer(session: s)
        }
    }

    private func resumeBanner(for session: Session) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(GT.limeInk)
            VStack(alignment: .leading, spacing: 2) {
                Text("WORKOUT IN PROGRESS")
                    .font(.gtMono(10, weight: .semibold))
                    .tracking(1.4)
                    .foregroundColor(GT.limeInk.opacity(0.7))
                Text(session.templateName)
                    .font(.gtDisplay(18, weight: .semibold))
                    .foregroundColor(GT.limeInk)
            }
            Spacer()
            Text("RESUME →")
                .font(.gtMono(11, weight: .bold))
                .tracking(1.0)
                .foregroundColor(GT.limeInk)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: GT.rLg).fill(GT.lime))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(todayLabel())
                    .gtMonoCaption(size: 11, tracking: 1.5)
                Text("Pick a session.")
                    .font(.gtDisplay(34, weight: .semibold))
                    .tracking(-1)
                    .foregroundColor(GT.ink)
                    .lineLimit(1)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .regular))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(GT.surface2))
                    .overlay(Circle().stroke(GT.line, lineWidth: 1))
                    .foregroundColor(GT.ink2)
            }
            .buttonStyle(.plain)
        }
    }

    // Data derivations

    private var finishedSessions: [Session] {
        sessions.filter { $0.finishedAt != nil }
    }

    private var streakDays: Int {
        let cal = Calendar.current
        let completedDays = Set(finishedSessions.compactMap {
            $0.finishedAt.map { cal.startOfDay(for: $0) }
        })
        var day = cal.startOfDay(for: Date())
        var count = 0
        // Allow rest days — count today + any of the last 14 days where we trained
        // as a loose "streak". Simple: consecutive days with training in last 30 days.
        for _ in 0..<30 {
            if completedDays.contains(day) {
                count += 1
            } else if count > 0 {
                break
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    /// Unique calendar days this week with at least one finished session —
    /// a more useful frequency signal than session count (which double-counts
    /// when you do two-a-days).
    private var daysTrainedThisWeek: Int {
        let cal = Calendar.current
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        let days = Set(finishedSessions.compactMap { s -> Date? in
            guard let end = s.finishedAt, end >= weekStart else { return nil }
            return cal.startOfDay(for: end)
        })
        return days.count
    }

    private var weekVolume: Double {
        let cal = Calendar.current
        let startOfWeek = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return finishedSessions
            .filter { ($0.finishedAt ?? Date()) >= startOfWeek }
            .reduce(0) { $0 + $1.totalVolume }
    }

    private var emptyTemplatesHint: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No routines yet")
                .font(.gtDisplay(16, weight: .semibold))
                .foregroundColor(GT.ink)
            Text("Open Library → Routines → NEW ROUTINE to create one.")
                .font(.gtBody(12))
                .foregroundColor(GT.ink3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtCard(radius: GT.rLg)
    }

    private func lastLabel(for t: WorkoutTemplate) -> String {
        let last = finishedSessions
            .filter { $0.templateName == t.name }
            .map(\.startedAt)
            .max()
        return GTMath.relativeDays(from: last)
    }

    private func todayLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE · MMM d"
        return f.string(from: Date()).uppercased()
    }
}

struct WorkoutCard: View {
    let template: WorkoutTemplate
    let lastLabel: String

    /// Same formula WorkoutDetailView uses — 11 minutes per exercise, with
    /// a floor of 25 to keep short routines from looking trivial.
    private var estimatedMinutes: Int {
        max(25, template.orderedExercises.count * 11)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(template.name)
                .font(.gtDisplay(28, weight: .semibold))
                .tracking(-1.0)
                .foregroundColor(GT.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if !template.subtitle.isEmpty {
                Text(template.subtitle)
                    .font(.gtBody(13))
                    .foregroundColor(GT.ink2)
                    .padding(.top, 4)
                    .lineLimit(2)
            }
            HStack(spacing: 10) {
                Text("\(template.orderedExercises.count) ex")
                Text("·").opacity(0.5)
                Text("~\(estimatedMinutes) min")
                Text("·").opacity(0.5)
                Text("last: \(lastLabel)")
            }
            .font(.gtMono(11))
            .foregroundColor(GT.ink3)
            .padding(.top, 14)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: GT.rLg).fill(GT.surface))
        .overlay(RoundedRectangle(cornerRadius: GT.rLg).stroke(GT.line, lineWidth: 1))
    }
}
