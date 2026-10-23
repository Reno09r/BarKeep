import AppKit
import Carbon.HIToolbox

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let permissions = PermissionsManager()
    private var statusController: StatusItemController?
    private var layout: MenuBarLayoutController?
    private var panelController: BarPanelController?
    private var activationService: ItemActivationService?
    private var hoverController: HoverRevealController?
    private var permissionPollTimer: Timer?


    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.info("BarKeep запущен. \(AppEnvironment.summary)")
        permissions.refresh(force: true)

        let scanner = MenuBarItemScanner()
        let layout = MenuBarLayoutController()
        self.layout = layout
        let activation = ItemActivationService(layout: layout, scanner: scanner)
        activationService = activation
        let hover = HoverRevealController(layout: layout)
        hoverController = hover
        let panel = BarPanelController(layout: layout, scanner: scanner, activation: activation)
        panelController = panel
        statusController = StatusItemController(
            scanner: scanner,
            permissions: permissions,
            layout: layout,
            activation: activation,
            panel: panel,
            hover: hover
        )
        installHotkeys()
        observeCommands()

        if permissions.accessibility {
            layout.applyDefaultState()
            if hover.isEnabled {
                hover.start()
            }
        } else {
            Log.warning("Accessibility не выдано — секции не скрываются, чтобы не оставить меню-бар пустым")
        }

        if let conflict = AppEnvironment.conflictingManagerName {
            Log.warning("Обнаружен другой менеджер меню-бара: \(conflict). Возможны конфликты при скрытии иконок.")
        }

        if !permissions.accessibility {
            Log.warning("Нет доступа к Accessibility — активация иконок будет ограничена.")
            startPermissionPollingIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showAccessibilityOnboarding()
            }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        checkPermissionRecovery()
    }

    private func startPermissionPollingIfNeeded() {
        guard !permissions.accessibility else { return }
        permissionPollTimer?.invalidate()
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPermissionRecovery()
            }
        }
    }

    private func checkPermissionRecovery() {
        guard !permissions.accessibility else { return }
        permissions.refresh(force: true)
        if permissions.accessibility {
            permissionPollTimer?.invalidate()
            permissionPollTimer = nil
            Log.info("Доступ к Accessibility обнаружен — активируем скрытие иконок")
            layout?.applyDefaultState()
            if hoverController?.isEnabled == true {
                hoverController?.start()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        Log.info("BarKeep завершается")
        layout?.resetAll()
    }

    /// Перед выходом возвращаем иконки на место. Разделитель исчезает вместе
    /// с процессом, поэтому иконки всё равно возвращаются, но сброс делает это сразу.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        layout?.resetAll()
        return .terminateNow
    }

    /// Команды из CLI и будущих хоткеев.
    private func observeCommands() {
        CommandBus.observe { [weak self] action in
            guard let self, let layout = self.layout else { return }
            switch action {
            case "showHidden": layout.show(.hidden)
            case "hideHidden": layout.hide(.hidden)
            case "toggleHidden": layout.toggle(.hidden)
            case "showAlwaysHidden": layout.show(.alwaysHidden)
            case "hideAlwaysHidden": layout.hide(.alwaysHidden)
            case "toggleAlwaysHidden": layout.toggle(.alwaysHidden)
            case "reset": layout.resetAll()
            case "panel": self.panelController?.toggle()
            case let action where action.hasPrefix("activate:"):
                let name = String(action.dropFirst("activate:".count))
                let scanner = MenuBarItemScanner()
                if let item = scanner.scan().first(where: {
                    !$0.isOwnItem && $0.displayName.localizedCaseInsensitiveContains(name)
                }) {
                    Log.info("Команда активации: \(item.displayName)")
                    self.activationService?.activate(item)
                } else {
                    Log.warning("Команда активации: не найдено \(name)")
                }
            case "quit": NSApp.terminate(nil)
            default: Log.warning("Неизвестная команда: \(action)")
            }
        }
    }

    /// Глобальные хоткеи: ⌃⌥⌘H — скрытые, ⌃⌥⌘A — всегда-скрытые, ⌃⌥⌘R — аварийный возврат.
    private func installHotkeys() {
        let modifiers = UInt32(controlKey | optionKey | cmdKey)

        HotkeyCenter.shared.register(keyCode: UInt32(kVK_ANSI_H), modifiers: modifiers) { [weak self] in
            Log.info("Хоткей ⌃⌥⌘H: открыть/закрыть панель")
            self?.panelController?.toggle()
        }
        HotkeyCenter.shared.register(keyCode: UInt32(kVK_ANSI_A), modifiers: modifiers) { [weak self] in
            Log.info("Хоткей ⌃⌥⌘A")
            self?.layout?.toggle(.alwaysHidden)
        }
        HotkeyCenter.shared.register(keyCode: UInt32(kVK_ANSI_R), modifiers: modifiers) { [weak self] in
            Log.warning("Аварийный хоткей ⌃⌥⌘R")
            self?.layout?.resetAll()
        }
    }

    private func showAccessibilityOnboarding() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = Localization.tr(.onboardingAccessibilityTitle)
        alert.informativeText = Localization.tr(.onboardingAccessibilityMessage)
        alert.alertStyle = .informational
        alert.addButton(withTitle: Localization.tr(.buttonOpenSettings))
        alert.addButton(withTitle: Localization.tr(.buttonLater))

        if alert.runModal() == .alertFirstButtonReturn {
            permissions.requestAccessibility()
        }
    }
}
