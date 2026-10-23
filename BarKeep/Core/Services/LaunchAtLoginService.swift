import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginService: ObservableObject {
    static let shared = LaunchAtLoginService()

    @Published private(set) var isEnabled: Bool = false

    private init() {
        refresh()
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    func toggle() -> Bool {
        set(enabled: !isEnabled)
    }

    @discardableResult
    func set(enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled {
                    isEnabled = true
                    return true
                }
                try SMAppService.mainApp.register()
                Log.info("Автозапуск при входе успешно зарегистрирован")
            } else {
                try SMAppService.mainApp.unregister()
                Log.info("Автозапуск при входе успешно отключён")
            }
            refresh()
            return true
        } catch {
            Log.error("Ошибка изменения статуса автозапуска: \(error)")
            refresh()
            return false
        }
    }
}
