import Foundation
import SwiftUI

enum CareRecordAttachmentKind: String, Codable {
    case image
    case video
}

struct CareRecordAttachment: Identifiable, Codable, Equatable {
    let id: UUID
    var kind: CareRecordAttachmentKind
    var data: Data
    var filename: String
    var contentType: String

    init(
        id: UUID = UUID(),
        kind: CareRecordAttachmentKind,
        data: Data,
        filename: String,
        contentType: String
    ) {
        self.id = id
        self.kind = kind
        self.data = data
        self.filename = filename
        self.contentType = contentType
    }
}

enum CareRecordCategory: String, CaseIterable, Identifiable, Codable {
    case food = "飲食"
    case medicine = "用藥"
    case bowel = "排便"
    case mood = "情緒"
    case custom = "其他"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .food:
            return "Food"
        case .medicine:
            return "Medication"
        case .bowel:
            return "Bowel"
        case .mood:
            return "Mood"
        case .custom:
            return "Other"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .food:
            return "Food"
        case .medicine:
            return "Meds"
        case .bowel:
            return "Bowel"
        case .mood:
            return "Mood"
        case .custom:
            return "Other"
        }
    }

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

    var displayName: String {
        switch self {
        case .good:
            return "Good"
        case .normal:
            return "Fair"
        case .bad:
            return "Poor"
        }
    }

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
            return "xmark.octagon.fill"
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
    var attachments: [CareRecordAttachment]

    init(
        id: UUID = UUID(),
        content: String,
        category: CareRecordCategory,
        condition: RecordCondition? = nil,
        createdAt: Date = Date(),
        createdBy: String = "Main Manager",
        attachments: [CareRecordAttachment] = []
    ) {
        self.id = id
        self.content = content
        self.category = category
        self.condition = condition
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.attachments = attachments
    }

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case category
        case condition
        case createdAt
        case createdBy
        case attachments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        category = try container.decode(CareRecordCategory.self, forKey: .category)
        condition = try container.decodeIfPresent(RecordCondition.self, forKey: .condition)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        attachments = try container.decodeIfPresent([CareRecordAttachment].self, forKey: .attachments) ?? []
    }
}
