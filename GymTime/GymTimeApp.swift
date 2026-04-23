import SwiftUI
import SwiftData

@main
struct GymTimeApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            Session.self,
            ExerciseLog.self,
            SetLog.self,
            AppSettings.self,
        ])
        // SwiftData + CloudKit private sync. Falls back to a local-only store
        // if CloudKit init fails (e.g. fresh simulator with no Apple ID).
        let built: ModelContainer
        do {
            let config = ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.jsamitt.GymTime"))
            built = try ModelContainer(for: schema, configurations: config)
        } catch {
            print("iPhone CloudKit init failed: \(error)")
            do {
                built = try ModelContainer(for: schema)
            } catch {
                fatalError("Failed to build ModelContainer with CloudKit or local fallback: \(error)")
            }
        }
        container = built
        // Seed + cleanup on first launch
        Task { @MainActor [container] in
            SeedLoader.seedIfNeeded(container.mainContext)
            SessionCleanup.run(container.mainContext)
            // Notification permission is requested on first LOG SET tap.
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(GT.lime)
        }
        .modelContainer(container)
    }
}
