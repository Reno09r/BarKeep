import AppKit

/// Один элемент меню-бара, найденный через CGWindowList (+ Accessibility, если доступна).
struct MenuBarItem: Identifiable {
    let windowID: CGWindowID
    let ownerPID: pid_t
    let ownerName: String
    let bundleIdentifier: String?
    let title: String?
    let frame: CGRect
    let isOnScreen: Bool
    let axElement: AXUIElement?
    var displaySuffix: String = ""

    var id: CGWindowID { windowID }

    /// Иконка уехала за левый край экрана (скрыта нами или другим менеджером).
    var isOffscreen: Bool { frame.maxX <= 1 }

    var isOwnItem: Bool { bundleIdentifier == Bundle.main.bundleIdentifier }

    var displayName: String {
        let base = underlyingDisplayName
        return displaySuffix.isEmpty ? base : base + displaySuffix
    }

    private var underlyingDisplayName: String {
        if isOwnItem { return "BarKeep" }
        if bundleIdentifier == "com.apple.controlcenter" {
            return Self.controlCenterNames[title ?? ""] ?? ownerName
        }
        if ownerPID == 0, let title, !title.isEmpty { return title }
        if let title, !title.isEmpty, title != "Item-0", title != "Item-1" {
            return "\(ownerName) — \(title)"
        }
        return ownerName
    }

    private static let controlCenterNames: [String: String] = [
        "BentoBox": "Пункт управления",
        "Clock": "Часы",
        "WiFi": "Wi-Fi",
        "Bluetooth": "Bluetooth",
        "Sound": "Звук",
        "Display": "Дисплей",
        "NowPlaying": "Сейчас играет",
        "ScreenMirroring": "Повтор экрана",
        "AccessibilityShortcuts": "Универсальный доступ",
        "StageManager": "Stage Manager",
        "FocusModes": "Режимы фокусировки",
        "KeyboardBrightness": "Яркость клавиатуры",
        "Hearing": "Слух",
    ]

    static let controlCenterBundleIdentifier = "com.apple.controlcenter"
}
