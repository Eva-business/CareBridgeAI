import Foundation
import SwiftData

@Model
final class PersistedAccountState {
    @Attribute(.unique) var key: String
    var careAccountsData: Data
    var usersData: Data
    var pendingRequestsData: Data
    var chatMessagesData: Data

    init(
        key: String = "main",
        careAccountsData: Data = Data(),
        usersData: Data = Data(),
        pendingRequestsData: Data = Data(),
        chatMessagesData: Data = Data()
    ) {
        self.key = key
        self.careAccountsData = careAccountsData
        self.usersData = usersData
        self.pendingRequestsData = pendingRequestsData
        self.chatMessagesData = chatMessagesData
    }
}

@Model
final class PersistedCareContent {
    @Attribute(.unique) var careRecipientID: String
    var draftData: Data
    var recordsData: Data
    var tasksData: Data
    var memosData: Data
    var profilePhotoData: Data?

    init(
        careRecipientID: String,
        draftData: Data,
        recordsData: Data,
        tasksData: Data,
        memosData: Data,
        profilePhotoData: Data? = nil
    ) {
        self.careRecipientID = careRecipientID
        self.draftData = draftData
        self.recordsData = recordsData
        self.tasksData = tasksData
        self.memosData = memosData
        self.profilePhotoData = profilePhotoData
    }
}

struct CareContentSnapshot: Codable {
    var draft: CareRecipientDraft
    var records: [CareRecord]
    var tasks: [CareTask]
    var memos: [Memo]
    var profilePhotoData: Data?
}

extension CareContentSnapshot {
    var containsLegacyDemoText: Bool {
        records.contains { $0.content.containsCareBridgeCJKText || $0.createdBy.containsCareBridgeCJKText }
        || tasks.contains { $0.title.containsCareBridgeCJKText || $0.note.containsCareBridgeCJKText }
        || memos.contains { $0.content.containsCareBridgeCJKText }
    }
}
