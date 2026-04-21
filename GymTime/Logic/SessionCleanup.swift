import Foundation
import SwiftData

/// Keeps at most one unfinished Session in the store, and only if it's recent.
/// Runs on app launch to heal any stale/duplicate active sessions that have
/// accumulated (e.g. from debugging or crashes).
///
/// - Any unfinished session older than `staleAfterHours` gets finished.
/// - If multiple unfinished sessions remain, only the most recent stays active;
///   the others are finished at their startedAt time (preserving history chronology).
@MainActor
enum SessionCleanup {
    static let staleAfterHours: Double = 6

    static func run(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.finishedAt == nil }
        )
        guard let unfinished = try? context.fetch(descriptor), !unfinished.isEmpty else { return }

        let sorted = unfinished.sorted { $0.startedAt > $1.startedAt }
        let cutoff = Date().addingTimeInterval(-staleAfterHours * 3600)

        for (index, session) in sorted.enumerated() {
            let isMostRecent = index == 0
            let isRecent = session.startedAt > cutoff
            if !isMostRecent || !isRecent {
                session.finishedAt = session.startedAt
            }
        }
        try? context.save()
    }

    /// Finish all unfinished sessions right now — used when starting a new
    /// workout so only one active session exists at a time.
    static func finishAllActive(_ context: ModelContext) {
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.finishedAt == nil }
        )
        guard let unfinished = try? context.fetch(descriptor) else { return }
        let now = Date()
        for session in unfinished {
            session.finishedAt = now
        }
        try? context.save()
    }
}
