import Foundation
import SwiftUI
import Combine
import SwiftData

final class CareAccountStore: ObservableObject {
    static let shared = CareAccountStore()

    @Published private(set) var careAccountsByID: [String: CareRecipientDraft] = [:]
    @Published private(set) var usersByEmail: [String: UserAccount] = [:]
    @Published private(set) var pendingRequestsByAccountID: [String: [Caregiver]] = [:]
    @Published private(set) var chatMessagesByAccountID: [String: [ChatMessage]] = [:]
    @Published private(set) var chatReadAtByAccountAndUserID: [String: Date] = [:]

    private var modelContext: ModelContext?
    private var persistedState: PersistedAccountState?
    private let chatReadAtDefaultsKey = "CareBridgeAI.chatReadAtByAccountAndUserID"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        chatReadAtByAccountAndUserID = loadChatReadState()
    }

    func configure(with modelContext: ModelContext) {
        guard self.modelContext == nil else { return }

        self.modelContext = modelContext

        do {
            let descriptor = FetchDescriptor<PersistedAccountState>()
            if let state = try modelContext.fetch(descriptor).first {
                persistedState = state
                careAccountsByID = decode([String: CareRecipientDraft].self, from: state.careAccountsData) ?? [:]
                usersByEmail = decode([String: UserAccount].self, from: state.usersData) ?? [:]
                pendingRequestsByAccountID = decode([String: [Caregiver]].self, from: state.pendingRequestsData) ?? [:]
                chatMessagesByAccountID = decode([String: [ChatMessage]].self, from: state.chatMessagesData) ?? [:]
            } else {
                let state = PersistedAccountState()
                modelContext.insert(state)
                persistedState = state
                persistAccountState()
            }
        } catch {
            print("讀取帳號資料失敗：\(error.localizedDescription)")
        }
    }

    func saveCareAccount(_ draft: CareRecipientDraft) {
        careAccountsByID[draft.careRecipientID] = draft
        persistAccountState()
    }

    func registerUser(
        caregiver: Caregiver,
        careRecipientID: String
    ) {
        let key = caregiver.email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let account = UserAccount(
            email: key,
            password: caregiver.password,
            caregiver: caregiver,
            careRecipientID: careRecipientID
        )

        usersByEmail[key] = account
        persistAccountState()
    }

    func login(
        email: String,
        password: String
    ) -> LoginResult {
        let key = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard let account = usersByEmail[key] else {
            return .notFound
        }

        guard account.password == password else {
            return .wrongPassword
        }

        switch account.caregiver.status {
        case .pending:
            return .pending

        case .rejected:
            return .rejected

        case .approved:
            guard let draft = careAccountsByID[account.careRecipientID] else {
                return .notFound
            }

            return .success(
                draft: draft,
                user: account.caregiver
            )
        }
    }

    func submitJoinRequest(
        careRecipientID: String,
        caregiver: Caregiver
    ) {
        let normalizedID = careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailKey = caregiver.email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedID.isEmpty else { return }
        guard careAccountsByID[normalizedID] != nil else {
            print("找不到此照護帳戶 ID：\(normalizedID)")
            return
        }

        var requests = pendingRequestsByAccountID[normalizedID] ?? []

        if requests.contains(where: { $0.email.lowercased() == emailKey }) {
            return
        }

        requests.append(caregiver)
        pendingRequestsByAccountID[normalizedID] = requests

        let account = UserAccount(
            email: emailKey,
            password: caregiver.password,
            caregiver: caregiver,
            careRecipientID: normalizedID
        )

        usersByEmail[emailKey] = account
        persistAccountState()
    }

    func pendingRequests(for careRecipientID: String) -> [Caregiver] {
        let normalizedID = careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines)
        return pendingRequestsByAccountID[normalizedID] ?? []
    }

    func approveRequest(
        _ caregiver: Caregiver,
        careRecipientID: String
    ) -> Caregiver {
        let normalizedID = careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailKey = caregiver.email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        pendingRequestsByAccountID[normalizedID]?.removeAll {
            $0.id == caregiver.id
        }

        var approved = caregiver
        approved.status = .approved

        if var draft = careAccountsByID[normalizedID] {
            if !draft.caregivers.contains(where: { $0.id == approved.id }) {
                draft.caregivers.append(approved)
            }

            careAccountsByID[normalizedID] = draft
        }

        if var account = usersByEmail[emailKey] {
            account.caregiver = approved
            usersByEmail[emailKey] = account
        }

        persistAccountState()

        return approved
    }

    func rejectRequest(
        _ caregiver: Caregiver,
        careRecipientID: String
    ) {
        let normalizedID = careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailKey = caregiver.email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        pendingRequestsByAccountID[normalizedID]?.removeAll {
            $0.id == caregiver.id
        }

        if var account = usersByEmail[emailKey] {
            var rejected = account.caregiver
            rejected.status = .rejected
            account.caregiver = rejected
            usersByEmail[emailKey] = account
        }

        persistAccountState()
    }

    func removeMember(
        _ caregiver: Caregiver,
        careRecipientID: String
    ) {
        let normalizedID = careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailKey = caregiver.email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard caregiver.role != .mainManager else { return }

        if var draft = careAccountsByID[normalizedID] {
            draft.caregivers.removeAll { $0.id == caregiver.id }
            careAccountsByID[normalizedID] = draft
        }

        usersByEmail.removeValue(forKey: emailKey)
        pendingRequestsByAccountID[normalizedID]?.removeAll { $0.id == caregiver.id }

        persistAccountState()
    }
    
    func chatMessages(for careRecipientID: String) -> [ChatMessage] {
        let normalizedID = careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines)
        return chatMessagesByAccountID[normalizedID] ?? []
    }

    func hasUnreadChatMessages(
        for careRecipientID: String,
        currentUserID: UUID
    ) -> Bool {
        let normalizedID = careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let readAt = chatReadAtByAccountAndUserID[chatReadKey(
            careRecipientID: normalizedID,
            userID: currentUserID
        )] ?? .distantPast

        return chatMessagesByAccountID[normalizedID, default: []].contains { message in
            message.senderID != currentUserID && message.createdAt > readAt
        }
    }

    func markChatAsRead(
        careRecipientID: String,
        userID: UUID,
        readAt: Date = Date()
    ) {
        let normalizedID = careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedID.isEmpty else { return }

        setChatReadAt(
            careRecipientID: normalizedID,
            userID: userID,
            readAt: readAt
        )
    }

    func sendChatMessage(
        careRecipientID: String,
        message: ChatMessage
    ) {
        let normalizedID = careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedID.isEmpty else { return }

        var messages = chatMessagesByAccountID[normalizedID] ?? []
        messages.append(message)
        chatMessagesByAccountID[normalizedID] = messages
        setChatReadAt(
            careRecipientID: normalizedID,
            userID: message.senderID,
            readAt: message.createdAt
        )
        persistAccountState()
    }

    func updateChatMessage(
        careRecipientID: String,
        message: ChatMessage
    ) {
        let normalizedID = careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard var messages = chatMessagesByAccountID[normalizedID] else { return }

        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }

        messages[index] = message
        chatMessagesByAccountID[normalizedID] = messages
        persistAccountState()
    }

    func loadCareContent(for careRecipientID: String) -> CareContentSnapshot? {
        guard let modelContext else { return nil }
        let normalizedID = careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptor = FetchDescriptor<PersistedCareContent>(
            predicate: #Predicate { $0.careRecipientID == normalizedID }
        )

        do {
            guard let content = try modelContext.fetch(descriptor).first,
                  let draft = decode(CareRecipientDraft.self, from: content.draftData),
                  let records = decode([CareRecord].self, from: content.recordsData),
                  let tasks = decode([CareTask].self, from: content.tasksData),
                  let memos = decode([Memo].self, from: content.memosData)
            else {
                return nil
            }

            return CareContentSnapshot(
                draft: draft,
                records: records,
                tasks: tasks,
                memos: memos,
                profilePhotoData: content.profilePhotoData
            )
        } catch {
            print("讀取照護資料失敗：\(error.localizedDescription)")
            return nil
        }
    }

    func saveCareContent(_ snapshot: CareContentSnapshot) {
        guard let modelContext,
              let draftData = encode(snapshot.draft),
              let recordsData = encode(snapshot.records),
              let tasksData = encode(snapshot.tasks),
              let memosData = encode(snapshot.memos)
        else {
            return
        }

        let careRecipientID = snapshot.draft.careRecipientID
        let descriptor = FetchDescriptor<PersistedCareContent>(
            predicate: #Predicate { $0.careRecipientID == careRecipientID }
        )

        do {
            let content: PersistedCareContent
            if let existing = try modelContext.fetch(descriptor).first {
                content = existing
                content.draftData = draftData
                content.recordsData = recordsData
                content.tasksData = tasksData
                content.memosData = memosData
                content.profilePhotoData = snapshot.profilePhotoData
            } else {
                content = PersistedCareContent(
                    careRecipientID: careRecipientID,
                    draftData: draftData,
                    recordsData: recordsData,
                    tasksData: tasksData,
                    memosData: memosData,
                    profilePhotoData: snapshot.profilePhotoData
                )
                modelContext.insert(content)
            }

            careAccountsByID[careRecipientID] = snapshot.draft
            persistAccountState(saveContext: false)
            try modelContext.save()
        } catch {
            print("儲存照護資料失敗：\(error.localizedDescription)")
        }
    }

    private func persistAccountState(saveContext: Bool = true) {
        guard let modelContext, let persistedState else { return }
        guard let careAccountsData = encode(careAccountsByID),
              let usersData = encode(usersByEmail),
              let pendingRequestsData = encode(pendingRequestsByAccountID),
              let chatMessagesData = encode(chatMessagesByAccountID)
        else {
            return
        }

        persistedState.careAccountsData = careAccountsData
        persistedState.usersData = usersData
        persistedState.pendingRequestsData = pendingRequestsData
        persistedState.chatMessagesData = chatMessagesData

        guard saveContext else { return }
        do {
            try modelContext.save()
        } catch {
            print("儲存帳號資料失敗：\(error.localizedDescription)")
        }
    }

    private func encode<T: Encodable>(_ value: T) -> Data? {
        do {
            return try encoder.encode(value)
        } catch {
            print("資料編碼失敗：\(error.localizedDescription)")
            return nil
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        guard !data.isEmpty else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private func loadChatReadState() -> [String: Date] {
        guard let data = UserDefaults.standard.data(forKey: chatReadAtDefaultsKey) else {
            return [:]
        }

        return decode([String: Date].self, from: data) ?? [:]
    }

    private func saveChatReadState() {
        guard let data = encode(chatReadAtByAccountAndUserID) else { return }
        UserDefaults.standard.set(data, forKey: chatReadAtDefaultsKey)
    }

    private func setChatReadAt(
        careRecipientID: String,
        userID: UUID,
        readAt: Date
    ) {
        var readState = chatReadAtByAccountAndUserID
        readState[chatReadKey(careRecipientID: careRecipientID, userID: userID)] = readAt
        chatReadAtByAccountAndUserID = readState
        saveChatReadState()
    }

    private func chatReadKey(careRecipientID: String, userID: UUID) -> String {
        "\(careRecipientID)|\(userID.uuidString)"
    }
}
