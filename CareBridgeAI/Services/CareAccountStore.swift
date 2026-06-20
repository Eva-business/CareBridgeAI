import Foundation
import SwiftUI
import Combine

final class CareAccountStore: ObservableObject {
    static let shared = CareAccountStore()

    @Published private(set) var careAccountsByID: [String: CareRecipientDraft] = [:]
    @Published private(set) var usersByEmail: [String: UserAccount] = [:]
    @Published private(set) var pendingRequestsByAccountID: [String: [Caregiver]] = [:]
    @Published private(set) var chatMessagesByAccountID: [String: [ChatMessage]] = [:]

    private init() {}

    func saveCareAccount(_ draft: CareRecipientDraft) {
        careAccountsByID[draft.careRecipientID] = draft
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
    }
    
    func chatMessages(for careRecipientID: String) -> [ChatMessage] {
        let normalizedID = careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines)
        return chatMessagesByAccountID[normalizedID] ?? []
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
    }
}
