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

        layout.configureHiddenDividerAction(target: self, action: #selector(dividerClicked))

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appLanguageDidChange),
            name: .appLanguageDidChange,
            object: nil
        )

        reload()
    }

    @objc private func appLanguageDidChange() {
        rebuild(menu)
    }

    @objc private func dividerClicked() {
        panel.toggle()
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
        let header = NSMenuItem(title: Localization.tr(.appVersion, version), action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        if let conflict = AppEnvironment.conflictingManagerName {
            let warning = NSMenuItem(
                title: Localization.tr(.conflictWarning, conflict),
                action: nil,
                keyEquivalent: ""
            )
            warning.isEnabled = false
            menu.addItem(warning)
        }

        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: Localization.tr(.hiddenPanel), keyEquivalent: "p") { [weak self] in
            self?.panel.toggle()
        })
        menu.addItem(ClosureMenuItem(title: Localization.tr(.refreshList), keyEquivalent: "r") { [weak self] in
            self?.reload()
        })

        // Секции
        let hiddenTitle = layout.isHiddenSectionCollapsed
            ? Localization.tr(.hideHiddenIcons)
            : Localization.tr(.showHiddenIcons)
        menu.addItem(ClosureMenuItem(title: hiddenTitle, keyEquivalent: "h") { [weak self] in
            self?.layout.toggle(.hidden)
        })

        let hoverItem = NSMenuItem(
            title: Localization.tr(.showOnHover),
            action: #selector(toggleHoverReveal),
            keyEquivalent: ""
        )
        hoverItem.target = self
        hoverItem.state = hover.isEnabled ? .on : .off
        menu.addItem(hoverItem)

        let loginItem = NSMenuItem(
            title: Localization.tr(.launchAtLogin),
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LaunchAtLoginService.shared.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(ClosureMenuItem(title: Localization.tr(.restoreAllIcons)) { [weak self] in
            self?.layout.resetAll()
        })

        menu.addItem(.separator())

        let itemsMenu = NSMenu()
        if items.isEmpty {
            let empty = NSMenuItem(title: Localization.tr(.noItemsFound), action: nil, keyEquivalent: "")
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
            title: Localization.tr(.iconsCount, visibleCount, items.count),
            action: nil,
            keyEquivalent: ""
        )
        itemsParent.submenu = itemsMenu
        menu.addItem(itemsParent)

        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem(
            title: permissions.accessibility
                ? Localization.tr(.accessibilityOk)
                : Localization.tr(.accessibilityMissing)
        ) { [weak self] in
            self?.permissions.requestAccessibility()
        })

        menu.addItem(ClosureMenuItem(
            title: permissions.screenRecording
                ? Localization.tr(.screenRecordingOk)
                : Localization.tr(.screenRecordingMissing)
        ) { [weak self] in
            self?.permissions.requestScreenRecording()
        })

        menu.addItem(.separator())

        // Язык / Language
        let languageMenu = NSMenu()
        for lang in AppLanguage.allCases {
            let langItem = NSMenuItem(title: lang.displayName, action: #selector(languageSelected(_:)), keyEquivalent: "")
            langItem.target = self
            langItem.representedObject = lang
            langItem.state = (Localization.shared.current == lang) ? .on : .off
            languageMenu.addItem(langItem)
        }
        let languageParent = NSMenuItem(
            title: "\(Localization.tr(.language)): \(Localization.shared.current.displayName)",
            action: nil,
            keyEquivalent: ""
        )
        languageParent.submenu = languageMenu
        menu.addItem(languageParent)

        // Стиль иконки BarKeep
        let iconStyleMenu = NSMenu()
        for style in ControlIconStyle.allCases {
            let styleItem = NSMenuItem(title: style.title, action: #selector(iconStyleSelected(_:)), keyEquivalent: "")
            styleItem.target = self
            styleItem.representedObject = style
            styleItem.state = (layout.currentIconStyle == style) ? .on : .off
            iconStyleMenu.addItem(styleItem)
        }
        let iconStyleParent = NSMenuItem(
            title: Localization.tr(.iconStyle),
            action: nil,
            keyEquivalent: ""
        )
        iconStyleParent.submenu = iconStyleMenu
        menu.addItem(iconStyleParent)

        menu.addItem(ClosureMenuItem(title: Localization.tr(.copyReport)) { [weak self] in
            self?.copyReport()
        })
        menu.addItem(ClosureMenuItem(title: Localization.tr(.openLog)) {
            Log.revealInFinder()
        })

        menu.addItem(ClosureMenuItem(title: Localization.tr(.preferences), keyEquivalent: ",") { [weak self] in
            self?.openSettings()
        })

        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: Localization.tr(.quitApp)) {
            NSApp.terminate(nil)
        })
    }

    private func openSettings() {
        SettingsWindowController.show(permissions: permissions, layout: layout, hover: hover)
    }

    @objc private func languageSelected(_ sender: NSMenuItem) {
        guard let lang = sender.representedObject as? AppLanguage else { return }
        Localization.shared.setLanguage(lang)
    }

    @objc private func iconStyleSelected(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? ControlIconStyle else { return }
        layout.currentIconStyle = style
        rebuild(menu)
    }

    @objc private func toggleHoverReveal() {
        let key = "BarKeepHoverReveal"
        let current = UserDefaults.standard.object(forKey: key) as? Bool ?? false
        UserDefaults.standard.set(!current, forKey: key)
        if !current {
            hover.start()
        } else {
            hover.stop()
        }
        rebuild(menu)
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLoginService.shared.toggle()
        rebuild(menu)
    }

    private func activate(_ item: MenuBarItem) {
        Log.info("Активация: \(item.displayName)")
        // Даём нашему меню закрыться, иначе чужая иконка не откроет своё меню.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.activation.activate(item)
        }
    }

    private func copyReport() {
        let hiddenState = layout.isHiddenSectionCollapsed
            ? Localization.tr(.reportStateShown)
            : Localization.tr(.reportStateHidden)
        let alwaysHiddenState = layout.isAlwaysHiddenSectionCollapsed
            ? Localization.tr(.reportStateShown)
            : Localization.tr(.reportStateHidden)

        var lines: [String] = [
            "BarKeep \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")",
            "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)",
            AppEnvironment.summary,
            Localization.tr(.reportItems, items.count),
            "\(Localization.tr(.reportHidden, hiddenState)), \(Localization.tr(.reportAlwaysHidden, alwaysHiddenState))",
        ]
        if let hidden = layout.hiddenFrame, let alwaysHidden = layout.alwaysHiddenFrame {
            lines.append(Localization.tr(.reportDividers, Int(hidden.minX), Int(alwaysHidden.minX)))
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
        Log.info(Localization.tr(.reportCopied, items.count))
    }
}
