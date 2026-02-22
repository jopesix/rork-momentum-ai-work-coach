import Foundation
import UIKit
import UserNotifications

@Observable
@MainActor
class AppMonitorService {
    var isSessionActive: Bool = false
    var timeAwaySeconds: Int = 0
    var showWelcomeBack: Bool = false

    private var backgroundTimestamp: Date?
    private var notificationsSent: Int = 0

    func startMonitoring() {
        isSessionActive = true
        notificationsSent = 0

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleBackground()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleForeground()
            }
        }
    }

    func stopMonitoring() {
        isSessionActive = false
        backgroundTimestamp = nil
        notificationsSent = 0
        NotificationCenter.default.removeObserver(self)
    }

    func dismissWelcomeBack() {
        showWelcomeBack = false
        timeAwaySeconds = 0
    }

    private func handleBackground() {
        guard isSessionActive else { return }
        backgroundTimestamp = Date()
        scheduleNotifications()
    }

    private func handleForeground() {
        guard isSessionActive, let backgroundTimestamp else { return }
        let away = Int(Date().timeIntervalSince(backgroundTimestamp))
        self.backgroundTimestamp = nil

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        if away > 120 {
            timeAwaySeconds = away
            showWelcomeBack = true
        }
    }

    private func scheduleNotifications() {
        guard notificationsSent < 2 else { return }

        let content1 = UNMutableNotificationContent()
        content1.title = "Mo is here"
        content1.body = "You've been away for a few minutes. Come back when you're ready — no judgment."
        content1.sound = .default

        let trigger1 = UNTimeIntervalNotificationTrigger(timeInterval: 180, repeats: false)
        let request1 = UNNotificationRequest(identifier: "mo_checkin_1", content: content1, trigger: trigger1)

        let content2 = UNMutableNotificationContent()
        content2.title = "Still here with you"
        content2.body = "Whenever you're ready. The work will be waiting."
        content2.sound = .default

        let trigger2 = UNTimeIntervalNotificationTrigger(timeInterval: 420, repeats: false)
        let request2 = UNNotificationRequest(identifier: "mo_checkin_2", content: content2, trigger: trigger2)

        UNUserNotificationCenter.current().add(request1)
        UNUserNotificationCenter.current().add(request2)
        notificationsSent = 2
    }

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
