import Foundation

struct CareAIService {
    static func classifyRecord(_ text: String) -> CareRecordCategory {
        classifyCategories(text).first ?? .custom
    }

    static func classifyCategories(_ text: String) -> [CareRecordCategory] {
        var categories: [CareRecordCategory] = []

        let foodKeywords = ["吃", "飯", "早餐", "午餐", "晚餐", "喝水", "食慾", "牛奶", "水果", "進食", "粥"]
        let medicineKeywords = ["藥", "服藥", "用藥", "血壓", "血糖", "回診", "醫生", "藥物", "健保卡"]
        let bowelKeywords = ["排便", "大便", "小便", "便秘", "腹瀉", "尿", "廁所"]
        let moodKeywords = ["情緒", "開心", "難過", "焦慮", "生氣", "失眠", "睡", "哭", "笑", "平穩"]

        if foodKeywords.contains(where: { text.contains($0) }) {
            categories.append(.food)
        }

        if medicineKeywords.contains(where: { text.contains($0) }) {
            categories.append(.medicine)
        }

        if bowelKeywords.contains(where: { text.contains($0) }) {
            categories.append(.bowel)
        }

        if moodKeywords.contains(where: { text.contains($0) }) {
            categories.append(.mood)
        }

        return categories.isEmpty ? [.custom] : categories
    }

    static func inferCondition(from text: String) -> RecordCondition? {
        let badKeywords = ["不好", "發燒", "跌倒", "嘔吐", "呼吸困難", "胸痛", "昏倒", "劇痛", "無法進食", "意識不清"]
        let normalKeywords = ["普通", "還好", "尚可", "咳嗽", "食慾差", "頭暈", "疲倦", "便秘", "腹瀉", "不舒服"]
        let goodKeywords = ["正常", "良好", "穩定", "有吃", "按時", "平穩", "開心"]

        if badKeywords.contains(where: { text.contains($0) }) {
            return .bad
        }

        if normalKeywords.contains(where: { text.contains($0) }) {
            return .normal
        }

        if goodKeywords.contains(where: { text.contains($0) }) {
            return .good
        }

        return nil
    }

    static func generateRecordsFromText(_ text: String, selectedCategories: [CareRecordCategory]) -> [CareRecord] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let categories = selectedCategories.isEmpty ? classifyCategories(trimmed) : selectedCategories
        let condition = inferCondition(from: trimmed)

        return categories.map { category in
            CareRecord(
                content: trimmed,
                category: category,
                condition: condition
            )
        }
    }

    static func generateStatus(from summary: String) -> CareStatus {
        let dangerKeywords = [
            "發燒", "跌倒", "嘔吐", "呼吸困難", "胸痛", "昏倒",
            "劇痛", "送醫", "異常", "無法進食", "意識不清", "不好"
        ]

        let warningKeywords = [
            "咳嗽", "食慾差", "頭暈", "疲倦", "腹瀉", "便秘",
            "情緒低落", "睡不好", "疼痛", "不舒服", "需注意", "普通"
        ]

        if dangerKeywords.contains(where: { summary.contains($0) }) {
            return .danger
        }

        if warningKeywords.contains(where: { summary.contains($0) }) {
            return .warning
        }

        return .good
    }

    static func generateSummary(from records: [CareRecord]) -> String {
        let todayRecords = records.sorted { $0.createdAt > $1.createdAt }

        guard !todayRecords.isEmpty else {
            return "今日尚無照護紀錄，目前無明顯異常資訊。"
        }

        let foodRecords = todayRecords.filter { $0.category == .food }
        let medicineRecords = todayRecords.filter { $0.category == .medicine }
        let bowelRecords = todayRecords.filter { $0.category == .bowel }
        let moodRecords = todayRecords.filter { $0.category == .mood }

        var summaryParts: [String] = []

        if let latestFood = foodRecords.first {
            summaryParts.append("飲食方面，\(latestFood.content)")
        }

        if let latestMedicine = medicineRecords.first {
            summaryParts.append("用藥方面，\(latestMedicine.content)")
        }

        if let latestBowel = bowelRecords.first {
            summaryParts.append("排便方面，\(latestBowel.content)")
        }

        if let latestMood = moodRecords.first {
            summaryParts.append("情緒方面，\(latestMood.content)")
        }

        let badRecords = todayRecords.filter { $0.condition == .bad }
        let normalRecords = todayRecords.filter { $0.condition == .normal }

        if !badRecords.isEmpty {
            summaryParts.append("今日有 \(badRecords.count) 筆狀態不佳紀錄，建議立即留意。")
        } else if !normalRecords.isEmpty {
            summaryParts.append("今日有 \(normalRecords.count) 筆普通狀態紀錄，建議持續觀察。")
        } else {
            summaryParts.append("整體狀態目前穩定。")
        }

        return summaryParts.joined(separator: " ")
    }

    static func generateSummary() -> String {
        "今日尚無完整照護紀錄，請新增飲食、用藥、排便或情緒紀錄後，系統會自動彙整交接摘要。"
    }
}
