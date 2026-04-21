import SwiftUI
import SwiftData

enum SyncStatus {
    case cloudKit
    case localOnly(String)
}

@MainActor
final class SyncStatusHolder: ObservableObject {
    static let shared = SyncStatusHolder()
    @Published var status: SyncStatus = .cloudKit
}

@main
struct GymTimeWatchApp: App {
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
        var initialStatus: SyncStatus = .cloudKit
        let built: ModelContainer
        do {
            let config = ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.jsamitt.GymTime"))
            built = try ModelContainer(for: schema, configurations: config)
        } catch {
            let msg = String(describing: error)
            print("Watch CloudKit init failed: \(msg)")
            initialStatus = .localOnly(msg)
            do {
                built = try ModelContainer(for: schema)
            } catch {
                fatalError("Watch local ModelContainer failed: \(error)")
            }
        }
        container = built
        let captured = initialStatus
        Task { @MainActor [built] in
            SyncStatusHolder.shared.status = captured
            SessionCleanup.run(built.mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .tint(GT.lime)
        }
        .modelContainer(container)
    }
}
