import AppKit

public enum ControlIconStyle: String, CaseIterable, Identifiable {
    case rectangle = "rectangle"
    case dots = "dots"
    case chevron = "chevron"
    case bar = "bar"
    case dash = "dash"

    public var id: String { rawValue }

    @MainActor
    public var localizedTitle: String {
        switch self {
        case .rectangle: return Localization.tr(.styleRectangle)
        case .dots: return Localization.tr(.styleDots)
        case .chevron: return Localization.tr(.styleChevron)
        case .bar: return Localization.tr(.styleBar)
        case .dash: return Localization.tr(.styleDash)
        }
    }

    public var title: String {
        switch self {
        case .rectangle: return "Rectangle (default)"
        case .dots: return "Dots (···)"
        case .chevron: return "Chevron (⟨)"
        case .bar: return "Bar (|)"
        case .dash: return "Dash (—)"
        }
    }

    public func image() -> NSImage? {
        let symbolName: String
        switch self {
        case .rectangle: symbolName = "menubar.rectangle"
        case .dots: symbolName = "ellipsis"
        case .chevron: symbolName = "chevron.left"
        case .bar: symbolName = "pipe"
        case .dash: symbolName = "minus"
        }

        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "BarKeep") {
            image.isTemplate = true
            return image
        }

        // Запасной вариант для текстовых символов
        let font = NSFont.systemFont(ofSize: 13, weight: .medium)
        let string: String
        switch self {
        case .rectangle: string = "BK"
        case .dots: string = "···"
        case .chevron: string = "⟨"
        case .bar: string = "|"
        case .dash: string = "—"
        }
        let attr = [NSAttributedString.Key.font: font, .foregroundColor: NSColor.labelColor]
        let size = (string as NSString).size(withAttributes: attr)
        let img = NSImage(size: NSSize(width: max(16, size.width + 4), height: 18), flipped: false) { rect in
            (string as NSString).draw(at: NSPoint(x: (rect.width - size.width) / 2, y: (rect.height - size.height) / 2), withAttributes: attr)
            return true
        }
        img.isTemplate = true
        return img
    }
}
