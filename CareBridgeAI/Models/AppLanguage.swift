import Foundation
import Speech

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case zhTW = "繁體中文"
    case en = "English"
    case id = "Bahasa Indonesia"
    case vi = "Tiếng Việt"
    case th = "ภาษาไทย"
    case ja = "日本語"

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }

    var code: String {
        switch self {
        case .zhTW:
            return "zh-TW"
        case .en:
            return "en"
        case .id:
            return "id"
        case .vi:
            return "vi"
        case .th:
            return "th"
        case .ja:
            return "ja"
        }
    }

    var speechLocaleIdentifier: String {
        switch self {
        case .zhTW:
            return "zh-TW"
        case .en:
            return "en-US"
        case .id:
            return "id-ID"
        case .vi:
            return "vi-VN"
        case .th:
            return "th-TH"
        case .ja:
            return "ja-JP"
        }
    }

    var englishName: String {
        switch self {
        case .zhTW:
            return "Traditional Chinese"
        case .en:
            return "English"
        case .id:
            return "Indonesian"
        case .vi:
            return "Vietnamese"
        case .th:
            return "Thai"
        case .ja:
            return "Japanese"
        }
    }
}
