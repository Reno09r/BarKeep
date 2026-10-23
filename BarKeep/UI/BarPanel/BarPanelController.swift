import AppKit
import SwiftUI

/// Панель под меню-баром со скрытыми иконками (аналог Bartender Bar).
@MainActor
final class BarPanelController {
    private var panel: BarPanelWindow?
    private var clickMonitor: Any?
    private var keyMonitor: Any?
    private var previousApp: NSRunningApplication?
    private let layout: MenuBarLayoutController
    private let scanner: MenuBarItemScanner
    private let activation: ItemActivationService
    private let images = ItemImageCache()

    private var items: [MenuBarItem] = []
    private var openedAt = Date.distantPast

    init(layout: MenuBarLayoutController, scanner: MenuBarItemScanner, activation: ItemActivationService) {
        self.layout = layout
        self.scanner = scanner
        self.activation = activation
    }

    var isVisible: Bool { panel?.isVisible == true }

    func toggle() {
        isVisible ? close() : show()
    }

    func show() {
        close(restoreFocus: false)

        items = scanner.scan().filter { item in
            guard !item.isOwnItem else { return false }
            return layout.section(forX: item.frame.minX) != .visible
        }

        guard !items.isEmpty else {
            NSSound.beep()
            Log.info("Панель: скрытых иконок нет")
            return
        }

        let frontmost = NSWorkspace.shared.frontmostApplication
        previousApp = frontmost?.bundleIdentifier == Bundle.main.bundleIdentifier ? nil : frontmost

        images.invalidate()

        let size = panelSize()
        let view = BarPanelView(
            items: items,
            imageProvider: { [weak self] item in self?.images.image(for: item) },
            onActivate: { [weak self] item in
                self?.close(restoreFocus: false)
                self?.activation.activate(item)
            },
            onHideApp: { [weak self] item in
                self?.hideApp(item)
            },
            onQuitApp: { [weak self] item, force in
                self?.quitApp(item, force: force)
            },
            onClose: { [weak self] in self?.close() }
        )

        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(origin: .zero, size: size)
        hosting.autoresizingMask = [.width, .height]
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor

        // Материал рисует отдельный NSVisualEffectView: SwiftUI-материал
        // в прозрачной borderless-панели может не отрисовываться.
        let container = NSView(frame: NSRect(origin: .zero, size: size))
        container.wantsLayer = true
        container.layer?.cornerRadius = 14
        container.layer?.masksToBounds = true
        container.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.94).cgColor
        let effect = NSVisualEffectView(frame: container.bounds)
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.autoresizingMask = [.width, .height]
        container.addSubview(effect)
        container.addSubview(hosting)

        let panel = BarPanelWindow(
            contentRect: NSRect(origin: origin(for: size), size: size),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = container
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.level = .mainMenu + 1
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.animationBehavior = .utilityWindow
        panel.collectionBehavior = [.fullScreenAuxiliary, .ignoresCycle, .moveToActiveSpace, .transient]
        panel.isMovable = false
        panel.hidesOnDeactivate = false

        self.panel = panel

        // Сначала активируем приложение, затем делаем панель key — иначе
        // клавиатура остаётся у предыдущего приложения.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self, let panel = self.panel else { return }
            Log.info("Панель: key=\(panel.isKeyWindow), active=\(NSApp.isActive)")
        }

        // Esc закрывает панель, даже если фокус ушёл с поля поиска.
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated {
                guard let self, event.window === self.panel else { return event }
                if event.keyCode == 53 {
                    self.close()
                    return nil
                }
                return event
            }
        }

        // Клик вне панели закрывает её (но не тот клик, которым её открыли).
        openedAt = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.panel != nil else { return }
            self.clickMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, Date().timeIntervalSince(self.openedAt) > 0.4 else { return }
                    if ProcessInfo.processInfo.environment["BARKEEP_PANEL_STICKY"] == "1" { return }
                    self.close()
                }
            }
        }

        Log.info("Панель открыта: \(items.count) иконок, размер \(Int(size.width))x\(Int(size.height))")
    }

    func close(restoreFocus: Bool = true) {
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if panel != nil {
            Log.info("Панель закрыта")
        }
        panel?.orderOut(nil)
        panel = nil

        let target = previousApp
        previousApp = nil
        guard restoreFocus, let target,
              target.bundleIdentifier != Bundle.main.bundleIdentifier,
              !target.isTerminated
        else { return }

        DispatchQueue.main.async {
            _ = target.activate(options: [])
        }
    }

    // MARK: - Действия с приложением иконки

    private func quitApp(_ item: MenuBarItem, force: Bool) {
        guard let app = AppTerminator.target(for: item) else {
            NSSound.beep()
            return
        }
        let name = app.localizedName ?? item.ownerName

        let alert = NSAlert()
        alert.messageText = force
            ? Localization.tr(.alertForceQuitTitle, name)
            : Localization.tr(.alertQuitTitle, name)
        alert.informativeText = force
            ? Localization.tr(.alertForceQuitMessage)
            : Localization.tr(.alertQuitMessage)
        alert.alertStyle = .warning
        alert.addButton(withTitle: force ? Localization.tr(.buttonForceQuit) : Localization.tr(.buttonQuit))
        alert.addButton(withTitle: Localization.tr(.buttonCancel))

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            panel?.makeKeyAndOrderFront(nil)
            return
        }

        Log.info("Завершение приложения: \(name) (принудительно: \(force))")
        if AppTerminator.terminate(item: item, force: force) {
            close()
        } else {
            Log.warning("Не удалось завершить \(name)")
            NSSound.beep()
            panel?.makeKeyAndOrderFront(nil)
        }
    }

    private func hideApp(_ item: MenuBarItem) {
        let name = AppTerminator.displayName(for: item)
        Log.info("Скрытие приложения: \(name)")
        AppTerminator.hide(item: item)
        close()
    }

    // MARK: - Геометрия

    private func panelSize() -> NSSize {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let available = screen.frame.width - 80
        let iconsWidth = CGFloat(min(items.count, 14)) * 38 + 24
        let width = min(available, max(340, iconsWidth + 190))
        return NSSize(width: width, height: 56)
    }

    private func origin(for size: NSSize) -> NSPoint {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let x = screen.frame.maxX - size.width - 12
        let y = screen.frame.maxY - ItemActivator.menuBarHeight - size.height - 8
        return NSPoint(x: x, y: y)
    }
}
