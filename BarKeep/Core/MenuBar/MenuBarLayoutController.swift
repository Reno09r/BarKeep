import AppKit

/// Управляет тремя секциями меню-бара.
///
/// Схема (справа налево):
///   [системные иконки] [BarKeep] [видимые] | разделитель скрытых | [скрытые]
///   | разделитель всегда-скрытых | [всегда скрытые]
///
/// Скрытие — раздувание разделителя до 10 000 px: всё левее уезжает за край экрана.
@MainActor
final class MenuBarLayoutController {
    enum Section: String, CaseIterable {
        case visible
        case hidden
        case alwaysHidden

        var title: String {
            switch self {
            case .visible: "Видимые"
            case .hidden: "Скрытые"
            case .alwaysHidden: "Всегда скрытые"
            }
        }
    }

    static let collapsedLength: CGFloat = 10
    static let expandedLength: CGFloat = 10_000

    let controlItem: NSStatusItem
    private let hiddenDivider: NSStatusItem
    private let alwaysHiddenDivider: NSStatusItem

    private(set) var isHiddenSectionCollapsed = false
    private(set) var isAlwaysHiddenSectionCollapsed = false

    /// Секция «всегда скрытые» требует ручного перемещения иконок за её границу.
    /// Пока перемещение недоступно, секция выключена и не влияет на классификацию.
    private(set) var isAlwaysHiddenEnabled = false

    init() {
        Self.installPreferredPositionsIfNeeded()

        controlItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        controlItem.autosaveName = "BKControl"
        if let button = controlItem.button {
            let image = NSImage(systemSymbolName: "menubar.rectangle", accessibilityDescription: "BarKeep")
            image?.isTemplate = true
            button.image = image
            if button.image == nil { button.title = "BK" }
            button.toolTip = "BarKeep"
        }

        hiddenDivider = NSStatusBar.system.statusItem(withLength: Self.collapsedLength)
        hiddenDivider.autosaveName = "BKHidden"
        Self.configureDivider(hiddenDivider)

        alwaysHiddenDivider = NSStatusBar.system.statusItem(withLength: 1)
        alwaysHiddenDivider.autosaveName = "BKAlwaysHidden"
        Self.configureInactiveDivider(alwaysHiddenDivider)

        logFrames("после создания")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.logFrames("через 1 секунду")
        }
    }

    /// Стартовое состояние: скрытые и всегда-скрытые уезжают за край.
    /// Вызывается только при выданном Accessibility — иначе легко оставить пользователя без иконок.
    func applyDefaultState() {
        hide(.hidden)
    }

    // MARK: - Управление секциями

    func show(_ section: Section) {
        switch section {
        case .visible:
            return
        case .hidden:
            isHiddenSectionCollapsed = true
            hiddenDivider.length = Self.collapsedLength
        case .alwaysHidden:
            isHiddenSectionCollapsed = true
            isAlwaysHiddenSectionCollapsed = true
            hiddenDivider.length = Self.collapsedLength
            alwaysHiddenDivider.length = Self.collapsedLength
        }
        Log.info("Показана секция: \(section.title)")
    }

    func hide(_ section: Section) {
        switch section {
        case .visible:
            return
        case .hidden:
            isHiddenSectionCollapsed = false
            hiddenDivider.length = Self.expandedLength
        case .alwaysHidden:
            isAlwaysHiddenSectionCollapsed = false
            alwaysHiddenDivider.length = Self.expandedLength
        }
        Log.info("Скрыта секция: \(section.title)")
    }

    func resetAll() {
        Log.warning("Аварийный возврат всех иконок")
        isHiddenSectionCollapsed = true
        isAlwaysHiddenSectionCollapsed = true
        hiddenDivider.length = Self.collapsedLength
        alwaysHiddenDivider.length = Self.collapsedLength
    }

    func toggle(_ section: Section) {
        switch section {
        case .visible:
            return
        case .hidden:
            isHiddenSectionCollapsed ? hide(.hidden) : show(.hidden)
        case .alwaysHidden:
            isAlwaysHiddenSectionCollapsed ? hide(.alwaysHidden) : show(.alwaysHidden)
        }
    }

    // MARK: - Геометрия

    /// Границы разделителей в координатах экрана (x совпадает у Cocoa и CGWindowList).
    var thresholds: (hiddenMinX: CGFloat?, alwaysHiddenMinX: CGFloat?) {
        (hiddenFrame?.minX, alwaysHiddenFrame?.minX)
    }

    var hiddenFrame: CGRect? { screenFrame(of: hiddenDivider) }
    var alwaysHiddenFrame: CGRect? { screenFrame(of: alwaysHiddenDivider) }
    var controlFrame: CGRect? { screenFrame(of: controlItem) }

    /// `window.frame` у статус-элементов отдаёт локальные координаты, поэтому конвертируем кнопку в экранные.
    private func screenFrame(of item: NSStatusItem) -> CGRect? {
        guard let button = item.button, let window = button.window else { return nil }
        return window.convertToScreen(button.convert(button.bounds, to: nil))
    }

    func section(forX x: CGFloat) -> Section {
        guard let hiddenMinX = hiddenFrame?.minX else { return .visible }
        if x > hiddenMinX { return .visible }
        guard isAlwaysHiddenEnabled, let alwaysHiddenMinX = alwaysHiddenFrame?.minX else { return .hidden }
        return x < alwaysHiddenMinX ? .alwaysHidden : .hidden
    }

    private func logFrames(_ context: String) {
        func describe(_ frame: CGRect?) -> String {
            guard let frame else { return "нет окна" }
            return String(format: "x=%.0f..%.0f (w=%.0f)", frame.minX, frame.maxX, frame.width)
        }
        Log.info("""
        Разделители \(context): \
        control=\(describe(controlFrame)) \
        hidden=\(describe(hiddenFrame)) \
        alwaysHidden=\(describe(alwaysHiddenFrame))
        """)
    }

    // MARK: - Настройка

    private static func configureDivider(_ item: NSStatusItem) {
        item.button?.image = dividerImage()
        item.button?.toolTip = "Граница секции BarKeep — перетащите иконки через неё с ⌘"
    }

    /// Невидимый разделитель для пока не используемой секции.
    private static func configureInactiveDivider(_ item: NSStatusItem) {
        let image = NSImage(size: NSSize(width: 1, height: 1), flipped: false) { _ in true }
        image.isTemplate = true
        item.button?.image = image
    }

    /// Тонкая вертикальная черта — видимая граница секции.
    private static func dividerImage() -> NSImage {
        let size = NSSize(width: 11, height: 16)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.secondaryLabelColor.withAlphaComponent(0.5).setFill()
            NSRect(x: rect.midX - 0.5, y: 2, width: 1, height: rect.height - 4).fill()
            return true
        }
        image.isTemplate = true
        return image
    }

    /// Позиции задаются ключами, которые читает AppKit при создании статус-элемента.
    /// Значение — отступ в точках от правого края экрана.
    private static func installPreferredPositionsIfNeeded() {
        let defaults = UserDefaults.standard
        let versionKey = "BarKeepLayoutVersion"
        let controlKey = "NSStatusItem Preferred Position BKControl"
        let hiddenKey = "NSStatusItem Preferred Position BKHidden"
        let alwaysKey = "NSStatusItem Preferred Position BKAlwaysHidden"

        if defaults.object(forKey: controlKey) == nil {
            defaults.set(0.0, forKey: controlKey)
        }
        if defaults.integer(forKey: versionKey) < 4 {
            // Граница видимых: справа остаются ~3 иконки (x ≈ 1220).
            defaults.set(500.0, forKey: hiddenKey)
            defaults.set(1600.0, forKey: alwaysKey)
            defaults.set(4, forKey: versionKey)
        }
    }
}
