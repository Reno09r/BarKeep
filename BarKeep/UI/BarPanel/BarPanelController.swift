import AppKit
import SwiftUI

/// Панель под меню-баром со скрытыми иконками (аналог Bartender Bar).
@MainActor
final class BarPanelController {
    private var panel: NSPanel?
    private var clickMonitor: Any?
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
        close()

        items = scanner.scan().filter { item in
            guard !item.isOwnItem else { return false }
            return layout.section(forX: item.frame.minX) != .visible
        }

        guard !items.isEmpty else {
            NSSound.beep()
            Log.info("Панель: скрытых иконок нет")
            return
        }

        images.invalidate()

        let size = panelSize()
        let view = BarPanelView(
            items: items,
            imageProvider: { [weak self] item in self?.images.image(for: item) },
            onActivate: { [weak self] item in
                self?.close()
                self?.activation.activate(item)
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

        let panel = NSPanel(
            contentRect: NSRect(origin: origin(for: size), size: size),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = container
        panel.isFloatingPanel = true
        panel.level = .mainMenu + 1
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.animationBehavior = .utilityWindow
        panel.collectionBehavior = [.fullScreenAuxiliary, .ignoresCycle, .moveToActiveSpace, .transient]
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.orderFrontRegardless()
        panel.makeKey()

        self.panel = panel
        NSApp.activate(ignoringOtherApps: true)

        // Клик вне панели закрывает её (но не тот клик, которым её открыли).
        openedAt = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.panel != nil else { return }
            self.clickMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [weak self] _ in
                guard let self, Date().timeIntervalSince(self.openedAt) > 0.4 else { return }
                DispatchQueue.main.async { self.close() }
            }
        }

        Log.info("Панель открыта: \(items.count) иконок, размер \(Int(size.width))x\(Int(size.height))")
    }

    func close() {
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
        panel?.orderOut(nil)
        panel = nil
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
