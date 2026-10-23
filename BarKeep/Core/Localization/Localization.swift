import Foundation
import Combine

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("BarKeepAppLanguageDidChange")
}

@MainActor
public final class Localization: ObservableObject {
    public static let shared = Localization()

    private static let userDefaultsKey = "BarKeepAppLanguage"

    @Published public private(set) var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: Self.userDefaultsKey)
            NotificationCenter.default.post(name: .appLanguageDidChange, object: current)
        }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: Self.userDefaultsKey),
           let lang = AppLanguage(rawValue: saved) {
            self.current = lang
        } else {
            self.current = .defaultLanguage
        }
        #if DEBUG
        for lang in AppLanguage.allCases {
            for key in Key.allCases {
                assert(Self.strings[lang]?[key] != nil, "Missing translation for \(lang.rawValue).\(key.rawValue)")
            }
        }
        #endif
    }

    public func setLanguage(_ language: AppLanguage) {
        guard language != current else { return }
        current = language
    }

    public static func tr(_ key: Key, _ args: CVarArg...) -> String {
        let format = strings[shared.current]?[key] ?? strings[.en]?[key] ?? key.rawValue
        if args.isEmpty {
            return format
        }
        return String(format: format, locale: Locale(identifier: shared.current.rawValue), arguments: args)
    }

    public enum Key: String, CaseIterable {
        case appVersion = "app_version"
        case conflictWarning = "conflict_warning"
        case hiddenPanel = "hidden_panel"
        case refreshList = "refresh_list"
        case hideHiddenIcons = "hide_hidden_icons"
        case showHiddenIcons = "show_hidden_icons"
        case showOnHover = "show_on_hover"
        case restoreAllIcons = "restore_all_icons"
        case iconsCount = "icons_count"
        case noItemsFound = "no_items_found"
        case accessibilityOk = "accessibility_ok"
        case accessibilityMissing = "accessibility_missing"
        case screenRecordingOk = "screen_recording_ok"
        case screenRecordingMissing = "screen_recording_missing"
        case copyReport = "copy_report"
        case openLog = "open_log"
        case language = "language"
        case quitApp = "quit_app"
        case launchAtLogin = "launch_at_login"
        case preferences = "preferences"
        case generalTab = "general_tab"
        case iconTab = "icon_tab"
        case permissionsTab = "permissions_tab"
        case aboutTab = "about_tab"
        case iconStyle = "icon_style"
        case alwaysHiddenEnabled = "always_hidden_enabled"

        case sectionVisible = "section_visible"
        case sectionHidden = "section_hidden"
        case sectionAlwaysHidden = "section_always_hidden"

        case searchPlaceholder = "search_placeholder"
        case activate = "activate"
        case hideAppName = "hide_app_name"
        case quitAppName = "quit_app_name"
        case forceQuitAppName = "force_quit_app_name"

        case alertQuitTitle = "alert_quit_title"
        case alertForceQuitTitle = "alert_force_quit_title"
        case alertQuitMessage = "alert_quit_message"
        case alertForceQuitMessage = "alert_force_quit_message"
        case buttonQuit = "button_quit"
        case buttonForceQuit = "button_force_quit"
        case buttonCancel = "button_cancel"
        case buttonOpenSettings = "button_open_settings"
        case buttonLater = "button_later"

        case onboardingAccessibilityTitle = "onboarding_accessibility_title"
        case onboardingAccessibilityMessage = "onboarding_accessibility_message"

        case reportCopied = "report_copied"
        case reportItems = "report_items"
        case reportHidden = "report_hidden"
        case reportAlwaysHidden = "report_always_hidden"
        case reportDividers = "report_dividers"
        case reportStateShown = "report_state_shown"
        case reportStateHidden = "report_state_hidden"

        case hotkeysTab = "hotkeys_tab"
        case launchAtLoginDesc = "launch_at_login_desc"
        case showOnHoverDesc = "show_on_hover_desc"
        case alwaysHiddenDesc = "always_hidden_desc"
        case languageDesc = "language_desc"
        case iconPreview = "icon_preview"
        case openHiddenPanel = "open_hidden_panel"
        case openHiddenPanelDesc = "open_hidden_panel_desc"
        case resetIconsDesc = "reset_icons_desc"
        case hotkeyPanelDesc = "hotkey_panel_desc"
        case hotkeyAlwaysHiddenDesc = "hotkey_always_hidden_desc"
        case hotkeyResetDesc = "hotkey_reset_desc"
        case hotkeyTip = "hotkey_tip"
        case accessibilityDesc = "accessibility_desc"
        case screenRecordingDesc = "screen_recording_desc"
        case statusGranted = "status_granted"
        case statusRequired = "status_required"
        case statusOptional = "status_optional"
        case checkPermissions = "check_permissions"
        case systemInfo = "system_info"
        case diagnosticsAndLogs = "diagnostics_and_logs"

        case generalSubheader = "general_subheader"
        case iconSubheader = "icon_subheader"
        case permissionsSubheader = "permissions_subheader"
        case menuBarHeight = "menubar_height"
        case conflictingApps = "conflicting_apps"
        case noConflictsDetected = "no_conflicts_detected"
        case copyReportDesc = "copy_report_desc"
        case copied = "copied"
        case copy = "copy"
        case openLogDesc = "open_log_desc"
        case open = "open"

        case styleRectangle = "style_rectangle"
        case styleDots = "style_dots"
        case styleChevron = "style_chevron"
        case styleBar = "style_bar"
        case styleDash = "style_dash"

        case statusItemTooltip = "status_item_tooltip"
        case resetAccessibility = "reset_accessibility"
        case resetAccessibilityDesc = "reset_accessibility_desc"
    }

    private static let strings: [AppLanguage: [Key: String]] = [
        .en: [
            .appVersion: "BarKeep %@",
            .conflictWarning: "⚠︎ %@ detected: conflicts possible",
            .hiddenPanel: "Hidden Icons Panel",
            .refreshList: "Refresh List",
            .hideHiddenIcons: "Hide Hidden Icons",
            .showHiddenIcons: "Show Hidden Icons",
            .showOnHover: "Show on Hover",
            .restoreAllIcons: "Restore All Icons",
            .iconsCount: "Icons: %d visible of %d",
            .noItemsFound: "No items found",
            .accessibilityOk: "Accessibility: ✓",
            .accessibilityMissing: "Accessibility: not granted — open Settings",
            .screenRecordingOk: "Screen Recording: ✓",
            .screenRecordingMissing: "Screen Recording: not granted — open Settings",
            .copyReport: "Copy Report to Clipboard",
            .openLog: "Open Log",
            .language: "Language",
            .quitApp: "Quit BarKeep",
            .launchAtLogin: "Launch at Login",
            .preferences: "Settings…",
            .generalTab: "General",
            .iconTab: "Menu Bar Icon",
            .permissionsTab: "Permissions",
            .aboutTab: "About",
            .iconStyle: "Icon Style",
            .alwaysHiddenEnabled: "Enable Always-Hidden Section",

            .sectionVisible: "Visible",
            .sectionHidden: "Hidden",
            .sectionAlwaysHidden: "Always Hidden",

            .searchPlaceholder: "Search",
            .activate: "Activate",
            .hideAppName: "Hide %@",
            .quitAppName: "Quit %@…",
            .forceQuitAppName: "Force Quit %@…",

            .alertQuitTitle: "Quit %@?",
            .alertForceQuitTitle: "Force Quit %@?",
            .alertQuitMessage: "The application will receive a standard termination request. Unsaved data may be lost.",
            .alertForceQuitMessage: "The application will close immediately without saving data.",
            .buttonQuit: "Quit",
            .buttonForceQuit: "Force Quit",
            .buttonCancel: "Cancel",
            .buttonOpenSettings: "Open Settings",
            .buttonLater: "Later",

            .onboardingAccessibilityTitle: "BarKeep Needs Accessibility Access",
            .onboardingAccessibilityMessage: "Without this permission, BarKeep cannot click or rearrange menu bar icons.\n\nOpen System Settings → Privacy & Security → Accessibility and enable BarKeep. Access will apply automatically once granted.",

            .reportCopied: "Report copied to clipboard (%d lines)",
            .reportItems: "Items: %d",
            .reportHidden: "Hidden: %@",
            .reportAlwaysHidden: "Always hidden: %@",
            .reportDividers: "Dividers: hidden.minX=%d alwaysHidden.minX=%d",
            .reportStateShown: "shown",
            .reportStateHidden: "hidden",

            .hotkeysTab: "Shortcuts",
            .launchAtLoginDesc: "Launch BarKeep automatically when logging in to your Mac",
            .showOnHoverDesc: "Reveal hidden menu bar icons when cursor hovers near the bar",
            .alwaysHiddenDesc: "Adds a secondary divider for icons you want to keep permanently hidden",
            .languageDesc: "Choose interface language for BarKeep",
            .iconPreview: "Menu Bar Preview",
            .openHiddenPanel: "Open Hidden Panel",
            .openHiddenPanelDesc: "Display floating panel containing all hidden icons",
            .resetIconsDesc: "Reset dividers and return all icons to default visible positions",
            .hotkeyPanelDesc: "Toggle hidden icons floating panel",
            .hotkeyAlwaysHiddenDesc: "Toggle always-hidden icons section",
            .hotkeyResetDesc: "Emergency restore of all menu bar icons",
            .hotkeyTip: "Global shortcuts work from any application in macOS.",
            .accessibilityDesc: "Required to inspect, arrange, and hide items in the macOS menu bar",
            .screenRecordingDesc: "Used to capture crisp thumbnails of icons for the hidden panel",
            .statusGranted: "Active",
            .statusRequired: "Action Required",
            .statusOptional: "Optional",
            .checkPermissions: "Check Permissions",
            .systemInfo: "System Information",
            .diagnosticsAndLogs: "Diagnostics & Logs",

            .generalSubheader: "Manage startup behavior, hover reveal, and language",
            .iconSubheader: "Menu bar icon style and quick actions",
            .permissionsSubheader: "macOS system permissions required for menu bar management",
            .menuBarHeight: "Menu bar height",
            .conflictingApps: "Conflicting utilities",
            .noConflictsDetected: "None detected",
            .copyReportDesc: "Copy system info, screen layout, and divider positions",
            .copied: "Copied!",
            .copy: "Copy",
            .openLogDesc: "Show BarKeep application log in Finder",
            .open: "Open",

            .styleRectangle: "Rectangle (default)",
            .styleDots: "Dots (···)",
            .styleChevron: "Chevron (⟨)",
            .styleBar: "Bar (|)",
            .styleDash: "Dash (—)",

            .statusItemTooltip: "BarKeep: Click to open icons panel; ⌘ + Drag to rearrange",
            .resetAccessibility: "Reset Permission",
            .resetAccessibilityDesc: "If BarKeep is already checked in System Settings, toggle it off and on or click here to reset"
        ],
        .ru: [
            .appVersion: "BarKeep %@",
            .conflictWarning: "⚠︎ Обнаружен %@: возможны конфликты",
            .hiddenPanel: "Панель скрытых",
            .refreshList: "Обновить список",
            .hideHiddenIcons: "Скрыть скрытые иконки",
            .showHiddenIcons: "Показать скрытые иконки",
            .showOnHover: "Показывать при наведении",
            .restoreAllIcons: "Вернуть все иконки",
            .iconsCount: "Иконки: видимых %d из %d",
            .noItemsFound: "Ничего не найдено",
            .accessibilityOk: "Accessibility: ✓",
            .accessibilityMissing: "Accessibility: не выдано — открыть настройки",
            .screenRecordingOk: "Запись экрана: ✓",
            .screenRecordingMissing: "Запись экрана: не выдано — открыть настройки",
            .copyReport: "Скопировать отчёт в буфер",
            .openLog: "Открыть журнал",
            .language: "Язык",
            .quitApp: "Выйти из BarKeep",
            .launchAtLogin: "Запуск при входе в систему",
            .preferences: "Настройки…",
            .generalTab: "Основные",
            .iconTab: "Иконка в меню",
            .permissionsTab: "Разрешения",
            .aboutTab: "О программе",
            .iconStyle: "Стиль иконки",
            .alwaysHiddenEnabled: "Включить секцию «Всегда скрытые»",

            .sectionVisible: "Видимые",
            .sectionHidden: "Скрытые",
            .sectionAlwaysHidden: "Всегда скрытые",

            .searchPlaceholder: "Поиск",
            .activate: "Активировать",
            .hideAppName: "Скрыть %@",
            .quitAppName: "Завершить %@…",
            .forceQuitAppName: "Завершить принудительно…",

            .alertQuitTitle: "Завершить %@?",
            .alertForceQuitTitle: "Принудительно завершить %@?",
            .alertQuitMessage: "Приложение получит обычный запрос на завершение. Несохранённые данные могут быть потеряны.",
            .alertForceQuitMessage: "Приложение будет закрыто сразу, без возможности сохранить данные.",
            .buttonQuit: "Завершить",
            .buttonForceQuit: "Завершить принудительно",
            .buttonCancel: "Отмена",
            .buttonOpenSettings: "Открыть настройки",
            .buttonLater: "Позже",

            .onboardingAccessibilityTitle: "BarKeep нужен доступ к Accessibility",
            .onboardingAccessibilityMessage: "Без этого разрешения BarKeep не сможет нажимать на иконки меню-бара и перемещать их.\n\nОткрой «Системные настройки → Конфиденциальность и безопасность → Accessibility» и включи BarKeep. После выдачи доступ применится автоматически.",

            .reportCopied: "Отчёт скопирован в буфер (%d строк)",
            .reportItems: "Элементов: %d",
            .reportHidden: "Скрытые: %@",
            .reportAlwaysHidden: "Всегда-скрытые: %@",
            .reportDividers: "Разделители: hidden.minX=%d alwaysHidden.minX=%d",
            .reportStateShown: "показаны",
            .reportStateHidden: "спрятаны",

            .hotkeysTab: "Горячие клавиши",
            .launchAtLoginDesc: "Автоматически запускать BarKeep при входе в систему",
            .showOnHoverDesc: "Раскрывать скрытые иконки при наведении курсора на меню-бар",
            .alwaysHiddenDesc: "Добавляет второй разделитель для иконок, которые всегда должны быть скрыты",
            .languageDesc: "Выберите язык интерфейса BarKeep",
            .iconPreview: "Предпросмотр в строке меню",
            .openHiddenPanel: "Открыть панель",
            .openHiddenPanelDesc: "Открыть плавающее окно со всеми скрытыми иконками",
            .resetIconsDesc: "Сбросить разделители и вернуть все иконки на исходные позиции",
            .hotkeyPanelDesc: "Открыть или закрыть панель скрытых иконок",
            .hotkeyAlwaysHiddenDesc: "Показать или спрятать секцию «Всегда скрытые»",
            .hotkeyResetDesc: "Аварийный возврат всех иконок меню-бара",
            .hotkeyTip: "Глобальные сочетания клавиш работают из любого приложения в macOS.",
            .accessibilityDesc: "Необходимо для считывания положения и скрытия иконок в меню-баре",
            .screenRecordingDesc: "Используется для захвата качественных миниатюр иконок сторонних программ",
            .statusGranted: "Активно",
            .statusRequired: "Требуется действие",
            .statusOptional: "Опционально",
            .checkPermissions: "Проверить статус",
            .systemInfo: "Информация о системе",
            .diagnosticsAndLogs: "Диагностика и журналы",

            .generalSubheader: "Управление автозапуском, поведением и языком",
            .iconSubheader: "Стиль иконки BarKeep в меню-баре и быстрые действия",
            .permissionsSubheader: "Системные доступы macOS для работы со строкой меню",
            .menuBarHeight: "Высота меню-бара",
            .conflictingApps: "Конфликтующие утилиты",
            .noConflictsDetected: "Не обнаружены",
            .copyReportDesc: "Скопировать системную информацию и состояние разделителей",
            .copied: "Скопировано!",
            .copy: "Скопировать",
            .openLogDesc: "Открыть файл журнала в Finder",
            .open: "Открыть",

            .styleRectangle: "Прямоугольник (по умолчанию)",
            .styleDots: "Точки (···)",
            .styleChevron: "Шеврон (⟨)",
            .styleBar: "Разделитель (|)",
            .styleDash: "Черта (—)",

            .statusItemTooltip: "BarKeep: клик — открыть панель иконок; ⌘ + перетаскивание — скрыть иконку",
            .resetAccessibility: "Сбросить разрешение",
            .resetAccessibilityDesc: "Если переключатель в Системных настройках уже включён, выключите и включите его снова или нажмите сброс"
        ],
        .kk: [
            .appVersion: "BarKeep %@",
            .conflictWarning: "⚠︎ %@ анықталды: қайшылықтар туындауы мүмкін",
            .hiddenPanel: "Жасырын белгішелер тақтасы",
            .refreshList: "Тізімді жаңарту",
            .hideHiddenIcons: "Жасырын белгішелерді тасалау",
            .showHiddenIcons: "Жасырын белгішелерді көрсету",
            .showOnHover: "Меңзерді апарғанда көрсету",
            .restoreAllIcons: "Барлық белгішелерді қайтару",
            .iconsCount: "Белгішелер: %d көрінеді, барлығы %d",
            .noItemsFound: "Ештеңе табылмады",
            .accessibilityOk: "Accessibility: ✓",
            .accessibilityMissing: "Accessibility: рұқсат берілмеген — баптауларды ашу",
            .screenRecordingOk: "Экранды жазу: ✓",
            .screenRecordingMissing: "Экранды жазу: рұқсат берілмеген — баптауларды ашу",
            .copyReport: "Есепті алмасу буферіне көшіру",
            .openLog: "Журналды ашу",
            .language: "Тіл",
            .quitApp: "BarKeep бағдарламасынан шығу",
            .launchAtLogin: "Жүйеге кіргенде іске қосу",
            .preferences: "Баптаулар…",
            .generalTab: "Негізгі",
            .iconTab: "Мәзір белгішесі",
            .permissionsTab: "Рұқсаттар",
            .aboutTab: "Бағдарлама туралы",
            .iconStyle: "Белгіше стилі",
            .alwaysHiddenEnabled: "«Әрқашан жасырын» бөлімін қосу",

            .sectionVisible: "Көрінетін",
            .sectionHidden: "Жасырын",
            .sectionAlwaysHidden: "Әрқашан жасырын",

            .searchPlaceholder: "Іздеу",
            .activate: "Іске қосу",
            .hideAppName: "%@ қолданбасын жасыру",
            .quitAppName: "%@ жұмысын аяқтау…",
            .forceQuitAppName: "%@ мәжбүрлі түрде аяқтау…",

            .alertQuitTitle: "%@ жұмысын аяқтау керек пе?",
            .alertForceQuitTitle: "%@ мәжбүрлі түрде аяқтау керек пе?",
            .alertQuitMessage: "Қолданбаға жұмысты аяқтау туралы стандартты сұрау жіберіледі. Сақталмаған деректер жоғалуы мүмкін.",
            .alertForceQuitMessage: "Қолданба дереу жабылады, деректерді сақтау мүмкіндігі болмайды.",
            .buttonQuit: "Аяқтау",
            .buttonForceQuit: "Мәжбүрлі аяқтау",
            .buttonCancel: "Болдырмау",
            .buttonOpenSettings: "Баптауларды ашу",
            .buttonLater: "Кейінірек",

            .onboardingAccessibilityTitle: "BarKeep бағдарламасына Accessibility рұқсаты қажет",
            .onboardingAccessibilityMessage: "Бұл рұқсатсыз BarKeep мәзір жолағының белгішелерін баса және жылжыта алмайды.\n\n«Жүйелік баптаулар → Құпиялылық және қауіпсіздік → Accessibility» тармағын ашып, BarKeep қосыңыз. Рұқсат берілгеннен кейін ол автоматты түрде іске қосылады.",

            .reportCopied: "Есеп алмасу буферіне көшірілді (%d жол)",
            .reportItems: "Элементтер: %d",
            .reportHidden: "Жасырын: %@",
            .reportAlwaysHidden: "Әрқашан жасырын: %@",
            .reportDividers: "Бөлгіштер: hidden.minX=%d alwaysHidden.minX=%d",
            .reportStateShown: "көрсетілген",
            .reportStateHidden: "жасырылған",

            .hotkeysTab: "Жылдам пернелер",
            .launchAtLoginDesc: "Жүйеге кіргенде BarKeep-ті автоматты түрде қосу",
            .showOnHoverDesc: "Меңзерді мәзір жолағына апарғанда жасырын белгішелерді көрсету",
            .alwaysHiddenDesc: "Әрқашан жасырын тұратын белгішелер үшін қосымша бөлгіш қосады",
            .languageDesc: "BarKeep интерфейс тілін таңдаңыз",
            .iconPreview: "Мәзір жолағында алдын ала көру",
            .openHiddenPanel: "Панельді ашу",
            .openHiddenPanelDesc: "Барлық жасырын белгішелері бар қалқымалы тақтаны көрсету",
            .resetIconsDesc: "Бөлгіштерді қалпына келтіріп, барлық белгішелерді бастапқы орнына қайтару",
            .hotkeyPanelDesc: "Жасырын белгішелер тақтасын ашу немесе жабу",
            .hotkeyAlwaysHiddenDesc: "«Әрқашан жасырын» бөлімін көрсету немесе тасалау",
            .hotkeyResetDesc: "Барлық белгішелерді апаттық қалпына келтіру",
            .hotkeyTip: "Жаһандық пернелер тіркесімі кез келген бағдарламада жұмыс істейді.",
            .accessibilityDesc: "Мәзір жолағындағы белгішелерді басқару және жасыру үшін қажет",
            .screenRecordingDesc: "Жасырын белгішелер тақтасы үшін анық нобайларды түсіруге пайдаланылады",
            .statusGranted: "Қосулы",
            .statusRequired: "Әрекет қажет",
            .statusOptional: "Қосымша",
            .checkPermissions: "Рұқсаттарды тексеру",
            .systemInfo: "Жүйе туралы ақпарат",
            .diagnosticsAndLogs: "Диагностика және журналдар",

            .generalSubheader: "Автоматты түрде қосуды, әрекеттерді және тілді баптау",
            .iconSubheader: "BarKeep белгішесінің стилі және жылдам әрекеттер",
            .permissionsSubheader: "Мәзір жолағымен жұмыс істеуге қажетті macOS жүйелік рұқсаттары",
            .menuBarHeight: "Мәзір жолағының биіктігі",
            .conflictingApps: "Қайшылық тудыратын утилиталар",
            .noConflictsDetected: "Табылмады",
            .copyReportDesc: "Жүйелік ақпаратты және бөлгіштердің күйін көшіру",
            .copied: "Көшірілді!",
            .copy: "Көшіру",
            .openLogDesc: "Журнал файлын Finder арқылы ашу",
            .open: "Ашу",

            .styleRectangle: "Тіктөртбұрыш (әдепкі)",
            .styleDots: "Нүктелер (···)",
            .styleChevron: "Шеврон (⟨)",
            .styleBar: "Бөлгіш (|)",
            .styleDash: "Сызықша (—)",

            .statusItemTooltip: "BarKeep: белгішелер тақтасын ашу үшін басыңыз; жылжыту үшін ⌘ + сүйреңіз",
            .resetAccessibility: "Рұқсатты қалпына келтіру",
            .resetAccessibilityDesc: "Егер баптаулардағы қосқыш қосулы болса, оны өшіріп қайта қосыңыз немесе қалпына келтіруді басыңыз"
        ],
        .zh: [
            .appVersion: "BarKeep %@",
            .conflictWarning: "⚠︎ 检测到 %@：可能会发生冲突",
            .hiddenPanel: "隐藏图标面板",
            .refreshList: "刷新列表",
            .hideHiddenIcons: "收起隐藏图标",
            .showHiddenIcons: "展开隐藏图标",
            .showOnHover: "鼠标悬停时展开",
            .restoreAllIcons: "恢复所有图标",
            .iconsCount: "图标：%d 个可见，共 %d 个",
            .noItemsFound: "未找到任何项目",
            .accessibilityOk: "辅助功能：✓",
            .accessibilityMissing: "辅助功能：未授权 — 打开设置",
            .screenRecordingOk: "屏幕录制：✓",
            .screenRecordingMissing: "屏幕录制：未授权 — 打开设置",
            .copyReport: "复制诊断报告到剪贴板",
            .openLog: "打开日志文件",
            .language: "语言",
            .quitApp: "退出 BarKeep",
            .launchAtLogin: "登录时启动",
            .preferences: "设置…",
            .generalTab: "通用",
            .iconTab: "菜单栏图标",
            .permissionsTab: "权限",
            .aboutTab: "关于",
            .iconStyle: "图标样式",
            .alwaysHiddenEnabled: "启用始终隐藏区域",

            .sectionVisible: "可见",
            .sectionHidden: "已隐藏",
            .sectionAlwaysHidden: "始终隐藏",

            .searchPlaceholder: "搜索",
            .activate: "激活",
            .hideAppName: "隐藏 %@",
            .quitAppName: "退出 %@…",
            .forceQuitAppName: "强制退出 %@…",

            .alertQuitTitle: "退出 %@？",
            .alertForceQuitTitle: "强制退出 %@？",
            .alertQuitMessage: "应用程序将收到正常的退出请求。未保存的数据可能会丢失。",
            .alertForceQuitMessage: "应用程序将立即关闭，无法保存数据。",
            .buttonQuit: "退出",
            .buttonForceQuit: "强制退出",
            .buttonCancel: "取消",
            .buttonOpenSettings: "打开设置",
            .buttonLater: "稍后",

            .onboardingAccessibilityTitle: "BarKeep 需要辅助功能权限",
            .onboardingAccessibilityMessage: "缺少此权限，BarKeep 将无法点击或重新排列菜单栏图标。\n\n请前往“系统设置 → 隐私与安全性 → 辅助功能”并启用 BarKeep。授权后将自动生效。",

            .reportCopied: "诊断报告已复制到剪贴板（%d 行）",
            .reportItems: "项目数量：%d",
            .reportHidden: "隐藏图标：%@",
            .reportAlwaysHidden: "始终隐藏：%@",
            .reportDividers: "分割线：hidden.minX=%d alwaysHidden.minX=%d",
            .reportStateShown: "已展开",
            .reportStateHidden: "已收起",

            .hotkeysTab: "快捷键",
            .launchAtLoginDesc: "登录 Mac 时自动启动 BarKeep",
            .showOnHoverDesc: "光标悬停在菜单栏时自动展开隐藏图标",
            .alwaysHiddenDesc: "为需要始终保持隐藏的图标添加次级分割线",
            .languageDesc: "选择 BarKeep 的界面语言",
            .iconPreview: "菜单栏实时预览",
            .openHiddenPanel: "打开面板",
            .openHiddenPanelDesc: "显示包含所有隐藏图标的浮动面板",
            .resetIconsDesc: "重置分割线并将所有图标恢复到默认可见位置",
            .hotkeyPanelDesc: "打开或关闭隐藏图标浮动面板",
            .hotkeyAlwaysHiddenDesc: "显示或隐藏“始终隐藏”区域",
            .hotkeyResetDesc: "紧急恢复所有菜单栏图标",
            .hotkeyTip: "全局快捷键可在 macOS 中的任何应用程序下使用。",
            .accessibilityDesc: "用于检测、读取菜单栏图标位置并管理其隐藏状态",
            .screenRecordingDesc: "用于为隐藏面板截取清晰的应用图标缩略图",
            .statusGranted: "已授权",
            .statusRequired: "需要授权",
            .statusOptional: "可选",
            .checkPermissions: "检查权限状态",
            .systemInfo: "系统信息",
            .diagnosticsAndLogs: "诊断与日志",

            .generalSubheader: "管理启动行为、悬停展开和界面语言",
            .iconSubheader: "菜单栏图标样式与快捷操作",
            .permissionsSubheader: "管理菜单栏所需的 macOS 系统权限",
            .menuBarHeight: "菜单栏高度",
            .conflictingApps: "冲突的应用程序",
            .noConflictsDetected: "未检测到冲突",
            .copyReportDesc: "复制系统信息、屏幕布局及分割线状态",
            .copied: "已复制！",
            .copy: "复制",
            .openLogDesc: "在访达 (Finder) 中显示日志文件",
            .open: "打开",

            .styleRectangle: "矩形（默认）",
            .styleDots: "圆点 (···)",
            .styleChevron: "单书名号 (⟨)",
            .styleBar: "竖线 (|)",
            .styleDash: "破折号 (—)",

            .statusItemTooltip: "BarKeep：点击打开图标面板；按住 ⌘ 并拖动可重新排列图标",
            .resetAccessibility: "重置权限",
            .resetAccessibilityDesc: "如果系统设置中的开关已开启，请尝试关闭后再重新打开，或点击重置"
        ]
    ]
}
