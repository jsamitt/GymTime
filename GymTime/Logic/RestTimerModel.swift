import Foundation
import Combine
import UserNotifications
#if os(iOS)
import UIKit
#endif
#if os(watchOS)
import WatchKit
#endif

@MainActor
final class RestTimerModel: ObservableObject {
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var elapsed: Int = 0
    @Published private(set) var plannedSec: Int = 0
    @Published private(set) var didFire: Bool = false

    private(set) var startDate: Date?
    private var timer: Timer?
    private var hapticEnabled: Bool = true
    private var pendingNotificationId: String?

    var remainingSec: Int { max(0, plannedSec - elapsed) }
    var progress: Double {
        guard plannedSec > 0 else { return 0 }
        return min(1.0, Double(elapsed) / Double(plannedSec))
    }

    func start(planned: Int, hapticOnEnd: Bool) {
        invalidate()
        // Kill the previous set's rest entirely before (re)starting. invalidate()
        // above drops the in-process tick timer, but the pending background
        // notification must be cancelled here too: scheduleBackgroundFallback
        // overwrites pendingNotificationId with a fresh UUID, so without this
        // the earlier set's notification is orphaned and still fires a stale
        // "Rest complete" alert/haptic when you log or skip before it elapses.
        cancelBackgroundFallback()
        // A non-positive planned rest (cold warmups use restCold = 0) means
        // "no rest", not a running 0-second rest. Starting a live timer with
        // plannedSec == 0 leaves isRunning true forever — showing a stuck
        // 0:00 rest block in-app and pushing a Live-Activity state whose
        // restEndsAt == restStartedAt, which inverts the widget's
        // `Date()...ends` countdown range and freezes the activity. That was
        // the first (cold) set of every new-muscle exercise appearing not to
        // render or progress. Reset to a clean stopped state instead.
        guard planned > 0 else {
            plannedSec = 0
            elapsed = 0
            didFire = false
            isRunning = false
            startDate = nil
            return
        }
        self.plannedSec = planned
        self.hapticEnabled = hapticOnEnd
        self.startDate = Date()
        self.elapsed = 0
        self.didFire = false
        self.isRunning = true
        scheduleBackgroundFallback(after: planned, hapticOnEnd: hapticOnEnd)
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    func stop() {
        cancelBackgroundFallback()
        invalidate()
        isRunning = false
        elapsed = 0
        plannedSec = 0
        didFire = false
    }

    func adjust(delta: Int) {
        let new = max(0, plannedSec + delta)
        plannedSec = new
        if isRunning {
            cancelBackgroundFallback()
            let remaining = max(1, new - elapsed)
            scheduleBackgroundFallback(after: remaining, hapticOnEnd: hapticEnabled)
        }
    }

    private func tick() {
        guard let start = startDate else { return }
        // Poll at 0.1s so didFire/haptic timing stays tight, but only
        // publish `elapsed` when the displayed second actually changes —
        // otherwise this republishes 10x/sec, forcing ActiveSetView's
        // entire body (including the ··· menu) to re-render that often
        // and intermittently swallowing taps mid-render.
        let seconds = Int(Date().timeIntervalSince(start))
        if seconds != elapsed {
            elapsed = seconds
        }
        if !didFire, elapsed >= plannedSec, plannedSec > 0 {
            didFire = true
            fireHaptic()
        }
    }

    private func invalidate() {
        timer?.invalidate()
        timer = nil
    }

    private func fireHaptic() {
        guard hapticEnabled else { return }
        #if os(iOS)
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #endif
    }

    private func scheduleBackgroundFallback(after seconds: Int, hapticOnEnd: Bool) {
        guard seconds > 0 else { return }
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Rest complete"
        content.body = "Set is ready."
        // Use sound + active interruption — watchOS only reliably plays its
        // haptic for a mirrored notification when the source notification
        // would itself break through. Passive/silent killed the wrist buzz.
        // The phone-side banner is the price of a reliable watch haptic.
        content.sound = hapticOnEnd ? .default : nil
        content.interruptionLevel = .active
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let id = UUID().uuidString
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(req) { _ in }
        pendingNotificationId = id
    }

    private func cancelBackgroundFallback() {
        if let id = pendingNotificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            pendingNotificationId = nil
        }
    }

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
