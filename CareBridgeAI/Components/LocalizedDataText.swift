import SwiftUI
import Translation

struct LocalizedDataText: View {
    @Environment(\.appLanguage) private var appLanguage

    let text: String

    @State private var translatedText: String?
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var translationKey = ""

    var body: some View {
        Text(displayText)
            .translationTask(translationConfiguration) { session in
                await translate(using: session)
            }
            .onAppear(perform: configureTranslation)
            .onChange(of: text) {
                configureTranslation()
            }
            .onChange(of: appLanguage) {
                configureTranslation()
            }
    }

    private var displayText: String {
        translatedText ?? deterministicText
    }

    private var deterministicText: String {
        guard !text.isEmpty else { return text }

        if appLanguage.isChinese || appLanguage.usesDynamicTargetTranslation {
            return text.localizedCareText(appLanguage)
        }

        let translated = text.careBridgeEnglishCareTextValue.careBridgeEnglishProfileValue
        return translated.containsCareBridgeCJKText ? text : translated
    }

    private func configureTranslation() {
        let key = "\(appLanguage.code)|\(text)"
        guard key != translationKey else { return }

        translationKey = key
        translatedText = nil

        guard let sourceLanguage = sourceLanguageForTranslation else {
            translationConfiguration = nil
            return
        }

        let nextConfiguration = TranslationService.configuration(
            from: sourceLanguage,
            to: appLanguage
        )

        if translationConfiguration == nextConfiguration {
            translationConfiguration?.invalidate()
        } else {
            translationConfiguration = nextConfiguration
        }
    }

    private var sourceLanguageForTranslation: AppLanguage? {
        guard appLanguage == .zhTW || appLanguage == .en || appLanguage.usesDynamicTargetTranslation else { return nil }

        if appLanguage.usesDynamicTargetTranslation {
            if appLanguage == .ja, text.containsCareBridgeJapaneseText {
                return nil
            }

            if appLanguage == .th, text.containsCareBridgeThaiText {
                return nil
            }

            if text.containsCareBridgeCJKText {
                return deterministicText.containsCareBridgeJapaneseText ? nil : .zhTW
            }

            return deterministicText.stillContainsEnglishWords ? .en : nil
        }

        if appLanguage == .zhTW {
            guard !text.containsCareBridgeCJKText else { return nil }
            return deterministicText.stillContainsEnglishWords ? .en : nil
        }

        guard text.containsCareBridgeCJKText else { return nil }
        return deterministicText.containsCareBridgeCJKText ? .zhTW : nil
    }

    private func translate(using session: TranslationSession) async {
        do {
            translatedText = try await TranslationService.translate(text: text, using: session)
        } catch {
            translatedText = nil
        }
    }
}

private extension String {
    var stillContainsEnglishWords: Bool {
        range(of: #"[A-Za-z]{3,}"#, options: .regularExpression) != nil
    }

    var containsCareBridgeJapaneseText: Bool {
        range(of: #"\p{Hiragana}|\p{Katakana}"#, options: .regularExpression) != nil
    }

    var containsCareBridgeThaiText: Bool {
        range(of: #"\p{Thai}"#, options: .regularExpression) != nil
    }
}
