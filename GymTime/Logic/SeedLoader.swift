import Foundation
import SwiftData

enum SeedLoader {
    private static let didSeedKey = "GymTime.didSeed.v1"
    private static let didSeedV2Key = "GymTime.didSeed.v2"

    static func seedIfNeeded(_ context: ModelContext) {
        if !UserDefaults.standard.bool(forKey: didSeedKey) {
            do {
                let existing = try context.fetch(FetchDescriptor<AppSettings>())
                if existing.isEmpty {
                    context.insert(AppSettings())
                }
                seedLibraryAndTemplates(context)
                try context.save()
                UserDefaults.standard.set(true, forKey: didSeedKey)
            } catch {
                print("Seed v1 failed: \(error)")
            }
        }
        if !UserDefaults.standard.bool(forKey: didSeedV2Key) {
            do {
                try seedV2(context)
                UserDefaults.standard.set(true, forKey: didSeedV2Key)
            } catch {
                print("Seed v2 failed: \(error)")
            }
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

    // MARK: - v2 additive seed

    private struct V2Spec {
        let name: String
        let muscles: [MuscleGroup]
        let equipment: Equipment
        let templates: [String]
    }

    private static let v2Exercises: [V2Spec] = [
        V2Spec(name: "Pec Deck",                muscles: [.chest],      equipment: .machine,  templates: ["Push", "Upper"]),
        V2Spec(name: "Machine Bench Press",     muscles: [.chest],      equipment: .machine,  templates: ["Push", "Upper"]),
        V2Spec(name: "Close Grip Bench Press",  muscles: [.triceps],    equipment: .barbell,  templates: ["Push", "Upper"]),
        V2Spec(name: "Seated Cable Pushdown",   muscles: [.triceps],    equipment: .cable,    templates: ["Push", "Upper"]),
        V2Spec(name: "Machine Dip",             muscles: [.triceps],    equipment: .machine,  templates: ["Push", "Upper"]),
        V2Spec(name: "Concentration Curls",     muscles: [.biceps],     equipment: .dumbbell, templates: ["Pull", "Upper"]),
        V2Spec(name: "Machine Preacher Curls",  muscles: [.biceps],     equipment: .machine,  templates: ["Pull", "Upper"]),
        V2Spec(name: "Reverse Grip Curls",      muscles: [.biceps],     equipment: .cable,    templates: ["Pull", "Upper"]),
        V2Spec(name: "Leg Lifts",               muscles: [.quads],      equipment: .machine,  templates: ["Legs", "Lower"]),
        V2Spec(name: "Leg Curls",               muscles: [.hamstrings], equipment: .machine,  templates: ["Legs", "Lower"]),
        V2Spec(name: "Hip Adduction",           muscles: [.quads],      equipment: .machine,  templates: ["Legs", "Lower"]),
        V2Spec(name: "Calf Raises",             muscles: [.calves],     equipment: .machine,  templates: ["Legs", "Lower"]),
        V2Spec(name: "Shoulder Flies",          muscles: [.shoulders],  equipment: .machine,  templates: ["Push", "Upper"]),
    ]

    private static func seedV2(_ context: ModelContext) throws {
        let existingExercises = try context.fetch(FetchDescriptor<Exercise>())
        let byLowerName: [String: Exercise] = Dictionary(
            existingExercises.map { ($0.name.lowercased(), $0) },
            uniquingKeysWith: { a, _ in a }
        )
        let templates = try context.fetch(FetchDescriptor<WorkoutTemplate>())
        let templatesByName: [String: WorkoutTemplate] = Dictionary(
            templates.map { ($0.name, $0) },
            uniquingKeysWith: { a, _ in a }
        )

        for spec in v2Exercises {
            // Find-or-create the exercise (match by case-insensitive name).
            let exercise: Exercise
            if let found = byLowerName[spec.name.lowercased()] {
                exercise = found
                // Ensure library visibility.
                if !exercise.isInLibrary { exercise.isInLibrary = true }
            } else {
                exercise = Exercise(
                    name: spec.name,
                    muscles: spec.muscles,
                    equipment: spec.equipment,
                    isInLibrary: true
                )
                context.insert(exercise)
            }

            // Attach to the requested templates if not already present.
            for templateName in spec.templates {
                guard let template = templatesByName[templateName] else { continue }
                let alreadyIn = (template.templateExercises ?? []).contains { $0.exercise?.id == exercise.id }
                if alreadyIn { continue }
                let nextOrder = (template.templateExercises ?? []).map(\.order).max().map { $0 + 1 } ?? 0
                let te = TemplateExercise(template: template, exercise: exercise, order: nextOrder)
                context.insert(te)
            }
        }
        try context.save()
    }
}
