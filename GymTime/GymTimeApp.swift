import SwiftUI
import SwiftData

@main
struct GymTimeApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Exercise.self,
                WorkoutTemplate.self,
                TemplateExercise.self,
                Session.self,
                ExerciseLog.self,
                SetLog.self,
                AppSettings.self,
            ])
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to build ModelContainer: \(error)")
        }
        // Seed on first launch
        Task { @MainActor [container] in
            SeedLoader.seedIfNeeded(container.mainContext)
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
