import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static var shared: SettingsWindowController?

    private let permissions: PermissionsManager

    init(window: NSWindow, permissions: PermissionsManager) {
        self.permissions = permissions
        super.init(window: window)
        window.delegate = self

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .appLanguageDidChange,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func languageDidChange() {
        window?.title = "BarKeep — " + Localization.tr(.preferences).replacingOccurrences(of: "…", with: "")
    }

    func windowDidBecomeKey(_ notification: Notification) {
        permissions.refresh(force: true)
    }

    static func show(
        permissions: PermissionsManager,
        layout: MenuBarLayoutController,
        hover: HoverRevealController
    ) {
        if let existing = shared, let window = existing.window {
            permissions.refresh(force: true)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView(permissions: permissions, layout: layout, hover: hover)
        let hosting = NSHostingView(rootView: view)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 460),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 620, height: 420)
        window.center()
        window.title = "BarKeep — " + Localization.tr(.preferences).replacingOccurrences(of: "…", with: "")
        window.contentView = hosting
        window.isReleasedWhenClosed = false

        let controller = SettingsWindowController(window: window, permissions: permissions)
        shared = controller
        window.makeKeyAndOrderFront(nil)
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
