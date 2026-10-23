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
            let lang = UserDefaults.standard.string(forKey: "BarKeepAppLanguage")
                .flatMap(AppLanguage.init(rawValue:)) ?? .defaultLanguage
            return Self.localizedControlCenterName(for: title ?? "", language: lang) ?? ownerName
        }
        if ownerPID == 0, let title, !title.isEmpty { return title }
        if let title, !title.isEmpty, title != "Item-0", title != "Item-1" {
            return "\(ownerName) — \(title)"
        }
        return ownerName
    }

    private static func localizedControlCenterName(for key: String, language: AppLanguage) -> String? {
        let names: [AppLanguage: [String: String]] = [
            .en: [
                "BentoBox": "Control Center",
                "Clock": "Clock",
                "WiFi": "Wi-Fi",
                "Bluetooth": "Bluetooth",
                "Sound": "Sound",
                "Display": "Display",
                "NowPlaying": "Now Playing",
                "ScreenMirroring": "Screen Mirroring",
                "AccessibilityShortcuts": "Accessibility",
                "StageManager": "Stage Manager",
                "FocusModes": "Focus",
                "KeyboardBrightness": "Keyboard Brightness",
                "Hearing": "Hearing",
            ],
            .ru: [
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
            ],
            .kk: [
                "BentoBox": "Басқару орталығы",
                "Clock": "Сағат",
                "WiFi": "Wi-Fi",
                "Bluetooth": "Bluetooth",
                "Sound": "Дыбыс",
                "Display": "Дисплей",
                "NowPlaying": "Қазір ойнатылуда",
                "ScreenMirroring": "Экранды қайталау",
                "AccessibilityShortcuts": "Арнайы мүмкіндіктер",
                "StageManager": "Stage Manager",
                "FocusModes": "Фокустау режимдері",
                "KeyboardBrightness": "Пернетақта жарықтығы",
                "Hearing": "Есту",
            ],
            .zh: [
                "BentoBox": "控制中心",
                "Clock": "时钟",
                "WiFi": "Wi-Fi",
                "Bluetooth": "蓝牙",
                "Sound": "声音",
                "Display": "显示器",
                "NowPlaying": "正在播放",
                "ScreenMirroring": "屏幕镜像",
                "AccessibilityShortcuts": "辅助功能快捷键",
                "StageManager": "台前调度",
                "FocusModes": "专注模式",
                "KeyboardBrightness": "键盘亮度",
                "Hearing": "听觉",
            ]
        ]
        return names[language]?[key] ?? names[.en]?[key]
    }

    static let controlCenterBundleIdentifier = "com.apple.controlcenter"
}
