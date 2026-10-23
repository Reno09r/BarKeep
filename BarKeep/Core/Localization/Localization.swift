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
            .reportStateHidden: "hidden"
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
            .reportStateHidden: "спрятаны"
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
            .reportStateHidden: "жасырылған"
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
            .reportStateHidden: "已收起"
        ]
    ]
}
