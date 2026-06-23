import Foundation
import Speech
import SwiftUI

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

extension AppLanguage {
    var isChinese: Bool { self == .zhTW }

    func text(en: String, zhTW: String) -> String {
        isChinese ? zhTW : en
    }
}

private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .en
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }
}

extension CareStatus {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .good:
            return language.text(en: "Stable", zhTW: "穩定")
        case .warning:
            return language.text(en: "Needs Attention", zhTW: "需注意")
        case .danger:
            return language.text(en: "Urgent", zhTW: "緊急")
        }
    }

    func description(_ language: AppLanguage) -> String {
        switch self {
        case .good:
            return language.text(en: "Currently stable", zhTW: "目前狀態穩定")
        case .warning:
            return language.text(en: "Follow-up needed", zhTW: "需要持續觀察")
        case .danger:
            return language.text(en: "Immediate attention needed", zhTW: "需要立即關注")
        }
    }
}

extension CareRecordCategory {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .food:
            return language.text(en: "Food", zhTW: "飲食")
        case .medicine:
            return language.text(en: "Medication", zhTW: "用藥")
        case .bowel:
            return language.text(en: "Bowel", zhTW: "排便")
        case .mood:
            return language.text(en: "Mood", zhTW: "情緒")
        case .custom:
            return language.text(en: "Other", zhTW: "其他")
        }
    }

    func shortDisplayName(_ language: AppLanguage) -> String {
        switch self {
        case .food:
            return language.text(en: "Food", zhTW: "食")
        case .medicine:
            return language.text(en: "Meds", zhTW: "藥")
        case .bowel:
            return language.text(en: "Bowel", zhTW: "便")
        case .mood:
            return language.text(en: "Mood", zhTW: "情緒")
        case .custom:
            return language.text(en: "Other", zhTW: "其他")
        }
    }
}

extension RecordCondition {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .good:
            return language.text(en: "Good", zhTW: "良好")
        case .normal:
            return language.text(en: "Fair", zhTW: "普通")
        case .bad:
            return language.text(en: "Poor", zhTW: "不好")
        }
    }
}

extension CareTaskType {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .routine:
            return language.text(en: "Routine Task", zhTW: "常態任務")
        case .temporary:
            return language.text(en: "One-time Task", zhTW: "單次任務")
        }
    }
}

extension CaregiverRole {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .mainManager:
            return language.text(en: "Main Manager", zhTW: "主要管理者")
        case .family:
            return language.text(en: "Family", zhTW: "家人")
        case .caregiver:
            return language.text(en: "Caregiver", zhTW: "看護")
        case .recipientSelf:
            return language.text(en: "Care Recipient", zhTW: "被照護者")
        }
    }
}

extension MemberStatus {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .pending:
            return language.text(en: "Pending Review", zhTW: "等待審核")
        case .approved:
            return language.text(en: "Joined", zhTW: "已加入")
        case .rejected:
            return language.text(en: "Rejected", zhTW: "已拒絕")
        }
    }
}
