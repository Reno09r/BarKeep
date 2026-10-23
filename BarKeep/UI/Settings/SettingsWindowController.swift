import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    static var shared: SettingsWindowController?

    static func show(
        permissions: PermissionsManager,
        layout: MenuBarLayoutController,
        hover: HoverRevealController
    ) {
        if let existing = shared, let window = existing.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView(permissions: permissions, layout: layout, hover: hover)
        let hosting = NSHostingView(rootView: view)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "BarKeep — " + Localization.tr(.preferences).replacingOccurrences(of: "…", with: "")
        window.contentView = hosting
        window.isReleasedWhenClosed = false

        let controller = SettingsWindowController(window: window)
        shared = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
