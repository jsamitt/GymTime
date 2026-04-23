import Foundation
import ActivityKit

/// Manages the single in-flight GymTime workout Live Activity. Starts it
/// when the Active Set screen appears, updates on every meaningful state
/// change, and ends it when the workout is closed/finished/abandoned.
///
/// Live Activities require iOS 16.1+; our deployment target is 17, so we
/// can use unguarded APIs directly. If the user has Live Activities disabled
/// globally in Settings, `start` no-ops silently.
@MainActor
final class LiveActivityController {
    static let shared = LiveActivityController()
    private var activity: Activity<GymTimeActivityAttributes>?

    private init() {}

    var isRunning: Bool { activity != nil }

    func start(state: GymTimeActivityAttributes.ContentState) {
        // Avoid duplicate starts — update in place if already running.
        if activity != nil {
            update(state: state)
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            let attrs = GymTimeActivityAttributes()
            activity = try Activity.request(
                attributes: attrs,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("LiveActivity start failed: \(error)")
        }
    }

    func update(state: GymTimeActivityAttributes.ContentState) {
        guard let activity else { return }
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end() {
        guard let activity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}
