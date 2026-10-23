import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable {
    case en = "en"
    case ru = "ru"
    case kk = "kk"
    case zh = "zh"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .en: "English"
        case .ru: "Русский"
        case .kk: "Қазақша"
        case .zh: "简体中文"
        }
    }

    public static let defaultLanguage: AppLanguage = .en
}
