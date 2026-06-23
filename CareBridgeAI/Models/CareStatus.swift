import SwiftUI

enum CareStatus: String, CaseIterable, Identifiable, Codable {
    case good = "正常"
    case warning = "需注意"
    case danger = "異常"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .good:
            return "Stable"
        case .warning:
            return "Needs Attention"
        case .danger:
            return "Urgent"
        }
    }

    var color: Color {
        switch self {
        case .good:
            return AppTheme.primaryGreen
        case .warning:
            return AppTheme.warningYellow
        case .danger:
            return AppTheme.dangerRed
        }
    }

    var icon: String {
        switch self {
        case .good:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .danger:
            return "xmark.octagon.fill"
        }
    }

    var description: String {
        switch self {
        case .good:
            return "Currently stable"
        case .warning:
            return "Follow-up needed"
        case .danger:
            return "Immediate attention needed"
        }
    }
}
