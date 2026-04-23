import Foundation
import ActivityKit

/// Shared between the main app (starts/updates/ends the activity) and the
/// widget extension (renders the lock-screen + Dynamic Island UI).
struct GymTimeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Display name of the current exercise, e.g. "Barbell Bench Press".
        var exerciseName: String
        /// Label for the current set, e.g. "LOADING SET 2".
        var setLabel: String
        /// Position within the exercise, e.g. "3 of 5".
        var setPosition: String
        /// Weight for the current set in the user's current unit.
        var weight: Double
        /// Reps planned for the current set.
        var reps: Int
        /// Wall-clock time the rest started. `nil` when not resting.
        var restStartedAt: Date?
        /// Planned rest duration in seconds.
        var restPlannedSec: Int
        /// Template name, e.g. "PUSH".
        var templateName: String
        /// Unit abbreviation ("lb" / "kg") for presentation.
        var unit: String

        var isResting: Bool { restStartedAt != nil && restPlannedSec > 0 }

        /// Inclusive end date for the rest countdown. `Text(timerInterval:)`
        /// on the widget uses this to live-count on the lock screen without
        /// the app having to push an update every second.
        var restEndsAt: Date? {
            guard let start = restStartedAt else { return nil }
            return start.addingTimeInterval(TimeInterval(restPlannedSec))
        }
    }
}
