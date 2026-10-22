import AppKit

/// Окружение: другие менеджеры меню-бара, которые могут конфликтовать.
enum AppEnvironment {
    private static let knownManagers: [(bundleID: String, name: String)] = [
        ("com.jordanbaird.Ice", "Ice"),
        ("com.surteesstudios.Bartender", "Bartender"),
        ("com.dwarvesv.minimalbar", "Hidden Bar"),
        ("com.mortennn.Dozer", "Dozer"),
        ("com.pilotmoon.Scroll-Reverser", "Scroll Reverser"),
    ]

    static var conflictingManagerName: String? {
        let running = NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier)
        // Scroll Reverser — не менеджер, но его иконка иногда ведёт себя странно; в конфликты не включаем.
        for manager in knownManagers where manager.bundleID != "com.pilotmoon.Scroll-Reverser" {
            if running.contains(manager.bundleID) { return manager.name }
        }
        return nil
    }

    @MainActor
    static var summary: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let screens = NSScreen.screens
            .map { "\($0.localizedName) \(Int($0.frame.width))x\(Int($0.frame.height)) safeTop=\(Int($0.safeAreaInsets.top))" }
            .joined(separator: "; ")
        return """
        macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)
        Экраны: \(screens)
        Высота меню-бара: \(ItemActivator.menuBarHeight)
        Конфликтующий менеджер: \(conflictingManagerName ?? "нет")
        """
    }
}
