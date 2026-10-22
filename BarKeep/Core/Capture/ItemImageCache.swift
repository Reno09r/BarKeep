import AppKit

/// Кеш картинок иконок меню-бара.
///
/// Скрытые иконки находятся за краем экрана, поэтому рисуем их по снимку окна.
/// Если снимок недоступен (нет Screen Recording), показываем иконку приложения.
@MainActor
final class ItemImageCache {
    private var cache: [CGWindowID: NSImage] = [:]
    private var failed: Set<CGWindowID> = []

    func image(for item: MenuBarItem) -> NSImage? {
        if let image = cache[item.windowID] { return image }
        guard !failed.contains(item.windowID) else { return fallbackImage(for: item) }
        guard let cgImage = Self.capture(windowID: item.windowID) else {
            failed.insert(item.windowID)
            return fallbackImage(for: item)
        }
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        cache[item.windowID] = image
        return image
    }

    func invalidate() {
        cache.removeAll()
        failed.removeAll()
    }

    func invalidate(item: MenuBarItem) {
        cache[item.windowID] = nil
    }

    private func fallbackImage(for item: MenuBarItem) -> NSImage? {
        guard let app = NSRunningApplication(processIdentifier: item.ownerPID) else { return nil }
        if let url = app.bundleURL {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 32, height: 32)
            return icon
        }
        return NSImage(systemSymbolName: "app.dashed", accessibilityDescription: item.displayName)
    }

    /// Снимок окна иконки. Устаревший API, но он единственный умеет снимать окна за краем экрана.
    private static func capture(windowID: CGWindowID) -> CGImage? {
        let windows = [windowID] as CFArray
        return CGImage(
            windowListFromArrayScreenBounds: .null,
            windowArray: windows,
            imageOption: [.boundsIgnoreFraming, .bestResolution]
        )
    }
}
