import SwiftUI
import Foundation

/// 按指定 Locale 从 Bundle 取本地化字符串（用于 Alert 标题、TextField placeholder 等必须传 String 的场景）。
/// SwiftUI 的 Text("key")、Button("key") 会跟随 environment(\.locale)；String(localized:) 不跟随，故此处用 Bundle 按 locale 查找。
func localizedString(_ key: String, locale: Locale, table: String? = nil) -> String {
    let id = locale.identifier
    if let path = Bundle.main.path(forResource: id, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        let s = bundle.localizedString(forKey: key, value: key, table: table)
        if s != key { return s }
    }
    let langCode = id.split(separator: "-").first.map(String.init) ?? id
    if let path = Bundle.main.path(forResource: langCode, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        return bundle.localizedString(forKey: key, value: key, table: table)
    }
    return Bundle.main.localizedString(forKey: key, value: key, table: table)
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case en = "en"
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case ja = "ja"
    case fr = "fr"
    case de = "de"
    case es = "es"
    case ko = "ko"
    case ptBR = "pt-BR"
    case ru = "ru"
    case it = "it"
    case pl = "pl"
    case nl = "nl"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system:
            return localizedString("language.system", locale: LocalizationManager.shared.locale)
        case .en:
            return "English"
        case .zhHans:
            return "简体中文"
        case .zhHant:
            return "繁體中文"
        case .ja:
            return "日本語"
        case .fr:
            return "Français"
        case .de:
            return "Deutsch"
        case .es:
            return "Español"
        case .ko:
            return "한국어"
        case .ptBR:
            return "Português (BR)"
        case .ru:
            return "Русский"
        case .it:
            return "Italiano"
        case .pl:
            return "Polski"
        case .nl:
            return "Nederlands"
        }
    }
    
    var locale: Locale? {
        guard self != .system else { return nil }
        return Locale(identifier: rawValue)
    }
}

@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()
    
    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    private init() {
        if let stored = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: stored) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .system
        }
    }
    
    var locale: Locale {
        currentLanguage.locale ?? Locale.current
    }
}

extension String {
    /// 按系统语言取本地化字符串（不跟随 SwiftUI environment locale）。需要跟随界面语言时请用 Text("key") 或 localizedString(_:locale:)。
    static func localized(_ key: String.LocalizationValue) -> String {
        String(localized: key)
    }
}
