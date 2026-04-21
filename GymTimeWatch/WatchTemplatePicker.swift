import SwiftUI
import SwiftData

struct WatchTemplatePicker: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutTemplate.order) private var templates: [WorkoutTemplate]

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("START WORKOUT")
                    .font(.gtMono(10, weight: .semibold))
                    .tracking(1.4)
                    .foregroundColor(GT.ink3)
                    .padding(.top, 2)
                    .padding(.bottom, 2)

                ForEach(templates) { t in
                    Button { startWorkout(t) } label: {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.name)
                                    .font(.gtDisplay(15, weight: .semibold))
                                    .foregroundColor(GT.ink)
                                    .lineLimit(1)
                                Text("\(t.orderedExercises.count) ex")
                                    .font(.gtMono(9))
                                    .foregroundColor(GT.ink3)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(GT.ink3)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).fill(GT.surface))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(GT.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)
        }
        .background(GT.bg.ignoresSafeArea())
    }

    private func startWorkout(_ t: WorkoutTemplate) {
        SessionCleanup.finishAllActive(context)
        let s = Session(templateName: t.name)
        context.insert(s)
        for (i, te) in t.orderedExercises.enumerated() {
            if let ex = te.exercise {
                let log = ExerciseLog(session: s, exercise: ex, order: i)
                context.insert(log)
            }
        }
        try? context.save()
        dismiss()
    }
}
