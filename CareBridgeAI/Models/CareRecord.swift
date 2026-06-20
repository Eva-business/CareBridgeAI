import Foundation
import SwiftUI

enum CareRecordCategory: String, CaseIterable, Identifiable, Codable {
    case food = "飲食"
    case medicine = "用藥"
    case bowel = "排便"
    case mood = "情緒"
    case custom = "其他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food:
            return "fork.knife"
        case .medicine:
            return "pills.fill"
        case .bowel:
            return "toilet.fill"
        case .mood:
            return "face.smiling.fill"
        case .custom:
            return "doc.text.fill"
        }
    }

    var color: Color {
        switch self {
        case .food:
            return .green
        case .medicine:
            return .purple
        case .bowel:
            return .brown
        case .mood:
            return .orange
        case .custom:
            return .gray
        }
    }
}

enum RecordCondition: String, CaseIterable, Identifiable, Codable {
    case good = "良好"
    case normal = "普通"
    case bad = "不好"

    var id: String { rawValue }

    var status: CareStatus {
        switch self {
        case .good:
            return .good
        case .normal:
            return .warning
        case .bad:
            return .danger
        }
    }

    var color: Color {
        switch self {
        case .good:
            return AppTheme.primaryGreen
        case .normal:
            return AppTheme.warningYellow
        case .bad:
            return AppTheme.dangerRed
        }
    }

    var icon: String {
        switch self {
        case .good:
            return "face.smiling.fill"
        case .normal:
            return "face.dashed.fill"
        case .bad:
            return "face.frown.fill"
        }
    }
}

struct CareRecord: Identifiable, Codable {
    let id: UUID
    var content: String
    var category: CareRecordCategory
    var condition: RecordCondition?
    var createdAt: Date
    var createdBy: String

    init(
        id: UUID = UUID(),
        content: String,
        category: CareRecordCategory,
        condition: RecordCondition? = nil,
        createdAt: Date = Date(),
        createdBy: String = "主要管理者"
    ) {
        self.id = id
        self.content = content
        self.category = category
        self.condition = condition
        self.createdAt = createdAt
        self.createdBy = createdBy
    }
}
