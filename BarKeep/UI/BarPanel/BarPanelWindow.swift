import AppKit

/// Панель, которая может получать клавиатурный ввод.
///
/// У `NSPanel` со стилем `.borderless` по умолчанию `canBecomeKey == false`,
/// из-за чего поле поиска не получало текст.
final class BarPanelWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
