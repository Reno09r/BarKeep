import AppKit

/// Определяет приложение, которому принадлежит иконка меню-бара, и умеет его
/// скрыть или завершить.
///
/// Для «дочерних» меню-барных процессов (например, RobloxMenuBar) поднимается
/// до внешнего `.app`, чтобы закрывалось само приложение, а не хелпер.
@MainActor
enum AppTerminator {
    /// Приложение-владелец иконки (с учётом вложенных helper-бандлов).
    static func target(for item: MenuBarItem) -> NSRunningApplication? {
        guard item.ownerPID > 0, !item.isOwnItem else { return nil }
        guard let direct = NSRunningApplication(processIdentifier: item.ownerPID) else { return nil }
        guard let directURL = direct.bundleURL else { return direct }

        // Ищем внешний родительский .app бандл, если текущий процесс — вложенный хелпер
        var searchURL = directURL.deletingLastPathComponent()
        while searchURL.path != "/" && searchURL.path != "." {
            if searchURL.pathExtension == "app" {
                if let identifier = Bundle(url: searchURL)?.bundleIdentifier,
                   let main = NSRunningApplication.runningApplications(withBundleIdentifier: identifier).first {
                    return main
                }
                break
            }
            searchURL = searchURL.deletingLastPathComponent()
        }

        return direct
    }

    static func displayName(for item: MenuBarItem) -> String {
        target(for: item)?.localizedName ?? item.ownerName
    }

    /// Можно ли безопасно завершать: только сторонние приложения.
    static func canManage(item: MenuBarItem) -> Bool {
        guard let app = target(for: item) else { return false }
        guard let identifier = app.bundleIdentifier, !identifier.hasPrefix("com.apple.") else { return false }
        return true
    }

    @discardableResult
    static func terminate(item: MenuBarItem, force: Bool) -> Bool {
        guard canManage(item: item), let app = target(for: item) else { return false }
        return force ? app.forceTerminate() : app.terminate()
    }

    static func hide(item: MenuBarItem) {
        target(for: item)?.hide()
    }
}
