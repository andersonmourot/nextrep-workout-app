import Foundation
import UserNotifications

struct RestTimerNotifier {
    private let identifier = "nextrep.rest.complete"
    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return
        }

        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleRestComplete(after seconds: Int, exerciseName: String? = nil) async {
        guard seconds > 0 else {
            return
        }

        await requestAuthorizationIfNeeded()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Rest complete"
        content.body = exerciseName.map { "Time for your next set of \($0)." } ?? "Time for your next set."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelRestComplete() {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
