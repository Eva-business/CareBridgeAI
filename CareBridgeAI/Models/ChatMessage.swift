import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    var senderID: UUID
    var senderName: String
    var senderRole: CaregiverRole
    var originalLanguage: AppLanguage
    var originalText: String
    var translatedText: String?
    var translatedLanguage: AppLanguage?
    var createdAt: Date
    var isVoiceMessage: Bool
    var isTranscriptVisible: Bool

    init(
        id: UUID = UUID(),
        senderID: UUID,
        senderName: String,
        senderRole: CaregiverRole,
        originalLanguage: AppLanguage,
        originalText: String,
        translatedText: String? = nil,
        translatedLanguage: AppLanguage? = nil,
        createdAt: Date = Date(),
        isVoiceMessage: Bool = false,
        isTranscriptVisible: Bool = true
    ) {
        self.id = id
        self.senderID = senderID
        self.senderName = senderName
        self.senderRole = senderRole
        self.originalLanguage = originalLanguage
        self.originalText = originalText
        self.translatedText = translatedText
        self.translatedLanguage = translatedLanguage
        self.createdAt = createdAt
        self.isVoiceMessage = isVoiceMessage
        self.isTranscriptVisible = isTranscriptVisible
    }
}
