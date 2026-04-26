import Foundation
import SwiftData

/// First-launch seed loader. v3 (current) is the canonical catalog: ~119
/// exercises across 11 muscle groups plus the standard PPL/Upper/Lower
/// templates. Older v1/v2 keys are kept so existing installs (which ran
/// them) don't re-seed; v3 runs additively via find-or-create on top of
/// whatever's already there.
enum SeedLoader {
    private static let didSeedKey = "GymTime.didSeed.v1"
    private static let didSeedV2Key = "GymTime.didSeed.v2"
    private static let didSeedV3Key = "GymTime.didSeed.v3"

    static func seedIfNeeded(_ context: ModelContext) {
        // AppSettings — always need exactly one row.
        do {
            let settings = try context.fetch(FetchDescriptor<AppSettings>())
            if settings.isEmpty {
                context.insert(AppSettings())
                try context.save()
            }
        } catch {
            print("Seed AppSettings failed: \(error)")
        }

        // v3 is the canonical exercise catalog. Runs once. On first run,
        // marks v1/v2 keys complete too so legacy seeders never run on
        // brand-new installs (they'd produce duplicates with old naming).
        if !UserDefaults.standard.bool(forKey: didSeedV3Key) {
            do {
                try seedV3(context)
                UserDefaults.standard.set(true, forKey: didSeedV3Key)
                UserDefaults.standard.set(true, forKey: didSeedKey)
                UserDefaults.standard.set(true, forKey: didSeedV2Key)
            } catch {
                print("Seed v3 failed: \(error)")
            }
        }
    }

    // MARK: - v3 catalog

    private struct CatalogEntry {
        let name: String
        let muscle: MuscleGroup
        let equipment: Equipment
        let inLibrary: Bool
    }

    private static let v3Catalog: [CatalogEntry] = [
        // CHEST (15)
        .init(name: "Barbell Bench Press",          muscle: .chest, equipment: .barbell,    inLibrary: true),
        .init(name: "Machine Bench Press",          muscle: .chest, equipment: .machine,    inLibrary: true),
        .init(name: "Dumbbell Bench Press",         muscle: .chest, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Incline Barbell Bench Press",  muscle: .chest, equipment: .barbell,    inLibrary: true),
        .init(name: "Incline Machine Bench Press",  muscle: .chest, equipment: .machine,    inLibrary: true),
        .init(name: "Incline Dumbbell Press",       muscle: .chest, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Decline Barbell Bench Press",  muscle: .chest, equipment: .barbell,    inLibrary: true),
        .init(name: "Decline Dumbbell Bench Press", muscle: .chest, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Decline Machine Bench Press",  muscle: .chest, equipment: .machine,    inLibrary: true),
        .init(name: "Dumbbell Fly",                 muscle: .chest, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Cable Fly",                    muscle: .chest, equipment: .cable,      inLibrary: true),
        .init(name: "Pec Deck",                     muscle: .chest, equipment: .machine,    inLibrary: true),
        .init(name: "Push-up",                      muscle: .chest, equipment: .bodyweight, inLibrary: true),
        .init(name: "Machine Dip (chest)",          muscle: .chest, equipment: .machine,    inLibrary: true),
        .init(name: "Weighted Dip (chest)",         muscle: .chest, equipment: .bodyweight, inLibrary: true),

        // BACK (10)
        .init(name: "Lat Pulldown",         muscle: .back, equipment: .cable,      inLibrary: true),
        .init(name: "Seated Cable Row",     muscle: .back, equipment: .cable,      inLibrary: true),
        .init(name: "Machine Lat Pulldown", muscle: .back, equipment: .machine,    inLibrary: true),
        .init(name: "Machine Seated Row",   muscle: .back, equipment: .machine,    inLibrary: true),
        .init(name: "Barbell Row",          muscle: .back, equipment: .barbell,    inLibrary: true),
        .init(name: "Dumbbell Row",         muscle: .back, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Pull-up",              muscle: .back, equipment: .bodyweight, inLibrary: true),
        .init(name: "Chin-up",              muscle: .back, equipment: .bodyweight, inLibrary: true),
        .init(name: "Weighted Pull-up",     muscle: .back, equipment: .bodyweight, inLibrary: true),
        .init(name: "Face Pull",            muscle: .back, equipment: .cable,      inLibrary: true),

        // SHOULDERS (9)
        .init(name: "Overhead Machine Press",  muscle: .shoulders, equipment: .machine,  inLibrary: true),
        .init(name: "Overhead Press",          muscle: .shoulders, equipment: .barbell,  inLibrary: true),
        .init(name: "Seated Dumbbell Press",   muscle: .shoulders, equipment: .dumbbell, inLibrary: true),
        .init(name: "Arnold Press",            muscle: .shoulders, equipment: .dumbbell, inLibrary: true),
        .init(name: "Lateral Raise",           muscle: .shoulders, equipment: .dumbbell, inLibrary: true),
        .init(name: "Cable Lateral Raise",     muscle: .shoulders, equipment: .cable,    inLibrary: true),
        .init(name: "Front Raise",             muscle: .shoulders, equipment: .dumbbell, inLibrary: true),
        .init(name: "Reverse Pec Deck",        muscle: .shoulders, equipment: .machine,  inLibrary: true),
        .init(name: "Upright Row",             muscle: .shoulders, equipment: .barbell,  inLibrary: true),

        // TRICEPS (12)
        .init(name: "Close-Grip Bench Press",            muscle: .triceps, equipment: .barbell,    inLibrary: true),
        .init(name: "Seated Cable Triceps Pushdown",     muscle: .triceps, equipment: .cable,      inLibrary: true),
        .init(name: "Cable Triceps Pushdown",            muscle: .triceps, equipment: .cable,      inLibrary: true),
        .init(name: "Skull Crusher",                     muscle: .triceps, equipment: .barbell,    inLibrary: true),
        .init(name: "Machine Skull Crusher",             muscle: .triceps, equipment: .machine,    inLibrary: true),
        .init(name: "Rope Pushdown",                     muscle: .triceps, equipment: .cable,      inLibrary: true),
        .init(name: "Overhead Triceps Extension (DB)",   muscle: .triceps, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Overhead Cable Extension",          muscle: .triceps, equipment: .cable,      inLibrary: true),
        .init(name: "Diamond Push-up",                   muscle: .triceps, equipment: .bodyweight, inLibrary: true),
        .init(name: "Weighted Dip (triceps)",            muscle: .triceps, equipment: .bodyweight, inLibrary: true),
        .init(name: "Triceps Kickback",                  muscle: .triceps, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Bench Dip",                         muscle: .triceps, equipment: .bodyweight, inLibrary: true),

        // BICEPS (10)
        .init(name: "Barbell Curl",          muscle: .biceps, equipment: .barbell,  inLibrary: true),
        .init(name: "EZ-Bar Curl",           muscle: .biceps, equipment: .barbell,  inLibrary: true),
        .init(name: "Dumbbell Curl",         muscle: .biceps, equipment: .dumbbell, inLibrary: true),
        .init(name: "Hammer Curl",           muscle: .biceps, equipment: .dumbbell, inLibrary: true),
        .init(name: "Preacher Curl",         muscle: .biceps, equipment: .barbell,  inLibrary: true),
        .init(name: "Machine Preacher Curl", muscle: .biceps, equipment: .machine,  inLibrary: true),
        .init(name: "Concentration Curl",    muscle: .biceps, equipment: .dumbbell, inLibrary: true),
        .init(name: "Cable Curl",            muscle: .biceps, equipment: .cable,    inLibrary: true),
        .init(name: "Reverse Curl",          muscle: .biceps, equipment: .barbell,  inLibrary: true),
        .init(name: "Incline Dumbbell Curl", muscle: .biceps, equipment: .dumbbell, inLibrary: true),

        // QUADS (10)
        .init(name: "Back Squat",            muscle: .quads, equipment: .barbell,    inLibrary: true),
        .init(name: "Front Squat",           muscle: .quads, equipment: .barbell,    inLibrary: true),
        .init(name: "Goblet Squat",          muscle: .quads, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Hack Squat",            muscle: .quads, equipment: .machine,    inLibrary: true),
        .init(name: "Leg Press",             muscle: .quads, equipment: .machine,    inLibrary: true),
        .init(name: "Leg Extension",         muscle: .quads, equipment: .machine,    inLibrary: true),
        .init(name: "Walking Lunge",         muscle: .quads, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Bulgarian Split Squat", muscle: .quads, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Step-up",               muscle: .quads, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Sissy Squat",           muscle: .quads, equipment: .bodyweight, inLibrary: false),

        // HAMSTRINGS (10)
        .init(name: "Romanian Deadlift",            muscle: .hamstrings, equipment: .barbell,    inLibrary: true),
        .init(name: "Stiff-Leg Deadlift",           muscle: .hamstrings, equipment: .barbell,    inLibrary: true),
        .init(name: "Conventional Deadlift",        muscle: .hamstrings, equipment: .barbell,    inLibrary: true),
        .init(name: "Lying Leg Curl",               muscle: .hamstrings, equipment: .machine,    inLibrary: true),
        .init(name: "Seated Leg Curl",              muscle: .hamstrings, equipment: .machine,    inLibrary: true),
        .init(name: "Good Morning",                 muscle: .hamstrings, equipment: .barbell,    inLibrary: true),
        .init(name: "Single-Leg Romanian Deadlift", muscle: .hamstrings, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Glute-Ham Raise",              muscle: .hamstrings, equipment: .bodyweight, inLibrary: true),
        .init(name: "Cable Pull-Through",           muscle: .hamstrings, equipment: .cable,      inLibrary: true),
        .init(name: "Nordic Curl",                  muscle: .hamstrings, equipment: .bodyweight, inLibrary: false),

        // GLUTES (10)
        .init(name: "Hip Thrust",              muscle: .glutes, equipment: .barbell,    inLibrary: true),
        .init(name: "Glute Bridge",            muscle: .glutes, equipment: .barbell,    inLibrary: true),
        .init(name: "Cable Kickback",          muscle: .glutes, equipment: .cable,      inLibrary: true),
        .init(name: "Sumo Deadlift",           muscle: .glutes, equipment: .barbell,    inLibrary: true),
        .init(name: "Single-Leg Hip Thrust",   muscle: .glutes, equipment: .bodyweight, inLibrary: true),
        .init(name: "Curtsy Lunge",            muscle: .glutes, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Step-up (glute focus)",   muscle: .glutes, equipment: .dumbbell,   inLibrary: false),
        .init(name: "Reverse Hyperextension",  muscle: .glutes, equipment: .machine,    inLibrary: true),
        .init(name: "Banded Clamshell",        muscle: .glutes, equipment: .bodyweight, inLibrary: false),
        .init(name: "Frog Pump",               muscle: .glutes, equipment: .bodyweight, inLibrary: false),

        // CALVES (10)
        .init(name: "Standing Calf Raise (Barbell)", muscle: .calves, equipment: .barbell,    inLibrary: true),
        .init(name: "Standing Calf Raise (Machine)", muscle: .calves, equipment: .machine,    inLibrary: true),
        .init(name: "Seated Calf Raise",             muscle: .calves, equipment: .machine,    inLibrary: true),
        .init(name: "Donkey Calf Raise",             muscle: .calves, equipment: .bodyweight, inLibrary: false),
        .init(name: "Single-Leg Calf Raise",         muscle: .calves, equipment: .bodyweight, inLibrary: true),
        .init(name: "Smith Machine Calf Raise",      muscle: .calves, equipment: .machine,    inLibrary: true),
        .init(name: "Leg Press Calf Raise",          muscle: .calves, equipment: .machine,    inLibrary: true),
        .init(name: "Calf Raise on Step",            muscle: .calves, equipment: .bodyweight, inLibrary: true),
        .init(name: "Tibialis Raise",                muscle: .calves, equipment: .bodyweight, inLibrary: false),
        .init(name: "Jump Rope",                     muscle: .calves, equipment: .bodyweight, inLibrary: false),

        // CORE (13)
        .init(name: "Plank",                  muscle: .core, equipment: .bodyweight, inLibrary: true),
        .init(name: "Hanging Leg Raise",      muscle: .core, equipment: .bodyweight, inLibrary: true),
        .init(name: "Cable Crunch",           muscle: .core, equipment: .cable,      inLibrary: true),
        .init(name: "Machine Crunch",         muscle: .core, equipment: .machine,    inLibrary: true),
        .init(name: "Machine Twist",          muscle: .core, equipment: .machine,    inLibrary: true),
        .init(name: "Seated Back Extension",  muscle: .core, equipment: .machine,    inLibrary: true),
        .init(name: "Ab Wheel Rollout",       muscle: .core, equipment: .bodyweight, inLibrary: true),
        .init(name: "Russian Twist",          muscle: .core, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Bicycle Crunch",         muscle: .core, equipment: .bodyweight, inLibrary: true),
        .init(name: "Side Plank",             muscle: .core, equipment: .bodyweight, inLibrary: true),
        .init(name: "Hollow Hold",            muscle: .core, equipment: .bodyweight, inLibrary: true),
        .init(name: "Dead Bug",               muscle: .core, equipment: .bodyweight, inLibrary: true),
        .init(name: "Mountain Climber",       muscle: .core, equipment: .bodyweight, inLibrary: false),

        // FOREARMS (10)
        .init(name: "Wrist Curl",                  muscle: .forearms, equipment: .barbell,    inLibrary: true),
        .init(name: "Reverse Wrist Curl",          muscle: .forearms, equipment: .barbell,    inLibrary: true),
        .init(name: "Farmer's Carry",              muscle: .forearms, equipment: .dumbbell,   inLibrary: true),
        .init(name: "Plate Pinch",                 muscle: .forearms, equipment: .bodyweight, inLibrary: false),
        .init(name: "Dead Hang",                   muscle: .forearms, equipment: .bodyweight, inLibrary: true),
        .init(name: "Towel Pull-up",               muscle: .forearms, equipment: .bodyweight, inLibrary: false),
        .init(name: "Wrist Roller",                muscle: .forearms, equipment: .bodyweight, inLibrary: false),
        .init(name: "Behind-the-Back Wrist Curl",  muscle: .forearms, equipment: .barbell,    inLibrary: false),
        .init(name: "Finger Curl",                 muscle: .forearms, equipment: .barbell,    inLibrary: false),
        .init(name: "Gripper Squeeze",             muscle: .forearms, equipment: .bodyweight, inLibrary: false),
    ]

    private struct TemplateSpec {
        let name: String
        let subtitle: String
        let exercises: [String] // Names matching the v3 catalog
    }

    private static let v3Templates: [TemplateSpec] = [
        TemplateSpec(name: "Push", subtitle: "Chest · Shoulders · Triceps", exercises: [
            "Barbell Bench Press", "Overhead Press", "Incline Dumbbell Press",
            "Weighted Dip (chest)", "Cable Triceps Pushdown",
        ]),
        TemplateSpec(name: "Pull", subtitle: "Back · Biceps · Rear Delts", exercises: [
            "Barbell Row", "Weighted Pull-up", "Seated Cable Row",
            "Barbell Curl", "Hammer Curl",
        ]),
        TemplateSpec(name: "Legs", subtitle: "Quads · Hamstrings · Glutes", exercises: [
            "Back Squat", "Romanian Deadlift", "Leg Press",
            "Walking Lunge", "Lying Leg Curl", "Standing Calf Raise (Machine)",
        ]),
        TemplateSpec(name: "Upper", subtitle: "Full upper body", exercises: [
            "Barbell Bench Press", "Barbell Row", "Overhead Press",
            "Weighted Pull-up", "Incline Dumbbell Press", "Barbell Curl",
            "Cable Triceps Pushdown",
        ]),
        TemplateSpec(name: "Lower", subtitle: "Full lower body", exercises: [
            "Back Squat", "Romanian Deadlift", "Leg Press",
            "Walking Lunge", "Lying Leg Curl", "Standing Calf Raise (Machine)",
        ]),
    ]

    private static func seedV3(_ context: ModelContext) throws {
        // Find-or-create exercises by case-insensitive name. New installs
        // get the full catalog. Existing installs gain any new entries.
        let existingExercises = try context.fetch(FetchDescriptor<Exercise>())
        var byLowerName: [String: Exercise] = Dictionary(
            existingExercises.map { ($0.name.lowercased(), $0) },
            uniquingKeysWith: { a, _ in a }
        )

        for entry in v3Catalog {
            if let _ = byLowerName[entry.name.lowercased()] { continue }
            let ex = Exercise(
                name: entry.name,
                muscles: [entry.muscle],
                equipment: entry.equipment,
                isInLibrary: entry.inLibrary
            )
            context.insert(ex)
            byLowerName[entry.name.lowercased()] = ex
        }

        // Templates — only seed if no templates exist yet (brand-new install).
        // Existing installs already have v1 templates; we don't duplicate.
        let existingTemplates = try context.fetch(FetchDescriptor<WorkoutTemplate>())
        if existingTemplates.isEmpty {
            for (i, spec) in v3Templates.enumerated() {
                let t = WorkoutTemplate(name: spec.name, subtitle: spec.subtitle, order: i)
                context.insert(t)
                for (j, exName) in spec.exercises.enumerated() {
                    guard let ex = byLowerName[exName.lowercased()] else { continue }
                    let te = TemplateExercise(template: t, exercise: ex, order: j)
                    context.insert(te)
                }
            }
        }

        try context.save()
    }
}
