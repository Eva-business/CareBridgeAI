import Foundation
import Translation

enum TranslationService {
    static func configuration(
        from sourceLanguage: AppLanguage,
        to targetLanguage: AppLanguage
    ) -> TranslationSession.Configuration {
        TranslationSession.Configuration(
            source: Locale.Language(identifier: sourceLanguage.code),
            target: Locale.Language(identifier: targetLanguage.code)
        )
    }

    static func translate(text: String, using session: TranslationSession) async throws -> String {
        try await session.translate(text).targetText
    }
}
