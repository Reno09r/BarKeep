import AppKit

/// Меню на иконке BarKeep в меню-баре.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let scanner: MenuBarItemScanner
    private let permissions: PermissionsManager
    private let layout: MenuBarLayoutController
    private let activation: ItemActivationService
    private let panel: BarPanelController
    private let hover: HoverRevealController
    private var items: [MenuBarItem] = []

    init(
        scanner: MenuBarItemScanner,
        permissions: PermissionsManager,
        layout: MenuBarLayoutController,
        activation: ItemActivationService,
        panel: BarPanelController,
        hover: HoverRevealController
    ) {
        self.scanner = scanner
        self.permissions = permissions
        self.layout = layout
        self.activation = activation
        self.panel = panel
        self.hover = hover
        self.statusItem = layout.controlItem
        super.init()

        menu.delegate = self
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        reload()
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else {
            panel.toggle()
            return
        }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showMenu()
        } else {
            panel.toggle()
        }
    }

    private func showMenu() {
        guard let button = statusItem.button else { return }
        reload()
        rebuild(menu)
        hover.isSuspended = true
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
        hover.isSuspended = false
    }

    func reload() {
        items = scanner.scan().filter { !$0.isOwnItem }
        Log.info("Сканирование: найдено \(items.count) элементов, скрытых за краем: \(items.filter(\.isOffscreen).count)")
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        permissions.refresh()
        reload()
        rebuild(menu)
    }

    private func rebuild(_ menu: NSMenu) {
        menu.removeAllItems()

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        let header = NSMenuItem(title: "BarKeep \(version)", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        if let conflict = AppEnvironment.conflictingManagerName {
            let warning = NSMenuItem(
                title: "⚠︎ Обнаружен \(conflict): возможны конфликты",
                action: nil,
                keyEquivalent: ""
            )
            warning.isEnabled = false
            menu.addItem(warning)
        }

        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: "Панель скрытых", keyEquivalent: "p") { [weak self] in
            self?.panel.toggle()
        })
        menu.addItem(ClosureMenuItem(title: "Обновить список", keyEquivalent: "r") { [weak self] in
            self?.reload()
        })

        // Секции
        let hiddenTitle = layout.isHiddenSectionCollapsed ? "Скрыть скрытые иконки" : "Показать скрытые иконки"
        menu.addItem(ClosureMenuItem(title: hiddenTitle, keyEquivalent: "h") { [weak self] in
            self?.layout.toggle(.hidden)
        })

        let hoverItem = NSMenuItem(
            title: "Показывать при наведении",
            action: #selector(toggleHoverReveal),
            keyEquivalent: ""
        )
        hoverItem.target = self
        hoverItem.state = hover.isEnabled ? .on : .off
        menu.addItem(hoverItem)

        menu.addItem(ClosureMenuItem(title: "Вернуть все иконки") { [weak self] in
            self?.layout.resetAll()
        })

        menu.addItem(.separator())

        let itemsMenu = NSMenu()
        if items.isEmpty {
            let empty = NSMenuItem(title: "Ничего не найдено", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            itemsMenu.addItem(empty)
        } else {
            for item in items {
                let section = layout.section(forX: item.frame.minX)
                let marker = item.isOffscreen ? "◌ " : ""
                let title = "\(marker)\(item.displayName)   · \(section.title)"
                let entry = ClosureMenuItem(title: title) { [weak self] in
                    self?.activate(item)
                }
                entry.toolTip = String(
                    format: "x=%.0f y=%.0f w=%.0f h=%.0f · pid=%d · %@",
                    item.frame.minX, item.frame.minY, item.frame.width, item.frame.height,
                    item.ownerPID, item.bundleIdentifier ?? "?"
                )
                itemsMenu.addItem(entry)
            }
        }

        let visibleCount = items.filter { layout.section(forX: $0.frame.minX) == .visible }.count
        let itemsParent = NSMenuItem(
            title: "Иконки: видимых \(visibleCount) из \(items.count)",
            action: nil,
            keyEquivalent: ""
        )
        itemsParent.submenu = itemsMenu
        menu.addItem(itemsParent)

        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem(
            title: permissions.accessibility ? "Accessibility: ✓" : "Accessibility: не выдано — открыть настройки"
        ) { [weak self] in
            self?.permissions.requestAccessibility()
        })

        menu.addItem(ClosureMenuItem(
            title: permissions.screenRecording ? "Запись экрана: ✓" : "Запись экрана: не выдано — открыть настройки"
        ) { [weak self] in
            self?.permissions.requestScreenRecording()
        })

        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem(title: "Скопировать отчёт в буфер") { [weak self] in
            self?.copyReport()
        })
        menu.addItem(ClosureMenuItem(title: "Открыть журнал") {
            Log.revealInFinder()
        })

        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: "Выйти") {
            NSApp.terminate(nil)
        })
    }

    @objc private func toggleHoverReveal() {
        let key = "BarKeepHoverReveal"
        let current = UserDefaults.standard.object(forKey: key) as? Bool ?? true
        UserDefaults.standard.set(!current, forKey: key)
    }

    private func activate(_ item: MenuBarItem) {
        Log.info("Активация: \(item.displayName)")
        // Даём нашему меню закрыться, иначе чужая иконка не откроет своё меню.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.activation.activate(item)
        }
    }

    private func copyReport() {
        var lines: [String] = [
            "BarKeep \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")",
            "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)",
            AppEnvironment.summary,
            "Элементов: \(items.count)",
            "Скрытые: \(layout.isHiddenSectionCollapsed ? "показаны" : "спрятаны"), всегда-скрытые: \(layout.isAlwaysHiddenSectionCollapsed ? "показаны" : "спрятаны")",
        ]
        if let hidden = layout.hiddenFrame, let alwaysHidden = layout.alwaysHiddenFrame {
            lines.append("Разделители: hidden.minX=\(Int(hidden.minX)) alwaysHidden.minX=\(Int(alwaysHidden.minX))")
        }
        for item in items {
            lines.append(String(
                format: "%@ [%@] x=%.1f y=%.1f w=%.1f h=%.1f onscreen=%d ax=%d pid=%d %@",
                item.displayName,
                layout.section(forX: item.frame.minX).title,
                item.frame.minX, item.frame.minY, item.frame.width, item.frame.height,
                item.isOnScreen ? 1 : 0,
                item.axElement == nil ? 0 : 1,
                item.ownerPID,
                item.bundleIdentifier ?? "?"
            ))
        }
        let text = lines.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        Log.info("Отчёт скопирован в буфер (\(items.count) строк)")
    }
}
