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
        elapsed = Int(Date().timeIntervalSince(start))
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
        if hapticOnEnd {
            content.sound = .default
        } else {
            content.sound = nil
        }
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
