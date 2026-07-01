import Foundation
import NaturalLanguage

struct CareSemanticAnalysisRequest {
    let text: String
    let outputLanguage: AppLanguage
}

protocol CareSemanticAnalyzing {
    var engineName: String { get }
    func analyze(_ request: CareSemanticAnalysisRequest) async throws -> CareAIAnalysis
}

struct CareSemanticAnalyzerPipeline {
    private let analyzers: [CareSemanticAnalyzing]

    init(analyzers: [CareSemanticAnalyzing]) {
        self.analyzers = analyzers
    }

    func analyze(_ request: CareSemanticAnalysisRequest) async -> CareAIAnalysis {
        for analyzer in analyzers {
            do {
                return try await analyzer.analyze(request)
            } catch {
                continue
            }
        }

        return CareAIAnalysis(categories: [.custom], condition: nil, suggestions: [], usedOnDeviceModel: false)
    }
}

struct KeywordFallbackCareSemanticAnalyzer: CareSemanticAnalyzing {
    let engineName = "Keyword fallback"

    func analyze(_ request: CareSemanticAnalysisRequest) async throws -> CareAIAnalysis {
        let trimmed = Self.normalizedCareSpeechText(request.text)
        guard !trimmed.isEmpty else {
            return CareAIAnalysis(categories: [], condition: nil, suggestions: [], usedOnDeviceModel: false)
        }

        let context = CareSemanticLanguageContext(text: trimmed, outputLanguage: request.outputLanguage)
        let categories = Self.classifyCategories(trimmed, context: context)
        let condition = Self.inferCondition(from: trimmed, context: context)
        let suggestions = Self.buildSuggestions(
            from: trimmed,
            categories: categories,
            condition: condition,
            outputLanguage: request.outputLanguage,
            context: context
        )

        return CareAIAnalysis(
            categories: categories,
            condition: condition,
            suggestions: suggestions,
            usedOnDeviceModel: false
        )
    }
}

extension KeywordFallbackCareSemanticAnalyzer {
    static func normalizedCareSpeechText(_ text: String) -> String {
        var normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        [
            ("餐後以服用", "餐後已服用"),
            ("早餐後以服用", "早餐後已服用"),
            ("午餐後以服用", "午餐後已服用"),
            ("晚餐後以服用", "晚餐後已服用"),
            ("飯後以服用", "飯後已服用"),
            ("用降血壓壓藥", "用降血壓藥"),
            ("服用降血壓壓藥", "服用降血壓藥"),
            ("降血壓壓藥", "降血壓藥")
        ].forEach { typo, correction in
            normalized = normalized.replacingOccurrences(of: typo, with: correction)
        }
        return normalized
    }

    static func classifyCategories(_ text: String, language: AppLanguage = .zhTW) -> [CareRecordCategory] {
        let normalized = normalizedCareSpeechText(text)
        return classifyCategories(normalized, context: CareSemanticLanguageContext(text: normalized, outputLanguage: language))
    }

    static func inferCondition(from text: String, language: AppLanguage = .zhTW) -> RecordCondition? {
        let normalized = normalizedCareSpeechText(text)
        return inferCondition(from: normalized, context: CareSemanticLanguageContext(text: normalized, outputLanguage: language))
    }

    static func buildSuggestions(
        from text: String,
        categories: [CareRecordCategory],
        condition: RecordCondition?,
        outputLanguage: AppLanguage = .en
    ) -> [CareAIRecordSuggestion] {
        let normalized = normalizedCareSpeechText(text)
        return buildSuggestions(
            from: normalized,
            categories: categories,
            condition: condition,
            outputLanguage: outputLanguage,
            context: CareSemanticLanguageContext(text: normalized, outputLanguage: outputLanguage)
        )
    }

    static func buildRecordSuggestions(
        from text: String,
        categories: [CareRecordCategory],
        analysis: CareAIAnalysis? = nil,
        condition: RecordCondition? = nil
    ) -> [CareAIRecordSuggestion] {
        let trimmed = normalizedCareSpeechText(text)
        guard !trimmed.isEmpty else { return [] }

        let context = CareSemanticLanguageContext(text: trimmed, outputLanguage: .en)
        let selectedCategories = uniqueCategories(categories.isEmpty ? classifyCategories(trimmed, context: context) : categories)
        let analyzedSuggestions = analysis?.suggestions ?? []

        return selectedCategories.map { category in
            if let suggestion = analyzedSuggestions.first(where: { $0.category == category }) {
                return suggestion
            }

            let content = extractContent(for: category, from: trimmed, context: context)
            let resolvedCondition = inferCondition(from: content, context: context) ?? (selectedCategories.count == 1 ? condition : nil) ?? .normal
            return CareAIRecordSuggestion(
                category: category,
                condition: resolvedCondition,
                content: content
            )
        }
    }
}

private extension KeywordFallbackCareSemanticAnalyzer {
    static func classifyCategories(_ text: String, context: CareSemanticLanguageContext) -> [CareRecordCategory] {
        var categories: [CareRecordCategory] = []

        for category in CareRecordCategory.allCases where category != .custom {
            if containsAnyKeyword(in: text, keywords: CareSemanticLexicon.categoryKeywords(for: category, context: context)) {
                categories.append(category)
            }
        }

        if categories.contains(.medicine),
           categories.contains(.food),
           !containsFoodIntakeEvidence(in: text) {
            categories.removeAll { $0 == .food }
        }

        return categories.isEmpty ? [.custom] : categories
    }

    static func inferCondition(from text: String, context: CareSemanticLanguageContext) -> RecordCondition? {
        if containsAnyNonNegatedKeyword(in: text, keywords: CareSemanticLexicon.conditionKeywords(for: .bad, context: context)) {
            return .bad
        }

        if containsAnyNonNegatedKeyword(in: text, keywords: CareSemanticLexicon.conditionKeywords(for: .normal, context: context)) {
            return .normal
        }

        if containsAnyKeyword(in: text, keywords: CareSemanticLexicon.conditionKeywords(for: .good, context: context)) {
            return .good
        }

        return nil
    }

    static func buildSuggestions(
        from text: String,
        categories: [CareRecordCategory],
        condition: RecordCondition?,
        outputLanguage: AppLanguage,
        context: CareSemanticLanguageContext
    ) -> [CareAIRecordSuggestion] {
        buildRecordSuggestions(from: text, categories: categories, condition: condition).map { suggestion in
            guard outputLanguage.usesDynamicTargetTranslation else { return suggestion }
            return CareAIRecordSuggestion(
                category: suggestion.category,
                condition: suggestion.condition,
                content: suggestion.content.localizedCareText(outputLanguage)
            )
        }
    }

    static func uniqueCategories(_ categories: [CareRecordCategory]) -> [CareRecordCategory] {
        var seen = Set<CareRecordCategory>()
        return categories.filter { seen.insert($0).inserted }
    }

    static func extractContent(for category: CareRecordCategory, from text: String, context: CareSemanticLanguageContext) -> String {
        let clauses = splitClauses(text)
        let matchedClauses = clauses.filter {
            let primaryCategory = primaryCategory(for: $0, context: context)
            if primaryCategory == category {
                return true
            }
            if clauseContains($0, category: category, context: context),
               containsMultiplePrimaryCategories(in: $0, context: context) {
                return true
            }
            if category == .mood, clauseContains($0, category: .mood, context: context) {
                return true
            }
            return primaryCategory == nil && clauseContains($0, category: category, context: context)
        }

        let content = matchedClauses
            .map { focusedClause($0, for: category, context: context) }
            .filter { !$0.isEmpty }
            .joined(separator: context.clauseJoiner)

        return content.isEmpty ? text : content
    }

    static func splitClauses(_ text: String) -> [String] {
        var normalized = text
        CareSemanticLexicon.clauseConnectors.forEach {
            normalized = normalized.replacingOccurrences(of: $0, with: "，")
        }

        return normalized
            .split { CareSemanticLexicon.clauseSeparators.contains($0) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func clauseContains(_ clause: String, category: CareRecordCategory, context: CareSemanticLanguageContext) -> Bool {
        containsAnyKeyword(in: clause, keywords: CareSemanticLexicon.categoryKeywords(for: category, context: context))
    }

    static func containsMultiplePrimaryCategories(in clause: String, context: CareSemanticLanguageContext) -> Bool {
        [CareRecordCategory.food, .medicine, .bowel, .mood].filter {
            clauseContains(clause, category: $0, context: context)
        }.count > 1
    }

    static func primaryCategory(for clause: String, context: CareSemanticLanguageContext) -> CareRecordCategory? {
        if clauseContains(clause, category: .medicine, context: context) { return .medicine }
        if clauseContains(clause, category: .bowel, context: context) { return .bowel }
        if clauseContains(clause, category: .food, context: context) { return .food }
        if clauseContains(clause, category: .mood, context: context) { return .mood }
        return nil
    }

    static func focusedClause(_ clause: String, for category: CareRecordCategory, context: CareSemanticLanguageContext) -> String {
        switch category {
        case .food:
            return prefixBeforeFirstKeyword(
                in: clause,
                keywords: medicationBoundaryKeywords(context: context)
                    + CareSemanticLexicon.categoryKeywords(for: .medicine, context: context)
                    + CareSemanticLexicon.categoryKeywords(for: .bowel, context: context)
                    + CareSemanticLexicon.categoryKeywords(for: .mood, context: context)
            ) ?? clause
        case .mood:
            return suffixFromFirstKeyword(in: clause, keywords: CareSemanticLexicon.categoryKeywords(for: .mood, context: context)) ?? clause
        case .medicine:
            return suffixFromFirstKeyword(in: clause, keywords: CareSemanticLexicon.categoryKeywords(for: .medicine, context: context)) ?? clause
        case .bowel:
            return suffixFromFirstKeyword(in: clause, keywords: CareSemanticLexicon.categoryKeywords(for: .bowel, context: context)) ?? clause
        case .custom:
            return clause
        }
    }

    static func prefixBeforeFirstKeyword(in text: String, keywords: [String]) -> String? {
        guard let range = firstKeywordRange(in: text, keywords: keywords), range.lowerBound > text.startIndex else {
            return nil
        }
        return String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func suffixFromFirstKeyword(in text: String, keywords: [String]) -> String? {
        guard let range = firstKeywordRange(in: text, keywords: keywords) else {
            return nil
        }
        return String(text[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func medicationBoundaryKeywords(context: CareSemanticLanguageContext) -> [String] {
        let zhTW = [
            "早餐後已服用", "午餐後已服用", "晚餐後已服用", "飯後已服用", "餐後已服用",
            "早餐後以服用", "午餐後以服用", "晚餐後以服用", "飯後以服用", "餐後以服用",
            "早餐後", "午餐後", "晚餐後", "飯後", "餐後"
        ]

        return zhTW
    }

    static func firstKeywordRange(in text: String, keywords: [String]) -> Range<String.Index>? {
        keywords
            .compactMap { keywordRange(in: text, keyword: $0) }
            .sorted { $0.lowerBound < $1.lowerBound }
            .first
    }

    static func containsAnyKeyword(in text: String, keywords: [String]) -> Bool {
        keywords.contains { keywordRange(in: text, keyword: $0) != nil }
    }

    static func containsAnyNonNegatedKeyword(in text: String, keywords: [String]) -> Bool {
        keywords.contains { nonNegatedKeywordRange(in: text, keyword: $0) != nil }
    }

    static func keywordRange(in text: String, keyword: String) -> Range<String.Index>? {
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]
        var searchRange = text.startIndex..<text.endIndex

        while let range = text.range(of: keyword, options: options, range: searchRange) {
            if !keywordNeedsWordBoundaries(keyword) || hasWordBoundaries(range, in: text) {
                return range
            }

            guard range.upperBound < text.endIndex else {
                return nil
            }
            searchRange = range.upperBound..<text.endIndex
        }

        return nil
    }

    static func nonNegatedKeywordRange(in text: String, keyword: String) -> Range<String.Index>? {
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]
        var searchRange = text.startIndex..<text.endIndex

        while let range = text.range(of: keyword, options: options, range: searchRange) {
            if (!keywordNeedsWordBoundaries(keyword) || hasWordBoundaries(range, in: text))
                && !isNegated(range, in: text) {
                return range
            }

            guard range.upperBound < text.endIndex else {
                return nil
            }
            searchRange = range.upperBound..<text.endIndex
        }

        return nil
    }

    static func isNegated(_ range: Range<String.Index>, in text: String) -> Bool {
        let prefixStart = text.index(range.lowerBound, offsetBy: -6, limitedBy: text.startIndex) ?? text.startIndex
        let prefix = String(text[prefixStart..<range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if [
            "無", "沒有", "没", "未", "未見", "未發現", "無明顯", "沒有明顯",
            "no", "not", "without", "none"
        ].contains(where: { prefix.hasSuffix($0) }) {
            return true
        }

        let clauseStart = text[..<range.lowerBound].lastIndex {
            CareSemanticLexicon.clauseSeparators.contains($0)
        }.map { text.index(after: $0) } ?? text.startIndex
        var clausePrefix = String(text[clauseStart..<range.lowerBound])

        ["但是", "可是", "不過", "但", "however", "but"].forEach { contrast in
            if let contrastRange = clausePrefix.range(of: contrast, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) {
                clausePrefix = String(clausePrefix[contrastRange.upperBound...])
            }
        }

        return ["無", "沒有", "没", "未", "no ", "not ", "without "].contains { negator in
            clausePrefix.range(of: negator, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) != nil
        }
    }

    static func keywordNeedsWordBoundaries(_ keyword: String) -> Bool {
        keyword.unicodeScalars.allSatisfy {
            CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 '-").contains($0)
        }
    }

    static func hasWordBoundaries(_ range: Range<String.Index>, in text: String) -> Bool {
        let hasLeadingBoundary: Bool
        if range.lowerBound == text.startIndex {
            hasLeadingBoundary = true
        } else {
            let previousIndex = text.index(before: range.lowerBound)
            hasLeadingBoundary = !isWordCharacter(text[previousIndex])
        }

        let hasTrailingBoundary: Bool
        if range.upperBound == text.endIndex {
            hasTrailingBoundary = true
        } else {
            hasTrailingBoundary = !isWordCharacter(text[range.upperBound])
        }

        return hasLeadingBoundary && hasTrailingBoundary
    }

    static func isWordCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.contains { CharacterSet.alphanumerics.contains($0) }
    }

    static func containsFoodIntakeEvidence(in text: String) -> Bool {
        let normalized = normalizedCareSpeechText(text)
        if containsAnyKeyword(
            in: normalized,
            keywords: ["喝", "進食", "食慾", "完食", "幾口", "半碗", "一碗", "水", "牛奶", "水果", "粥",
                       "ate", "drank", "drink", "appetite", "finished", "meal", "water", "milk", "fruit", "porridge"]
        ) {
            return true
        }

        return nonMedicationEatingRange(in: normalized) != nil
    }

    static func nonMedicationEatingRange(in text: String) -> Range<String.Index>? {
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
}

struct CareSemanticLanguageContext {
    let text: String
    let outputLanguage: AppLanguage
    let detectedLanguage: AppLanguage?

    init(text: String, outputLanguage: AppLanguage) {
        self.text = text
        self.outputLanguage = outputLanguage
        self.detectedLanguage = Self.detectAppLanguage(in: text)
    }

    var candidateLanguages: [AppLanguage] {
        var languages: [AppLanguage] = []
        [detectedLanguage, outputLanguage, .zhTW, .en].compactMap { $0 }.forEach {
            if !languages.contains($0) {
                languages.append($0)
            }
        }
        return languages
    }

    var clauseJoiner: String {
        (outputLanguage.isChinese || outputLanguage.isJapanese) ? "，" : ", "
    }

    private static func detectAppLanguage(in text: String) -> AppLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let language = recognizer.dominantLanguage else { return nil }
        switch language {
        case .traditionalChinese, .simplifiedChinese:
            return .zhTW
        case .english:
            return .en
        case .indonesian:
            return .id
        case .vietnamese:
            return .vi
        case .thai:
            return .th
        case .japanese:
            return .ja
        default:
            return nil
        }
    }
}

private enum CareSemanticLexicon {
    static let clauseConnectors = [
        "但是", "可是", "不過", "而且", "另外", "然後", "並且",
        "but", "however", "also", "and then", "then",
        "tetapi", "namun", "lalu", "kemudian", "dan",
        "nhung", "tuy nhien", "roi", "sau do", "va",
        "แต่", "อย่างไรก็ตาม", "แล้ว", "จากนั้น", "และ",
        "でも", "しかし", "ただ", "それから", "そして"
    ]

    static let clauseSeparators = "，,。；;\n.!?！？、"

    static func categoryKeywords(for category: CareRecordCategory, context: CareSemanticLanguageContext) -> [String] {
        mergeKeywords(from: categoryKeywords[category] ?? [:], context: context)
    }

    static func conditionKeywords(for condition: RecordCondition, context: CareSemanticLanguageContext) -> [String] {
        mergeKeywords(from: conditionKeywords[condition] ?? [:], context: context)
    }

    private static func mergeKeywords(from table: [AppLanguage: [String]], context: CareSemanticLanguageContext) -> [String] {
        var keywords: [String] = []
        for language in context.candidateLanguages {
            keywords.append(contentsOf: table[language] ?? [])
        }

        for language in AppLanguage.allCases where !context.candidateLanguages.contains(language) {
            keywords.append(contentsOf: table[language] ?? [])
        }

        var seen = Set<String>()
        return keywords.filter { seen.insert($0).inserted }
    }

    private static let categoryKeywords: [CareRecordCategory: [AppLanguage: [String]]] = [
        .food: [
            .zhTW: ["吃", "飯", "早餐", "午餐", "晚餐", "喝水", "食慾", "牛奶", "水果", "進食", "粥"],
            .en: ["eat", "ate", "meal", "breakfast", "lunch", "dinner", "drink water", "water", "appetite", "milk", "fruit", "porridge", "food"],
            .id: ["makan", "sarapan", "makan siang", "makan malam", "minum", "air", "nafsu makan", "susu", "buah", "bubur"],
            .vi: ["an", "bua sang", "bua trua", "bua toi", "uong nuoc", "nuoc", "khau vi", "sua", "trai cay", "chao"],
            .th: ["กิน", "อาหาร", "มื้อเช้า", "อาหารเช้า", "มื้อกลางวัน", "มื้อเย็น", "ดื่มน้ำ", "น้ำ", "นม", "ผลไม้", "โจ๊ก"],
            .ja: ["食事", "食べ", "朝食", "昼食", "夕食", "水分", "水を飲", "食欲", "牛乳", "果物", "お粥"]
        ],
        .medicine: [
            .zhTW: ["早餐後已服用", "午餐後已服用", "晚餐後已服用", "飯後已服用", "已服用", "服用", "服藥後", "藥", "服藥", "用藥", "血壓", "血糖", "回診", "醫生", "藥物", "健保卡", "忘記吃藥", "漏吃藥", "未服藥"],
            .en: ["medicine", "medication", "meds", "pill", "dose", "blood pressure", "blood sugar", "doctor", "clinic", "appointment", "forgot medicine", "missed medicine"],
            .id: ["obat", "minum obat", "pil", "dosis", "tekanan darah", "gula darah", "dokter", "klinik", "kontrol", "lupa obat"],
            .vi: ["thuoc", "uong thuoc", "vien thuoc", "lieu", "huyet ap", "duong huyet", "bac si", "phong kham", "tai kham", "quen thuoc"],
            .th: ["ยา", "กินยา", "เม็ดยา", "ขนาดยา", "ความดัน", "น้ำตาล", "หมอ", "แพทย์", "คลินิก", "ลืมกินยา"],
            .ja: ["薬", "服薬", "内服", "血圧", "血糖", "受診", "医師", "先生", "病院", "飲み忘れ"]
        ],
        .bowel: [
            .zhTW: ["排便", "大便", "小便", "便秘", "腹瀉", "尿", "廁所"],
            .en: ["bowel", "stool", "poop", "urine", "pee", "constipation", "diarrhea", "toilet", "bathroom"],
            .id: ["bab", "buang air besar", "bak", "buang air kecil", "urin", "sembelit", "diare", "toilet", "kamar mandi"],
            .vi: ["di tieu", "di ngoai", "phan", "nuoc tieu", "tao bon", "tieu chay", "nha ve sinh"],
            .th: ["ถ่าย", "อุจจาระ", "ปัสสาวะ", "ท้องผูก", "ท้องเสีย", "ห้องน้ำ"],
            .ja: ["排便", "便", "尿", "おしっこ", "便秘", "下痢", "トイレ"]
        ],
        .mood: [
            .zhTW: ["情緒", "開心", "難過", "焦慮", "生氣", "失眠", "睡", "哭", "笑", "平穩", "精神", "不錯", "疲倦"],
            .en: ["mood", "happy", "sad", "anxious", "angry", "sleep", "insomnia", "cry", "smile", "calm", "stable", "energy", "spirit"],
            .id: ["suasana hati", "senang", "sedih", "cemas", "marah", "tidur", "insomnia", "menangis", "tersenyum", "tenang", "stabil", "semangat"],
            .vi: ["tam trang", "vui", "buon", "lo lang", "tuc gian", "ngu", "mat ngu", "khoc", "cuoi", "binh tinh", "on dinh", "tinh than"],
            .th: ["อารมณ์", "ดีใจ", "เศร้า", "กังวล", "โกรธ", "นอน", "นอนไม่หลับ", "ร้องไห้", "ยิ้ม", "สงบ", "คงที่"],
            .ja: ["気分", "機嫌", "嬉し", "悲し", "不安", "怒", "睡眠", "眠れ", "泣", "笑", "落ち着", "安定", "元気"]
        ]
    ]

    private static let conditionKeywords: [RecordCondition: [AppLanguage: [String]]] = [
        .bad: [
            .zhTW: ["不好", "發燒", "跌倒", "嘔吐", "呼吸困難", "胸痛", "昏倒", "劇痛", "無法進食", "意識不清", "忘記", "漏吃", "沒吃藥", "未服藥"],
            .en: ["bad", "poor", "fever", "fall", "fell", "vomit", "vomiting", "shortness of breath", "chest pain", "fainted", "severe pain", "unable to eat", "unconscious", "forgot", "missed dose", "missed medicine"],
            .id: ["buruk", "demam", "jatuh", "muntah", "sesak napas", "nyeri dada", "pingsan", "sakit parah", "tidak bisa makan", "tidak sadar", "lupa", "terlewat"],
            .vi: ["xau", "sot", "te nga", "nga", "non", "kho tho", "dau nguc", "ngat", "dau nhieu", "khong an duoc", "bat tinh", "quen", "bo lieu"],
            .th: ["แย่", "ไข้", "ล้ม", "อาเจียน", "หายใจลำบาก", "เจ็บหน้าอก", "เป็นลม", "ปวดมาก", "กินไม่ได้", "หมดสติ", "ลืม", "พลาดยา"],
            .ja: ["悪い", "発熱", "熱", "転倒", "嘔吐", "呼吸困難", "胸痛", "失神", "激痛", "食べられない", "意識不明", "忘れ", "飲み忘れ"]
        ],
        .normal: [
            .zhTW: ["普通", "還好", "尚可", "咳嗽", "食慾差", "食慾比平常差", "食慾較差", "食慾不好", "比平常差", "頭暈", "疲倦", "便秘", "腹瀉", "不舒服", "半碗"],
            .en: ["fair", "okay", "cough", "poor appetite", "dizzy", "dizziness", "tired", "fatigue", "constipation", "diarrhea", "uncomfortable", "discomfort"],
            .id: ["biasa", "lumayan", "batuk", "nafsu makan kurang", "pusing", "lelah", "sembelit", "diare", "tidak nyaman"],
            .vi: ["binh thuong", "tam duoc", "ho", "kem an", "chong mat", "met", "tao bon", "tieu chay", "kho chiu"],
            .th: ["ปกติ", "พอใช้", "ไอ", "เบื่ออาหาร", "เวียนหัว", "เหนื่อย", "ท้องผูก", "ท้องเสีย", "ไม่สบาย"],
            .ja: ["普通", "まあまあ", "咳", "食欲低下", "めまい", "疲れ", "便秘", "下痢", "不快", "しんどい"]
        ],
        .good: [
            .zhTW: ["正常", "良好", "穩定", "有吃", "吃完", "喝水", "喝溫水", "已服用", "已服藥", "服藥後", "按時", "平穩", "開心", "不錯", "精神好", "精神還不錯", "沒有嗆咳", "無頭暈", "沒有頭暈", "無噁心", "沒有噁心"],
            .en: ["good", "normal", "stable", "ate", "on time", "calm", "happy", "doing well", "good energy"],
            .id: ["baik", "normal", "stabil", "sudah makan", "tepat waktu", "tenang", "senang", "semangat baik"],
            .vi: ["tot", "binh thuong", "on dinh", "da an", "dung gio", "binh tinh", "vui", "tinh than tot"],
            .th: ["ดี", "ปกติ", "คงที่", "กินแล้ว", "ตรงเวลา", "สงบ", "ดีใจ", "สดชื่น"],
            .ja: ["良好", "正常", "安定", "食べた", "時間通り", "落ち着", "嬉し", "元気", "調子が良い"]
        ]
    ]
}
