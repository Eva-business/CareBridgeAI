import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct CareAIAnalysis {
    let categories: [CareRecordCategory]
    let condition: RecordCondition?
    let suggestions: [CareAIRecordSuggestion]
    let usedOnDeviceModel: Bool
}

struct CareAIRecordSuggestion: Identifiable, Hashable {
    let id = UUID()
    let category: CareRecordCategory
    let condition: RecordCondition
    let content: String
}

struct CareAISummary {
    let text: String
    let status: CareStatus
    let usedOnDeviceModel: Bool
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
private struct GeneratedCareAnalysis {
    @Guide(description: "One or more record categories", .maximumCount(5))
    var categories: [GeneratedCareCategory]

    var condition: GeneratedCareCondition?

    @Guide(description: "Separate concise records extracted from the note. Create one item per meaningful category.", .maximumCount(6))
    var records: [GeneratedCareRecord]
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedCareRecord {
    @Guide(description: "Choose exactly one category. Use medicine for medication, pills, blood pressure, blood sugar, doctor, clinic, or follow-up visits even if the text says after breakfast.")
    var category: GeneratedCareCategory

    @Guide(description: "Choose exactly one label: good = 良好, completed as expected, stable, or explicitly no symptoms; normal = 普通, mild unnegated concern needing observation; bad = 不好, urgent or clearly abnormal.")
    var condition: GeneratedCareCondition

    @Guide(description: "A short factual record for only this category, written in the requested output language")
    var content: String
}

@available(iOS 26.0, *)
@Generable
private enum GeneratedCareCategory {
    case food
    case medicine
    case bowel
    case mood
    case custom
}

@available(iOS 26.0, *)
@Generable(description: "The care condition label. good = 良好/completed/stable/no symptoms; normal = 普通/mild unnegated concern; bad = 不好/urgent or clearly abnormal.")
private enum GeneratedCareCondition {
    case good
    case normal
    case bad
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedCareSummary {
    @Guide(description: "A concise caregiver handoff summary in the requested language")
    var summary: String

    var status: GeneratedCareStatus
}

@available(iOS 26.0, *)
@Generable
private enum GeneratedCareStatus {
    case good
    case warning
    case danger
}
#endif

enum CareAIService {
    static func analyze(_ text: String, language: AppLanguage = .en) async -> CareAIAnalysis {
        let trimmed = KeywordFallbackCareSemanticAnalyzer.normalizedCareSpeechText(text)
        guard !trimmed.isEmpty else {
            return CareAIAnalysis(categories: [], condition: nil, suggestions: [], usedOnDeviceModel: false)
        }

        var analyzers: [CareSemanticAnalyzing] = []

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.availability == .available {
            analyzers.append(FoundationModelsCareSemanticAnalyzer())
        }
        #endif

        analyzers.append(KeywordFallbackCareSemanticAnalyzer())
        return await CareSemanticAnalyzerPipeline(analyzers: analyzers).analyze(
            CareSemanticAnalysisRequest(text: trimmed, outputLanguage: language)
        )
    }

    static func summarize(
        _ records: [CareRecord],
        applying24HourWindow: Bool = true,
        language: AppLanguage = .en
    ) async -> CareAISummary {
        let recentRecords: [CareRecord]
        if applying24HourWindow {
            let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
            recentRecords = records.filter { $0.createdAt >= cutoff }
        } else {
            recentRecords = records
        }

        guard !recentRecords.isEmpty else {
            let text = generateSummary(from: recentRecords, language: language)
            return CareAISummary(text: text, status: .good, usedOnDeviceModel: false)
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.availability == .available {
            do {
                let result = try await summarizeWithFoundationModels(
                    recentRecords,
                    language: language
                )
                return CareAISummary(
                    text: result.text,
                    status: generateStatus(from: recentRecords),
                    usedOnDeviceModel: result.usedOnDeviceModel
                )
            } catch {
                // Fall through so the handoff remains useful on every supported device.
            }
        }
        #endif

        let text = generateSummary(from: recentRecords, language: language)
        return CareAISummary(
            text: text,
            status: generateStatus(from: recentRecords),
            usedOnDeviceModel: false
        )
    }

    static func classifyRecord(_ text: String) -> CareRecordCategory {
        classifyCategories(text).first ?? .custom
    }

    static func classifyCategories(_ text: String) -> [CareRecordCategory] {
        KeywordFallbackCareSemanticAnalyzer.classifyCategories(
            KeywordFallbackCareSemanticAnalyzer.normalizedCareSpeechText(text)
        )
    }

    static func inferCondition(from text: String) -> RecordCondition? {
        KeywordFallbackCareSemanticAnalyzer.inferCondition(
            from: KeywordFallbackCareSemanticAnalyzer.normalizedCareSpeechText(text)
        )
    }

    static func generateRecordsFromText(
        _ text: String,
        selectedCategories: [CareRecordCategory],
        analysis: CareAIAnalysis? = nil,
        condition: RecordCondition? = nil
    ) -> [CareRecord] {
        let trimmed = KeywordFallbackCareSemanticAnalyzer.normalizedCareSpeechText(text)
        guard !trimmed.isEmpty else { return [] }

        let categories = uniqueCategories(selectedCategories.isEmpty ? (analysis?.categories ?? classifyCategories(trimmed)) : selectedCategories)
        let resolvedCondition = condition ?? analysis?.condition ?? inferCondition(from: trimmed)
        let suggestions = buildRecordSuggestions(
            from: trimmed,
            categories: categories,
            analysis: analysis,
            condition: resolvedCondition
        )

        return finalizedRecordSuggestions(suggestions).map {
            CareRecord(content: $0.content, category: $0.category, condition: $0.condition)
        }
    }

    static func generateStatus(from summary: String) -> CareStatus {
        let normalizedSummary = removeNegatedAbnormalPhrases(from: summary)
        let dangerKeywords = [
            "發燒", "跌倒", "嘔吐", "呼吸困難", "胸痛", "昏倒", "劇痛", "送醫", "異常", "無法進食", "意識不清", "不好",
            "fever", "fall", "fell", "vomit", "vomiting", "shortness of breath", "chest pain", "fainted", "severe pain",
            "sent to hospital", "abnormal", "unable to eat", "unconscious", "urgent", "poor condition"
        ]
        let warningKeywords = [
            "咳嗽", "食慾差", "頭暈", "疲倦", "腹瀉", "便秘", "情緒低落", "睡不好", "疼痛", "不舒服", "需注意", "普通",
            "cough", "poor appetite", "dizzy", "dizziness", "tired", "fatigue", "diarrhea", "constipation",
            "low mood", "slept poorly", "pain", "discomfort", "needs attention", "follow-up", "fair"
        ]

        if dangerKeywords.contains(where: { normalizedSummary.contains($0) }) { return .danger }
        if warningKeywords.contains(where: { normalizedSummary.contains($0) }) { return .warning }
        return .good
    }

    static func generateStatus(from records: [CareRecord]) -> CareStatus {
        if records.contains(where: { $0.condition == .bad }) {
            return .danger
        }

        if records.contains(where: { $0.condition == .normal }) {
            return .warning
        }

        let unevaluatedRecords = records.filter { $0.condition == nil }
        guard !unevaluatedRecords.isEmpty else {
            return .good
        }

        let unevaluatedText = unevaluatedRecords
            .map(\.content)
            .joined(separator: " ")
        return generateStatus(from: unevaluatedText)
    }

    static func generateSummary(
        from records: [CareRecord],
        language: AppLanguage = .en
    ) -> String {
        let sortedRecords = records.sorted { $0.createdAt > $1.createdAt }
        guard !sortedRecords.isEmpty else {
            return language.text(
                en: "No care records have been added today. No clear abnormal information is available yet.",
                zhTW: "今天尚未新增照護紀錄，目前沒有明確異常資訊。"
            )
        }

        var parts: [String] = []
        for category in CareRecordCategory.allCases {
            if let latest = sortedRecords.first(where: { $0.category == category }) {
                let content = latest.content.localizedCareText(language)
                let separator = (language.isChinese || language.isJapanese) ? "：" : ": "
                parts.append("\(category.displayName(language))\(separator)\(content)")
            }
        }

        let badCount = sortedRecords.filter { $0.condition == .bad }.count
        let normalCount = sortedRecords.filter { $0.condition == .normal }.count
        if badCount > 0 {
            parts.append(language.text(
                en: "\(badCount) record(s) indicate poor condition today. Please review promptly.",
                zhTW: "今天有 \(badCount) 筆狀況不佳的紀錄，請盡快查看。"
            ))
        } else if normalCount > 0 {
            parts.append(language.text(
                en: "\(normalCount) record(s) need follow-up observation today.",
                zhTW: "今天有 \(normalCount) 筆紀錄需要持續觀察。"
            ))
        } else {
            parts.append(language.text(
                en: "Overall status is currently stable.",
                zhTW: "整體狀態目前穩定。"
            ))
        }
        return parts.joined(separator: " ")
    }

    static func generateSummary() -> String {
        "No complete care records have been added today. Add food, medication, bowel, or mood records and the system will create a handoff summary automatically."
    }

    private static func removeNegatedAbnormalPhrases(from text: String) -> String {
        var normalized = text
        [
            "無明顯異常資訊",
            "無明顯異常",
            "無異常反應",
            "無異常",
            "沒有異常",
            "未見異常",
            "未發現異常",
            "沒有不舒服",
            "無不舒服",
            "無不適",
            "沒有不好"
        ].forEach {
            normalized = normalized.replacingOccurrences(of: $0, with: "")
        }
        return normalized
    }

    static func buildRecordSuggestions(
        from text: String,
        categories: [CareRecordCategory],
        analysis: CareAIAnalysis? = nil,
        condition: RecordCondition? = nil
    ) -> [CareAIRecordSuggestion] {
        let trimmed = KeywordFallbackCareSemanticAnalyzer.normalizedCareSpeechText(text)
        guard !trimmed.isEmpty else { return [] }

        return KeywordFallbackCareSemanticAnalyzer.buildRecordSuggestions(
            from: trimmed,
            categories: categories,
            analysis: analysis,
            condition: condition
        )
    }

    private static func buildFallbackSuggestions(
        from text: String,
        categories: [CareRecordCategory],
        condition: RecordCondition?,
        language: AppLanguage = .en
    ) -> [CareAIRecordSuggestion] {
        KeywordFallbackCareSemanticAnalyzer.buildSuggestions(
            from: text,
            categories: categories,
            condition: condition,
            outputLanguage: language
        )
    }

    private static func uniqueCategories(_ categories: [CareRecordCategory]) -> [CareRecordCategory] {
        var seen = Set<CareRecordCategory>()
        return categories.filter { seen.insert($0).inserted }
    }

    private static func finalizedRecordSuggestions(
        _ suggestions: [CareAIRecordSuggestion]
    ) -> [CareAIRecordSuggestion] {
        let scopedSuggestions: [CareAIRecordSuggestion] = suggestions.compactMap { suggestion in
            let scopedContent = finalCategoryContent(
                for: suggestion.category,
                in: suggestion.content
            )
            guard !scopedContent.isEmpty else { return nil }

            return CareAIRecordSuggestion(
                category: suggestion.category,
                condition: finalCondition(
                    current: suggestion.condition,
                    content: scopedContent
                ),
                content: scopedContent
            )
        }

        let containsMedicine = scopedSuggestions.contains { $0.category == .medicine }
        let filtered = scopedSuggestions.filter { suggestion in
            !(containsMedicine && suggestion.category == .food && !finalContainsFoodIntakeEvidence(in: suggestion.content))
        }

        return filtered.reduce(into: [CareAIRecordSuggestion]()) { result, suggestion in
            guard let index = result.firstIndex(where: { $0.category == suggestion.category }) else {
                result.append(suggestion)
                return
            }

            if suggestion.content.count > result[index].content.count {
                result[index] = suggestion
            }
        }
    }

    private static func finalCategoryContent(
        for category: CareRecordCategory,
        in text: String
    ) -> String {
        let trimmed = KeywordFallbackCareSemanticAnalyzer.normalizedCareSpeechText(text)

        switch category {
        case .food:
            return finalTrimmedRecordContent(
                finalPrefixBeforeFirstKeyword(in: trimmed, keywords: finalMedicationBoundaryKeywords + finalMedicineKeywords + finalBowelKeywords + finalMoodKeywords) ?? trimmed
            )
        case .medicine:
            return finalTrimmedRecordContent(
                finalSegment(from: finalMedicineKeywords, until: finalBowelKeywords + finalMoodKeywords, in: trimmed) ?? trimmed
            )
        case .bowel:
            return finalTrimmedRecordContent(
                finalSegment(from: finalBowelKeywords, until: finalMedicineKeywords + finalMoodKeywords, in: trimmed) ?? trimmed
            )
        case .mood:
            return finalTrimmedRecordContent(
                finalSegment(from: finalMoodKeywords, until: finalMedicineKeywords + finalBowelKeywords, in: trimmed) ?? trimmed
            )
        case .custom:
            return finalTrimmedRecordContent(trimmed)
        }
    }

    private static func finalCondition(
        current: RecordCondition,
        content: String
    ) -> RecordCondition {
        guard let inferred = KeywordFallbackCareSemanticAnalyzer.inferCondition(from: content, language: .zhTW) else {
            return current
        }

        if current == .normal, inferred == .good {
            return .good
        }

        return finalConditionSeverity(inferred) > finalConditionSeverity(current) ? inferred : current
    }

    private static func finalSegment(
        from startKeywords: [String],
        until boundaryKeywords: [String],
        in text: String
    ) -> String? {
        guard let startRange = finalFirstKeywordRange(in: text, keywords: startKeywords) else {
            return nil
        }

        let segmentStart = startRange.lowerBound
        let searchRange = startRange.upperBound..<text.endIndex
        let boundaryRange = boundaryKeywords
            .compactMap { keyword in
                text.range(
                    of: keyword,
                    options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                    range: searchRange
                )
            }
            .sorted { $0.lowerBound < $1.lowerBound }
            .first

        let segmentEnd = boundaryRange?.lowerBound ?? text.endIndex
        let content = String(text[segmentStart..<segmentEnd])
        return content.isEmpty ? nil : content
    }

    private static func finalTrimmedRecordContent(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "，,。；;、")))
    }

    private static func finalConditionSeverity(_ condition: RecordCondition) -> Int {
        switch condition {
        case .good:
            return 0
        case .normal:
            return 1
        case .bad:
            return 2
        }
    }

    private static func finalPrefixBeforeFirstKeyword(in text: String, keywords: [String]) -> String? {
        guard let range = finalFirstKeywordRange(in: text, keywords: keywords),
              range.lowerBound > text.startIndex
        else {
            return nil
        }

        let content = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        return content.isEmpty ? nil : content
    }

    private static func finalSuffixFromFirstKeyword(in text: String, keywords: [String]) -> String? {
        guard let range = finalFirstKeywordRange(in: text, keywords: keywords) else {
            return nil
        }

        let content = String(text[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return content.isEmpty ? nil : content
    }

    private static func finalFirstKeywordRange(in text: String, keywords: [String]) -> Range<String.Index>? {
        keywords
            .compactMap { text.range(of: $0, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) }
            .sorted { $0.lowerBound < $1.lowerBound }
            .first
    }

    private static func finalContainsFoodIntakeEvidence(in text: String) -> Bool {
        let normalized = KeywordFallbackCareSemanticAnalyzer.normalizedCareSpeechText(text)
        if finalFoodIntakeKeywords.contains(where: { keyword in
            normalized.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) != nil
        }) {
            return true
        }

        return finalNonMedicationEatingRange(in: normalized) != nil
    }

    private static func finalNonMedicationEatingRange(in text: String) -> Range<String.Index>? {
        let medicationTerms = ["藥", "藥物", "medicine", "medication", "meds", "pill"]
        var searchRange = text.startIndex..<text.endIndex

        while let range = text.range(
            of: "吃",
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            range: searchRange
        ) {
            let suffixEnd = text.index(range.upperBound, offsetBy: 4, limitedBy: text.endIndex) ?? text.endIndex
            let suffix = String(text[range.upperBound..<suffixEnd])
            if !medicationTerms.contains(where: { suffix.range(of: $0, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) != nil }) {
                return range
            }

            guard range.upperBound < text.endIndex else { break }
            searchRange = range.upperBound..<text.endIndex
        }

        return nil
    }

    private static let finalFoodIntakeKeywords = [
        "喝", "進食", "食慾", "完食", "幾口", "半碗", "一碗", "水", "牛奶", "水果", "粥",
        "ate", "drank", "drink", "appetite", "finished", "meal", "water", "milk", "fruit", "porridge"
    ]

    private static let finalMedicineKeywords = [
        "早餐後已服用", "午餐後已服用", "晚餐後已服用", "飯後已服用", "早餐後", "午餐後", "晚餐後", "飯後",
        "餐後已服用", "餐後", "已服用", "服用", "服藥後", "藥", "服藥", "用藥", "血壓", "血糖", "回診", "醫生", "藥物",
        "medicine", "medication", "meds", "pill", "dose", "blood pressure", "blood sugar"
    ]

    private static let finalMedicationBoundaryKeywords = [
        "早餐後已服用", "午餐後已服用", "晚餐後已服用", "飯後已服用", "餐後已服用",
        "早餐後以服用", "午餐後以服用", "晚餐後以服用", "飯後以服用", "餐後以服用",
        "早餐後", "午餐後", "晚餐後", "飯後", "餐後"
    ]

    private static let finalBowelKeywords = [
        "排便", "大便", "便秘", "腹瀉", "廁所", "解便", "stool", "bowel", "constipation", "diarrhea"
    ]

    private static let finalMoodKeywords = [
        "情緒", "心情", "精神", "焦慮", "開心", "沮喪", "疲倦", "mood", "calm", "anxious", "happy", "sad"
    ]
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
private extension CareAIService {
    struct FoundationModelsCareSemanticAnalyzer: CareSemanticAnalyzing {
        let engineName = "Foundation Models"

        func analyze(_ request: CareSemanticAnalysisRequest) async throws -> CareAIAnalysis {
            try await CareAIService.analyzeWithFoundationModels(
                request.text,
                language: request.outputLanguage
            )
        }
    }

    static func analyzeWithFoundationModels(_ text: String, language: AppLanguage) async throws -> CareAIAnalysis {
        let normalizedText = KeywordFallbackCareSemanticAnalyzer.normalizedCareSpeechText(text)
        let outputLanguage = language.foundationModelOutputLanguageName
        let session = LanguageModelSession(instructions: """
            You classify caregiver notes. Extract every relevant category, even when one note contains multiple events.
            Use custom only when none of food, medicine, bowel, or mood applies.
            Infer condition only from explicit evidence. bad means urgent or clearly abnormal; normal means mild concern; good means explicitly stable, completed as expected, or explicitly without symptoms.
            Treat negated symptoms such as "no dizziness", "no nausea", "沒有嗆咳", or "無頭暈" as reassuring evidence, not as mild concern.
            Completed meals, hydration, and medication taken as scheduled should be good unless the note also contains an unnegated concern.
            Also split the note into separate concise records in \(outputLanguage). Each record must contain only the facts for its category and have its own condition.
            Always write generated record content only in \(outputLanguage), regardless of the input language.
            """)
        let response = try await session.respond(
            to: normalizedText,
            generating: GeneratedCareAnalysis.self
        )

        let generatedSuggestions = normalizedGeneratedSuggestions(
            response.content.records.map {
                CareAIRecordSuggestion(
                    category: $0.category.careRecordCategory,
                    condition: $0.condition.recordCondition,
                    content: $0.content.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            },
            language: language
        )
        let categories = uniqueCategories(response.content.categories.map(\.careRecordCategory) + generatedSuggestions.map(\.category))
        let fallbackSuggestions = buildFallbackSuggestions(
            from: normalizedText,
            categories: categories,
            condition: response.content.condition?.recordCondition,
            language: language
        )
        let suggestions = categories.map { category in
            preferredSuggestion(
                generated: generatedSuggestions.first(where: { $0.category == category && !$0.content.isEmpty }),
                fallback: fallbackSuggestions.first(where: { $0.category == category })
            ) ?? CareAIRecordSuggestion(category: category, condition: .normal, content: normalizedText)
        }

        return CareAIAnalysis(
            categories: categories.isEmpty ? [.custom] : categories,
            condition: response.content.condition?.recordCondition,
            suggestions: suggestions,
            usedOnDeviceModel: true
        )
    }

    static func normalizedGeneratedSuggestions(
        _ suggestions: [CareAIRecordSuggestion],
        language: AppLanguage
    ) -> [CareAIRecordSuggestion] {
        let normalized: [CareAIRecordSuggestion] = suggestions.compactMap { suggestion in
            let content = suggestion.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else { return nil }

            let classifiedCategories = KeywordFallbackCareSemanticAnalyzer.classifyCategories(content, language: language)
            let category = classifiedCategories.count > 1 && classifiedCategories.contains(suggestion.category)
                ? suggestion.category
                : (dominantCategory(for: content, language: language) ?? suggestion.category)
            let scopedContent = categorySpecificContent(for: category, in: content)
            let condition = correctedCondition(
                suggestion.condition,
                content: scopedContent,
                language: language
            )

            return CareAIRecordSuggestion(
                category: category,
                condition: condition,
                content: scopedContent
            )
        }

        let containsMedicine = normalized.contains { $0.category == .medicine }
        let filtered = normalized.filter { suggestion in
            !(containsMedicine && suggestion.category == .food && !containsFoodIntakeEvidence(in: suggestion.content))
        }

        return deduplicatedSuggestions(filtered)
    }

    static func preferredSuggestion(
        generated: CareAIRecordSuggestion?,
        fallback: CareAIRecordSuggestion?
    ) -> CareAIRecordSuggestion? {
        guard let generated else { return fallback }
        guard let fallback else { return generated }

        let generatedContent = generated.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackContent = fallback.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fallbackContent.isEmpty else { return generated }
        guard !generatedContent.isEmpty else { return fallback }

        if fallbackContent.count > generatedContent.count {
            return CareAIRecordSuggestion(
                category: generated.category,
                condition: conditionSeverity(fallback.condition) > conditionSeverity(generated.condition) ? fallback.condition : generated.condition,
                content: fallbackContent
            )
        }

        return generated
    }

    static func dominantCategory(for text: String, language: AppLanguage) -> CareRecordCategory? {
        let categories = KeywordFallbackCareSemanticAnalyzer.classifyCategories(text, language: language)
        if categories.contains(.medicine) { return .medicine }
        if categories.contains(.bowel) { return .bowel }
        if categories.contains(.food) { return .food }
        if categories.contains(.mood) { return .mood }
        return categories.first == .custom ? nil : categories.first
    }

    static func deduplicatedSuggestions(_ suggestions: [CareAIRecordSuggestion]) -> [CareAIRecordSuggestion] {
        suggestions.reduce(into: [CareAIRecordSuggestion]()) { result, suggestion in
            guard let index = result.firstIndex(where: { $0.category == suggestion.category }) else {
                result.append(suggestion)
                return
            }

            if suggestion.content.count > result[index].content.count {
                result[index] = suggestion
            }
        }
    }

    static func categorySpecificContent(
        for category: CareRecordCategory,
        in text: String
    ) -> String {
        let trimmed = KeywordFallbackCareSemanticAnalyzer.normalizedCareSpeechText(text)
        switch category {
        case .food:
            return trimmedRecordContent(prefixBeforeFirstKeyword(in: trimmed, keywords: medicationBoundaryKeywords + medicineKeywords + bowelKeywords + moodKeywords) ?? trimmed)
        case .medicine:
            return trimmedRecordContent(segment(from: medicineKeywords, until: bowelKeywords + moodKeywords, in: trimmed) ?? trimmed)
        case .bowel:
            return trimmedRecordContent(segment(from: bowelKeywords, until: medicineKeywords + moodKeywords, in: trimmed) ?? trimmed)
        case .mood:
            return trimmedRecordContent(segment(from: moodKeywords, until: medicineKeywords + bowelKeywords, in: trimmed) ?? trimmed)
        case .custom:
            return trimmedRecordContent(trimmed)
        }
    }

    static func prefixBeforeFirstKeyword(in text: String, keywords: [String]) -> String? {
        guard let range = firstKeywordRange(in: text, keywords: keywords),
              range.lowerBound > text.startIndex
        else {
            return nil
        }

        let content = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        return content.isEmpty ? nil : content
    }

    static func suffixFromFirstKeyword(in text: String, keywords: [String]) -> String? {
        guard let range = firstKeywordRange(in: text, keywords: keywords) else {
            return nil
        }

        let content = String(text[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return content.isEmpty ? nil : content
    }

    static func segment(
        from startKeywords: [String],
        until boundaryKeywords: [String],
        in text: String
    ) -> String? {
        guard let startRange = firstKeywordRange(in: text, keywords: startKeywords) else {
            return nil
        }

        let searchRange = startRange.upperBound..<text.endIndex
        let boundaryRange = boundaryKeywords
            .compactMap { keyword in
                text.range(
                    of: keyword,
                    options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                    range: searchRange
                )
            }
            .sorted { $0.lowerBound < $1.lowerBound }
            .first

        let segmentEnd = boundaryRange?.lowerBound ?? text.endIndex
        let content = String(text[startRange.lowerBound..<segmentEnd])
        return content.isEmpty ? nil : content
    }

    static func trimmedRecordContent(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "，,。；;、")))
    }

    static func firstKeywordRange(in text: String, keywords: [String]) -> Range<String.Index>? {
        keywords
            .compactMap { text.range(of: $0, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) }
            .sorted { $0.lowerBound < $1.lowerBound }
            .first
    }

    static let medicineKeywords = [
        "早餐後已服用", "午餐後已服用", "晚餐後已服用", "飯後已服用", "餐後已服用",
        "早餐後", "午餐後", "晚餐後", "飯後", "餐後",
        "已服用", "服用", "服藥後", "藥", "服藥", "用藥", "血壓", "血糖", "回診", "醫生", "藥物",
        "medicine", "medication", "meds", "pill", "dose", "blood pressure", "blood sugar"
    ]

    static let medicationBoundaryKeywords = [
        "早餐後已服用", "午餐後已服用", "晚餐後已服用", "飯後已服用", "餐後已服用",
        "早餐後以服用", "午餐後以服用", "晚餐後以服用", "飯後以服用", "餐後以服用",
        "早餐後", "午餐後", "晚餐後", "飯後", "餐後"
    ]

    static let bowelKeywords = [
        "排便", "大便", "便秘", "腹瀉", "廁所", "解便", "stool", "bowel", "constipation", "diarrhea"
    ]

    static let moodKeywords = [
        "情緒", "心情", "精神", "焦慮", "開心", "沮喪", "疲倦", "mood", "calm", "anxious", "happy", "sad"
    ]

    static func containsFoodIntakeEvidence(in text: String) -> Bool {
        let keywords = [
            "喝", "進食", "食慾", "完食", "幾口", "半碗", "一碗", "水", "牛奶", "水果", "粥",
            "ate", "drank", "drink", "appetite", "finished", "meal", "water", "milk", "fruit", "porridge"
        ]
        if keywords.contains(where: { keyword in
            text.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) != nil
        }) {
            return true
        }

        return finalNonMedicationEatingRange(in: text) != nil
    }

    static func correctedCondition(
        _ condition: RecordCondition,
        content: String,
        language: AppLanguage
    ) -> RecordCondition {
        guard let fallbackCondition = KeywordFallbackCareSemanticAnalyzer.inferCondition(
            from: content,
            language: language
        ) else {
            return condition
        }

        if condition == .normal, fallbackCondition == .good {
            return .good
        }

        return conditionSeverity(fallbackCondition) > conditionSeverity(condition) ? fallbackCondition : condition
    }

    static func conditionSeverity(_ condition: RecordCondition) -> Int {
        switch condition {
        case .good:
            return 0
        case .normal:
            return 1
        case .bad:
            return 2
        }
    }

    static func summarizeWithFoundationModels(
        _ records: [CareRecord],
        language: AppLanguage
    ) async throws -> CareAISummary {
        let recordText = records
            .sorted { $0.createdAt < $1.createdAt }
            .map {
                "[\($0.createdAt.formatted(date: .abbreviated, time: .shortened))] \($0.category.displayName) / \($0.condition?.displayName ?? "Not evaluated"): \($0.content)"
            }
            .joined(separator: "\n")

        let outputLanguage = language.foundationModelOutputLanguageName
        let session = LanguageModelSession(instructions: """
            You create a factual caregiver shift handoff in \(outputLanguage).
            Mention important food, medication, bowel, mood, and safety facts. Do not invent diagnoses or medical advice.
            Include only facts found in the supplied records. Preserve medication names, dosages, times, measurements, and quantities exactly.
            Do not add explanations, diagnoses, recommendations, or events that are absent from the records.
            Keep the summary concise. Mark danger only for urgent explicit symptoms, warning for observations needing follow-up, otherwise good.
            Write only in \(outputLanguage), regardless of the record language.
            """)
        let response = try await session.respond(
            to: recordText,
            generating: GeneratedCareSummary.self
        )
        return CareAISummary(
            text: response.content.summary,
            status: response.content.status.careStatus,
            usedOnDeviceModel: true
        )
    }
}

@available(iOS 26.0, *)
private extension GeneratedCareCategory {
    var careRecordCategory: CareRecordCategory {
        switch self {
        case .food: return .food
        case .medicine: return .medicine
        case .bowel: return .bowel
        case .mood: return .mood
        case .custom: return .custom
        }
    }
}

@available(iOS 26.0, *)
private extension GeneratedCareCondition {
    var recordCondition: RecordCondition {
        switch self {
        case .good: return .good
        case .normal: return .normal
        case .bad: return .bad
        }
    }
}

@available(iOS 26.0, *)
private extension GeneratedCareStatus {
    var careStatus: CareStatus {
        switch self {
        case .good: return .good
        case .warning: return .warning
        case .danger: return .danger
        }
    }
}
#endif
