import Foundation

enum TranslationService {
    static func translate(
        text: String,
        from sourceLanguage: AppLanguage,
        to targetLanguage: AppLanguage
    ) async -> String {
        // MVP 原型：先用假翻譯，確認聊天室流程可以跑。
        // 之後這裡可以改接 Apple Translation framework、OpenAI API、Google Translate API 等。
        if sourceLanguage == targetLanguage {
            return text
        }

        return "[\(sourceLanguage.displayName) → \(targetLanguage.displayName)] \(text)"
    }
}
