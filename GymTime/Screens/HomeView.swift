import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutTemplate.order) private var templates: [WorkoutTemplate]
    @Query private var sessions: [Session]
    @Query private var settingsList: [AppSettings]

    @State private var activeTemplate: WorkoutTemplate?

    private var primary: [WorkoutTemplate] { Array(templates.prefix(3)) }
    private var alternate: [WorkoutTemplate] { Array(templates.dropFirst(3)) }

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    // Stats row
                    HStack(spacing: 10) {
                        StatTile(label: "Streak", value: "\(streakDays)", unit: "d", accent: true)
                        StatTile(label: "This wk", value: "\(weekCount)", unit: "/4")
                        StatTile(label: "Volume", value: GTMath.formatVolume(weekVolume), unit: "")
                    }
                    .padding(.top, 22)

                    // Routine header
                    HStack {
                        Text("PPL ROUTINE · WEEK \(routineWeek)")
                            .gtMonoCaption(size: 11, tracking: 1.6)
                        Spacer()
                        Text("edit")
                            .font(.gtMono(11))
                            .foregroundColor(GT.ink3)
                    }
                    .padding(.top, 22)
                    .padding(.bottom, 12)

                    VStack(spacing: 10) {
                        ForEach(Array(primary.enumerated()), id: \.element.id) { i, t in
                            Button { activeTemplate = t } label: {
                                WorkoutCard(template: t, isNext: i == 0, lastLabel: lastLabel(for: t))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !alternate.isEmpty {
                        Text("ALTERNATE TEMPLATES")
                            .gtMonoCaption(size: 11, tracking: 1.6)
                            .padding(.top, 22)
                            .padding(.bottom, 10)

                        HStack(spacing: 10) {
                            ForEach(alternate) { t in
                                Button { activeTemplate = t } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(t.name)
                                            .font(.gtDisplay(18, weight: .semibold))
                                            .foregroundColor(GT.ink)
                                        Text("\(t.orderedExercises.count) exercises")
                                            .font(.gtBody(11))
                                            .foregroundColor(GT.ink3)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .gtCard()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .fullScreenCover(item: $activeTemplate) { t in
            WorkoutDetailView(template: t) { activeTemplate = nil }
        }
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

    private var weekCount: Int {
        let cal = Calendar.current
        let startOfWeek = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return finishedSessions.filter { ($0.finishedAt ?? Date()) >= startOfWeek }.count
    }

    private var weekVolume: Double {
        let cal = Calendar.current
        let startOfWeek = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return finishedSessions
            .filter { ($0.finishedAt ?? Date()) >= startOfWeek }
            .reduce(0) { $0 + $1.totalVolume }
    }

    private var routineWeek: Int {
        guard let first = finishedSessions.map(\.startedAt).min() else { return 1 }
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: first, to: Date()).weekOfYear ?? 0
        return max(1, weeks + 1)
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
    let isNext: Bool
    let lastLabel: String

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if isNext {
                Text("NEXT UP →")
                    .font(.gtMono(10, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(GT.limeInk.opacity(0.6))
                    .padding(.top, 14)
                    .padding(.trailing, 16)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(template.name)
                    .font(.gtDisplay(32, weight: .semibold))
                    .tracking(-1.2)
                    .foregroundColor(isNext ? GT.limeInk : GT.ink)
                Text(template.subtitle)
                    .font(.gtBody(13))
                    .foregroundColor(isNext ? GT.limeInk.opacity(0.65) : GT.ink2)
                    .padding(.top, 4)

                HStack(spacing: 12) {
                    Text("\(template.orderedExercises.count) ex")
                    Text("·").opacity(0.5)
                    Text("~52 min")
                    Text("·").opacity(0.5)
                    Text("last: \(lastLabel)")
                }
                .font(.gtMono(11))
                .foregroundColor(isNext ? GT.limeInk.opacity(0.65) : GT.ink3)
                .padding(.top, 16)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: GT.rLg)
                .fill(isNext ? GT.lime : GT.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GT.rLg)
                .stroke(isNext ? .clear : GT.line, lineWidth: 1)
        )
    }
}
