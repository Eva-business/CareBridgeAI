import SwiftUI

enum CareStatus: String, CaseIterable, Identifiable, Codable {
    case good = "正常"
    case warning = "需注意"
    case danger = "異常"

    var id: String { rawValue }

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
            return "目前狀態穩定"
        case .warning:
            return "有狀況需要留意"
        case .danger:
            return "需要立即關注"
        }
    }
}
