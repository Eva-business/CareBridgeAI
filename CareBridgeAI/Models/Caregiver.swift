import Foundation

enum CaregiverRole: String, CaseIterable, Codable, Identifiable {
    case mainManager = "主要管理者"
    case family = "家人"
    case caregiver = "看護"
    case recipientSelf = "被照護者本人"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mainManager:
            return "Main Manager"
        case .family:
            return "Family"
        case .caregiver:
            return "Caregiver"
        case .recipientSelf:
            return "Care Recipient"
        }
    }
}

enum MemberStatus: String, CaseIterable, Codable, Identifiable {
    case pending = "等待審核"
    case approved = "已加入"
    case rejected = "已拒絕"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending:
            return "Pending Review"
        case .approved:
            return "Joined"
        case .rejected:
            return "Rejected"
        }
    }
}

struct Caregiver: Identifiable, Codable {
    let id: UUID
    var name: String
    var phone: String
    var email: String
    var password: String
    var role: CaregiverRole
    var status: MemberStatus
    var isCreator: Bool
    var joinedAt: Date
    var preferredLanguage: AppLanguage

    init(
        id: UUID = UUID(),
        name: String,
        phone: String,
        email: String,
        password: String,
        role: CaregiverRole,
        status: MemberStatus = .approved,
        isCreator: Bool = false,
        joinedAt: Date = Date(),
        preferredLanguage: AppLanguage = .zhTW
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.password = password
        self.role = role
        self.status = status
        self.isCreator = isCreator
        self.joinedAt = joinedAt
        self.preferredLanguage = preferredLanguage
    }

    var canManageMembers: Bool {
        role == .mainManager && status == .approved
    }

    var canDeleteGroup: Bool {
        role == .mainManager && status == .approved
    }

    var canApproveMembers: Bool {
        role == .mainManager && status == .approved
    }
}
