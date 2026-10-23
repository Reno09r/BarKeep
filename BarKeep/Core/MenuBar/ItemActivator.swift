import AppKit

/// Активирует иконки меню-бара: сначала через Accessibility, затем координатным кликом.
@MainActor
enum ItemActivator {
    enum Button {
        case left
        case right
    }

    @discardableResult
    static func activate(_ item: MenuBarItem, button: Button = .left) -> Bool {
        if let element = item.axElement {
            let action = button == .left ? kAXPressAction : kAXShowMenuAction
            if AX.perform(element, action) {
                Log.info("AX \(button == .left ? "press" : "showMenu"): \(item.displayName)")
                return true
            }
            if button == .right, AX.perform(element, kAXPressAction) {
                Log.info("AX press (fallback для правого клика): \(item.displayName)")
                return true
            }
        }

        guard item.frame.maxX > 0 else {
            Log.warning("Нельзя кликнуть скрытую иконку без AX: \(item.displayName)")
            return false
        }

        let clickY = item.frame.midY > 0 ? item.frame.midY : (menuBarHeight / 2)
        click(at: CGPoint(x: item.frame.midX, y: clickY), button: button)
        Log.info("Координатный клик: \(item.displayName) @ (\(Int(item.frame.midX)), \(Int(clickY)))")
        return true
    }

    /// Высота меню-бара в логических пикселях (учитывает чёлку).
    static var menuBarHeight: CGFloat {
        guard let screen = NSScreen.main else { return 24 }
        return max(24, screen.frame.maxY - screen.visibleFrame.maxY)
    }

    private static func click(at point: CGPoint, button: Button) {
        let saved = CGEvent(source: nil)?.location ?? point
        let mouseButton: CGMouseButton = button == .left ? .left : .right
        let downType: CGEventType = button == .left ? .leftMouseDown : .rightMouseDown
        let upType: CGEventType = button == .left ? .leftMouseUp : .rightMouseUp

        DispatchQueue.global(qos: .userInteractive).async {
            func post(_ type: CGEventType, _ location: CGPoint) {
                guard let event = CGEvent(
                    mouseEventSource: nil,
                    mouseType: type,
                    mouseCursorPosition: location,
                    mouseButton: mouseButton
                ) else { return }
                event.setIntegerValueField(.mouseEventClickState, value: 1)
                event.post(tap: .cghidEventTap)
            }

            // При автоскрытии меню-бара сначала «выводим» его курсором к верхней кромке.
            post(.mouseMoved, CGPoint(x: point.x, y: max(1, point.y - 10)))
            usleep(350_000)
            post(.mouseMoved, point)
            usleep(120_000)
            post(downType, point)
            usleep(90_000)
            post(upType, point)
            usleep(200_000)
            post(.mouseMoved, saved)
        }
    }
}
