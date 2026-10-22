import Foundation

/// Простая шина команд между запущенным приложением и CLI/автоматизацией.
/// Используется для отладки и будущих хоткеев.
enum CommandBus {
    static let notificationName = Notification.Name("com.reno.barkeep.command")

    static func observe(_ handler: @escaping (String) -> Void) {
        DistributedNotificationCenter.default().addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { notification in
            guard let action = notification.userInfo?["action"] as? String else { return }
            handler(action)
        }
    }

    static func send(_ action: String) {
        DistributedNotificationCenter.default().postNotificationName(
            notificationName,
            object: nil,
            userInfo: ["action": action],
            deliverImmediately: true
        )
    }
}
