import Foundation
import SwiftData

enum SeedLoader {
    private static let didSeedKey = "GymTime.didSeed.v1"

    static func seedIfNeeded(_ context: ModelContext) {
        if UserDefaults.standard.bool(forKey: didSeedKey) { return }
        do {
            // Settings singleton
            let existing = try context.fetch(FetchDescriptor<AppSettings>())
            if existing.isEmpty {
                context.insert(AppSettings())
            }
            seedLibraryAndTemplates(context)
            try context.save()
            UserDefaults.standard.set(true, forKey: didSeedKey)
        } catch {
            print("Seed failed: \(error)")
        }
    }

    private static func seedLibraryAndTemplates(_ context: ModelContext) {
        // Exercises — matches the mockup's library (grouped by muscle).
        let lib: [(String, [MuscleGroup], Equipment, Double, Int, Bool)] = [
            // Chest
            ("Barbell Bench Press",      [.chest, .triceps],    .barbell, 185, 5, true),
            ("Incline DB Press",         [.chest, .shoulders],  .dumbbell, 70, 8, true),
            ("Cable Fly",                [.chest],              .cable, 0, 12, false),
            ("Push-up",                  [.chest, .triceps],    .bodyweight, 0, 15, false),
            // Shoulders
            ("Overhead Press",           [.shoulders, .triceps], .barbell, 115, 6, true),
            ("Lateral Raise",            [.shoulders],          .dumbbell, 25, 12, true),
            ("Face Pull",                [.shoulders, .back],   .cable, 0, 15, false),
            // Triceps
            ("Weighted Dip",             [.triceps, .chest],    .bodyweight, 45, 8, true),
            ("Cable Triceps Pushdown",   [.triceps],            .cable, 62, 12, true),
            ("Skull Crusher",            [.triceps],            .barbell, 0, 10, false),
            // Back
            ("Barbell Row",              [.back, .biceps],      .barbell, 155, 6, true),
            ("Weighted Pull-up",         [.back, .biceps],      .bodyweight, 25, 6, true),
            ("Lat Pulldown",             [.back, .biceps],      .cable, 140, 10, true),
            ("Seated Cable Row",         [.back, .biceps],      .cable, 130, 10, true),
            // Biceps
            ("Barbell Curl",             [.biceps],             .barbell, 80, 8, true),
            ("Hammer Curl",              [.biceps, .forearms],  .dumbbell, 35, 10, true),
            // Legs
            ("Back Squat",               [.quads, .glutes],     .barbell, 245, 5, true),
            ("Romanian Deadlift",        [.hamstrings, .glutes], .barbell, 205, 6, true),
            ("Leg Press",                [.quads, .glutes],     .machine, 400, 10, true),
            ("Walking Lunge",            [.quads, .glutes],     .dumbbell, 40, 10, true),
            ("Leg Curl",                 [.hamstrings],         .machine, 110, 12, true),
            ("Standing Calf Raise",      [.calves],             .machine, 180, 12, true),
            // Core
            ("Hanging Leg Raise",        [.core],               .bodyweight, 0, 12, false),
            ("Cable Crunch",             [.core],               .cable, 90, 15, false),
        ]

        var byName: [String: Exercise] = [:]
        for (name, muscles, eq, weight, reps, inLib) in lib {
            let e = Exercise(
                name: name, muscles: muscles, equipment: eq,
                topWorkingWeight: weight, repTarget: reps,
                numLoadingSets: 2, isInLibrary: inLib
            )
            context.insert(e)
            byName[name] = e
        }

        // Templates
        let templates: [(String, String, [String])] = [
            ("Push", "Chest · Shoulders · Triceps", [
                "Barbell Bench Press", "Overhead Press", "Incline DB Press",
                "Weighted Dip", "Cable Triceps Pushdown"
            ]),
            ("Pull", "Back · Biceps · Rear Delts", [
                "Barbell Row", "Weighted Pull-up", "Seated Cable Row",
                "Barbell Curl", "Hammer Curl"
            ]),
            ("Legs", "Quads · Hamstrings · Glutes", [
                "Back Squat", "Romanian Deadlift", "Leg Press",
                "Walking Lunge", "Leg Curl", "Standing Calf Raise"
            ]),
            ("Upper", "Full upper body", [
                "Barbell Bench Press", "Barbell Row", "Overhead Press",
                "Weighted Pull-up", "Incline DB Press", "Barbell Curl",
                "Cable Triceps Pushdown"
            ]),
            ("Lower", "Full lower body", [
                "Back Squat", "Romanian Deadlift", "Leg Press",
                "Walking Lunge", "Leg Curl", "Standing Calf Raise"
            ]),
        ]
        for (i, (name, subtitle, exNames)) in templates.enumerated() {
            let t = WorkoutTemplate(name: name, subtitle: subtitle, order: i)
            context.insert(t)
            for (j, exName) in exNames.enumerated() {
                guard let ex = byName[exName] else { continue }
                let te = TemplateExercise(template: t, exercise: ex, order: j)
                context.insert(te)
            }
        }
    }
}
