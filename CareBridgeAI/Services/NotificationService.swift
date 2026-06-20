import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error {
                print("通知權限錯誤：\(error.localizedDescription)")
            }

            print("通知權限：\(granted ? "已允許" : "未允許")")
        }
    }

    func scheduleNotification(for task: CareTask) {
        cancelNotification(for: task)

        switch task.type {
        case .temporary:
            scheduleTemporaryNotification(for: task)

        case .routine:
            scheduleRoutineNotifications(for: task)
        }
    }

    func cancelNotification(for task: CareTask) {
        let identifiers = notificationIdentifiers(for: task)

        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
    }

    private func scheduleTemporaryNotification(for task: CareTask) {
        let content = notificationContent(for: task)

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: task.dueDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("新增非常態任務通知失敗：\(error.localizedDescription)")
            }
        }
    }

    private func scheduleRoutineNotifications(for task: CareTask) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: task.dueDate)
        let minute = calendar.component(.minute, from: task.dueDate)

        for weekday in task.repeatWeekdays {
            let content = notificationContent(for: task)

            var components = DateComponents()
            components.weekday = weekday.rawValue
            components.hour = hour
            components.minute = minute

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: "task-\(task.id.uuidString)-weekday-\(weekday.rawValue)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("新增常態任務通知失敗：\(error.localizedDescription)")
                }
            }
        }
    }

    private func notificationContent(for task: CareTask) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "CareBridge AI 任務提醒"
        content.body = task.note.isEmpty ? task.title : "\(task.title)：\(task.note)"
        content.sound = .default
        return content
    }

    private func notificationIdentifiers(for task: CareTask) -> [String] {
        switch task.type {
        case .temporary:
            return ["task-\(task.id.uuidString)"]

        case .routine:
            return Weekday.allCases.map {
                "task-\(task.id.uuidString)-weekday-\($0.rawValue)"
            }
        }
    }
}
