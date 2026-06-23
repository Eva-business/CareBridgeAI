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
    var category: GeneratedCareCategory

    var condition: GeneratedCareCondition

    @Guide(description: "A short English factual record for only this category")
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
@Generable
private enum GeneratedCareCondition {
    case good
    case normal
    case bad
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedCareSummary {
    @Guide(description: "A concise English caregiver handoff summary")
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
    static func analyze(_ text: String) async -> CareAIAnalysis {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return CareAIAnalysis(categories: [], condition: nil, suggestions: [], usedOnDeviceModel: false)
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.availability == .available {
            do {
                return try await analyzeWithFoundationModels(trimmed)
            } catch {
                // The deterministic fallback keeps recording available if the model refuses or is busy.
            }
        }
        #endif

        let categories = classifyCategories(trimmed)
        let condition = inferCondition(from: trimmed)
        return CareAIAnalysis(
            categories: categories,
            condition: condition,
            suggestions: buildFallbackSuggestions(from: trimmed, categories: categories, condition: condition),
            usedOnDeviceModel: false
        )
    }

    static func summarize(
        _ records: [CareRecord],
        applying24HourWindow: Bool = true
    ) async -> CareAISummary {
        let recentRecords: [CareRecord]
        if applying24HourWindow {
            let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
            recentRecords = records.filter { $0.createdAt >= cutoff }
        } else {
            recentRecords = records
        }

        guard !recentRecords.isEmpty else {
            let text = generateSummary(from: recentRecords)
            return CareAISummary(text: text, status: .good, usedOnDeviceModel: false)
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.availability == .available {
            do {
                let result = try await summarizeWithFoundationModels(recentRecords)
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

        let text = generateSummary(from: recentRecords)
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
        var categories: [CareRecordCategory] = []

        let foodKeywords = ["吃", "飯", "早餐", "午餐", "晚餐", "喝水", "食慾", "牛奶", "水果", "進食", "粥"]
        let medicineKeywords = ["藥", "服藥", "用藥", "血壓", "血糖", "回診", "醫生", "藥物", "健保卡", "忘記吃藥", "漏吃藥"]
        let bowelKeywords = ["排便", "大便", "小便", "便秘", "腹瀉", "尿", "廁所"]
        let moodKeywords = ["情緒", "開心", "難過", "焦慮", "生氣", "失眠", "睡", "哭", "笑", "平穩"]

        if foodKeywords.contains(where: { text.contains($0) }) { categories.append(.food) }
        if medicineKeywords.contains(where: { text.contains($0) }) { categories.append(.medicine) }
        if bowelKeywords.contains(where: { text.contains($0) }) { categories.append(.bowel) }
        if moodKeywords.contains(where: { text.contains($0) }) { categories.append(.mood) }

        return categories.isEmpty ? [.custom] : categories
    }

    static func inferCondition(from text: String) -> RecordCondition? {
        let badKeywords = ["不好", "發燒", "跌倒", "嘔吐", "呼吸困難", "胸痛", "昏倒", "劇痛", "無法進食", "意識不清", "忘記", "漏吃", "沒吃藥", "未服藥"]
        let normalKeywords = ["普通", "還好", "尚可", "咳嗽", "食慾差", "頭暈", "疲倦", "便秘", "腹瀉", "不舒服"]
        let goodKeywords = ["正常", "良好", "穩定", "有吃", "按時", "平穩", "開心", "不錯", "精神好", "精神還不錯"]

        if badKeywords.contains(where: { text.contains($0) }) { return .bad }
        if normalKeywords.contains(where: { text.contains($0) }) { return .normal }
        if goodKeywords.contains(where: { text.contains($0) }) { return .good }
        return nil
    }

    static func generateRecordsFromText(
        _ text: String,
        selectedCategories: [CareRecordCategory],
        analysis: CareAIAnalysis? = nil,
        condition: RecordCondition? = nil
    ) -> [CareRecord] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let categories = uniqueCategories(selectedCategories.isEmpty ? (analysis?.categories ?? classifyCategories(trimmed)) : selectedCategories)
        let resolvedCondition = condition ?? analysis?.condition ?? inferCondition(from: trimmed)
        let suggestions = buildRecordSuggestions(
            from: trimmed,
            categories: categories,
            analysis: analysis,
            condition: resolvedCondition
        )

        return suggestions.map {
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

    static func generateSummary(from records: [CareRecord]) -> String {
        let sortedRecords = records.sorted { $0.createdAt > $1.createdAt }
        guard !sortedRecords.isEmpty else {
            return "No care records have been added today. No clear abnormal information is available yet."
        }

        var parts: [String] = []
        for category in CareRecordCategory.allCases {
            if let latest = sortedRecords.first(where: { $0.category == category }) {
                parts.append("\(category.displayName): \(latest.content.careBridgeEnglishCareDisplayValue)")
            }
        }

        let badCount = sortedRecords.filter { $0.condition == .bad }.count
        let normalCount = sortedRecords.filter { $0.condition == .normal }.count
        if badCount > 0 {
            parts.append("\(badCount) record(s) indicate poor condition today. Please review promptly.")
        } else if normalCount > 0 {
            parts.append("\(normalCount) record(s) need follow-up observation today.")
        } else {
            parts.append("Overall status is currently stable.")
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
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let selectedCategories = uniqueCategories(categories.isEmpty ? classifyCategories(trimmed) : categories)
        let analyzedSuggestions = analysis?.suggestions ?? []

        return selectedCategories.map { category in
            if let suggestion = analyzedSuggestions.first(where: { $0.category == category }) {
                return suggestion
            }

            let content = extractContent(for: category, from: trimmed)
            let resolvedCondition = inferCondition(from: content) ?? (selectedCategories.count == 1 ? condition : nil) ?? .normal
            return CareAIRecordSuggestion(
                category: category,
                condition: resolvedCondition,
                content: content
            )
        }
    }

    private static func buildFallbackSuggestions(
        from text: String,
        categories: [CareRecordCategory],
        condition: RecordCondition?
    ) -> [CareAIRecordSuggestion] {
        buildRecordSuggestions(from: text, categories: categories, condition: condition)
    }

    private static func uniqueCategories(_ categories: [CareRecordCategory]) -> [CareRecordCategory] {
        var seen = Set<CareRecordCategory>()
        return categories.filter { seen.insert($0).inserted }
    }

    private static func extractContent(for category: CareRecordCategory, from text: String) -> String {
        let clauses = splitClauses(text)
        let matchedClauses = clauses.filter {
            let primaryCategory = primaryCategory(for: $0)
            if primaryCategory == category {
                return true
            }
            if category == .mood, clauseContains($0, category: .mood) {
                return true
            }
            return primaryCategory == nil && clauseContains($0, category: category)
        }

        let content = matchedClauses
            .map { focusedClause($0, for: category) }
            .filter { !$0.isEmpty }
            .joined(separator: "，")

        return content.isEmpty ? text : content
    }

    private static func splitClauses(_ text: String) -> [String] {
        var normalized = text
        ["但是", "可是", "不過", "而且", "另外", "然後", "並且"].forEach {
            normalized = normalized.replacingOccurrences(of: $0, with: "，")
        }

        return normalized
            .split { "，,。；;\n".contains($0) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func clauseContains(_ clause: String, category: CareRecordCategory) -> Bool {
        categoryKeywords(for: category).contains { clause.contains($0) }
    }

    private static func primaryCategory(for clause: String) -> CareRecordCategory? {
        if clauseContains(clause, category: .medicine) { return .medicine }
        if clauseContains(clause, category: .bowel) { return .bowel }
        if clauseContains(clause, category: .food) { return .food }
        if clauseContains(clause, category: .mood) { return .mood }
        return nil
    }

    private static func focusedClause(_ clause: String, for category: CareRecordCategory) -> String {
        switch category {
        case .food:
            return prefixBeforeFirstKeyword(in: clause, keywords: categoryKeywords(for: .mood)) ?? clause
        case .mood:
            return suffixFromFirstKeyword(in: clause, keywords: categoryKeywords(for: .mood)) ?? clause
        case .medicine, .bowel, .custom:
            return clause
        }
    }

    private static func prefixBeforeFirstKeyword(in text: String, keywords: [String]) -> String? {
        guard let range = firstKeywordRange(in: text, keywords: keywords), range.lowerBound > text.startIndex else {
            return nil
        }
        return String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func suffixFromFirstKeyword(in text: String, keywords: [String]) -> String? {
        guard let range = firstKeywordRange(in: text, keywords: keywords) else {
            return nil
        }
        return String(text[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstKeywordRange(in text: String, keywords: [String]) -> Range<String.Index>? {
        keywords
            .compactMap { text.range(of: $0) }
            .sorted { $0.lowerBound < $1.lowerBound }
            .first
    }

    private static func categoryKeywords(for category: CareRecordCategory) -> [String] {
        switch category {
        case .food:
            return ["吃", "飯", "早餐", "午餐", "晚餐", "喝水", "食慾", "牛奶", "水果", "進食", "粥"]
        case .medicine:
            return ["藥", "服藥", "用藥", "血壓", "血糖", "回診", "醫生", "藥物", "健保卡", "忘記吃藥", "漏吃藥", "未服藥"]
        case .bowel:
            return ["排便", "大便", "小便", "便秘", "腹瀉", "尿", "廁所"]
        case .mood:
            return ["情緒", "開心", "難過", "焦慮", "生氣", "失眠", "睡", "哭", "笑", "平穩", "精神", "不錯"]
        case .custom:
            return []
        }
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
private extension CareAIService {
    static func analyzeWithFoundationModels(_ text: String) async throws -> CareAIAnalysis {
        let session = LanguageModelSession(instructions: """
            You classify caregiver notes. Extract every relevant category, even when one note contains multiple events.
            Use custom only when none of food, medicine, bowel, or mood applies.
            Infer condition only from explicit evidence. bad means urgent or clearly abnormal; normal means mild concern; good means explicitly stable.
            Also split the note into separate concise English records. Each record must contain only the facts for its category and have its own condition.
            Always write generated record content in English, regardless of the input language.
            """)
        let response = try await session.respond(
            to: text,
            generating: GeneratedCareAnalysis.self
        )

        let generatedSuggestions = response.content.records.map {
            CareAIRecordSuggestion(
                category: $0.category.careRecordCategory,
                condition: $0.condition.recordCondition,
                content: $0.content.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        let categories = uniqueCategories(response.content.categories.map(\.careRecordCategory) + generatedSuggestions.map(\.category))
        let fallbackSuggestions = buildFallbackSuggestions(
            from: text,
            categories: categories,
            condition: response.content.condition?.recordCondition
        )
        let suggestions = categories.map { category in
            generatedSuggestions.first(where: { $0.category == category && !$0.content.isEmpty })
            ?? fallbackSuggestions.first(where: { $0.category == category })
            ?? CareAIRecordSuggestion(category: category, condition: .normal, content: text)
        }

        return CareAIAnalysis(
            categories: categories.isEmpty ? [.custom] : categories,
            condition: response.content.condition?.recordCondition,
            suggestions: suggestions,
            usedOnDeviceModel: true
        )
    }

    static func summarizeWithFoundationModels(_ records: [CareRecord]) async throws -> CareAISummary {
        let recordText = records
            .sorted { $0.createdAt < $1.createdAt }
            .map {
                "[\($0.createdAt.formatted(date: .abbreviated, time: .shortened))] \($0.category.displayName) / \($0.condition?.displayName ?? "Not evaluated"): \($0.content)"
            }
            .joined(separator: "\n")

        let session = LanguageModelSession(instructions: """
            You create a factual caregiver shift handoff in English.
            Mention important food, medication, bowel, mood, and safety facts. Do not invent diagnoses or medical advice.
            Keep the summary under 80 English words. Mark danger only for urgent explicit symptoms, warning for observations needing follow-up, otherwise good.
            Always write the summary in English, regardless of the record language.
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
