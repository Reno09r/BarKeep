import AppKit

/// Пункт меню, выполняющий замыкание.
final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(title: String, keyEquivalent: String = "", handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: nil, keyEquivalent: keyEquivalent)
        target = self
        action = #selector(fire)
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    @objc private func fire() {
        handler()
    }
}
