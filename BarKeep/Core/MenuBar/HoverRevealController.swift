import AppKit

/// Показ скрытых иконок при наведении на пустую часть меню-бара.
///
/// Иконки скрытой секции физически уезжают за левый край экрана, поэтому
/// «навести на иконку» нельзя. Вместо этого наведение на пустую зону меню-бара,
/// где скрытые иконки окажутся после показа, разворачивает секцию на месте.
@MainActor
final class HoverRevealController {
    private let layout: MenuBarLayoutController
    private var timer: Timer?
    private var revealedByHover = false
    private var leftBarAt: Date?

    /// Левая граница зоны наведения: левее находятся меню активного приложения.
    private let zoneMinX: CGFloat = 400
    private let hideDelay: TimeInterval = 0.7

    init(layout: MenuBarLayoutController) {
        self.layout = layout
    }

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "BarKeepHoverReveal") as? Bool ?? false
    }

    func start() {
        stop()
        let timer = Timer(timeInterval: 0.15, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Временно отключает реакцию на наведение (например, пока открыто меню).
    var isSuspended = false

    private func tick() {
        guard isEnabled, !isSuspended else { return }
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSPointInRect(mouse, $0.frame) }) else { return }

        let menuBarHeight = max(24, screen.frame.maxY - screen.visibleFrame.maxY)
        let barBottom = screen.frame.maxY - menuBarHeight
        let isInBar = mouse.y >= barBottom - 1

        guard isInBar else {
            guard revealedByHover else { return }
            if leftBarAt == nil { leftBarAt = Date() }
            if let leftBarAt, Date().timeIntervalSince(leftBarAt) >= hideDelay {
                layout.hide(.hidden)
                revealedByHover = false
                self.leftBarAt = nil
                Log.info("Скрытые иконки убраны после ухода курсора с меню-бара")
            }
            return
        }

        leftBarAt = nil

        // Секция уже показана — ничего не делаем, пока курсор в меню-баре.
        guard !layout.isHiddenSectionCollapsed else { return }

        let screenZoneMinX = screen.frame.minX + zoneMinX
        let rightEdge = layout.hiddenFrame?.maxX ?? screen.frame.maxX
        guard mouse.x > screenZoneMinX, mouse.x < rightEdge - 10 else { return }

        layout.show(.hidden)
        revealedByHover = true
        Log.info("Скрытые иконки показаны при наведении")
    }
}
