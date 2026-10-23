import AppKit

/// Активация иконок: видимые нажимаем сразу, скрытые — временно возвращаем в меню-бар.
@MainActor
final class ItemActivationService {
    private let layout: MenuBarLayoutController
    private let scanner: MenuBarItemScanner
    private var rehideWorkItem: DispatchWorkItem?

    /// Через сколько секунд возвращать иконки обратно после временного показа.
    var autoHideDelay: TimeInterval = 2.5

    init(layout: MenuBarLayoutController, scanner: MenuBarItemScanner) {
        self.layout = layout
        self.scanner = scanner
    }

    func activate(_ item: MenuBarItem, button: ItemActivator.Button = .left) {
        let section = layout.section(forX: item.frame.minX)

        guard section != .visible else {
            ItemActivator.activate(item, button: button)
            return
        }

        // Если скрытая секция уже развернута пользователем, активируем без автоскрытия
        if section == .hidden, layout.isHiddenSectionCollapsed {
            ItemActivator.activate(item, button: button)
            return
        }

        Log.info("Временный показ секции \(section.title) для \(item.displayName)")
        layout.show(section)
        scheduleAutoHide(section, extraDelay: 1.0)
        waitUntilVisible(windowID: item.windowID, fallback: item, button: button, attempt: 0)
    }

    /// Пересчёт раскладки после изменения длины разделителя занимает до ~1.5 с.
    /// Ждём, пока иконка окажется на экране, иначе меню откроется за краем.
    private func waitUntilVisible(
        windowID: CGWindowID,
        fallback: MenuBarItem,
        button: ItemActivator.Button,
        attempt: Int
    ) {
        guard attempt < 30 else {
            Log.warning("Иконка не вернулась на экран, нажимаем как есть: \(fallback.displayName)")
            ItemActivator.activate(fallback, button: button)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            if let refreshed = self.scanner.scan().first(where: { $0.windowID == windowID }),
               refreshed.frame.maxX > 1 {
                if attempt > 0 {
                    Log.info("Иконка на экране через \(attempt * 100) мс")
                }
                ItemActivator.activate(refreshed, button: button)
                return
            }
            self.waitUntilVisible(windowID: windowID, fallback: fallback, button: button, attempt: attempt + 1)
        }
    }

    /// Показать секцию вручную (без клика) и запустить автоскрытие.
    func showTemporarily(_ section: MenuBarLayoutController.Section) {
        layout.show(section)
        scheduleAutoHide(section)
    }

    func cancelAutoHide() {
        rehideWorkItem?.cancel()
        rehideWorkItem = nil
    }

    private func scheduleAutoHide(_ section: MenuBarLayoutController.Section, extraDelay: TimeInterval = 0) {
        rehideWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            // Не скрываем секцию, пока пользователь держит курсор в меню-баре
            let mouse = NSEvent.mouseLocation
            if let screen = NSScreen.screens.first(where: { NSPointInRect(mouse, $0.frame) }) {
                let menuBarHeight = max(24, screen.frame.maxY - screen.visibleFrame.maxY)
                if mouse.y >= screen.frame.maxY - menuBarHeight - 1 {
                    self.scheduleAutoHide(section, extraDelay: 2.0)
                    return
                }
            }
            self.layout.hide(section)
            Log.info("Автоскрытие секции \(section.title)")
        }
        rehideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + autoHideDelay + extraDelay, execute: workItem)
    }
}
