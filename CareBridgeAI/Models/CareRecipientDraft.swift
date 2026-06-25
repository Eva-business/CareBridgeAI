import Foundation

struct CareRecipientDraft: Codable {
    var careRecipientID: String = InviteService.generateCareRecipientID()
    
    var name: String = ""
    var relationship: String = ""
    var gender: String = "女"
    var bloodType: String = ""
    var birthday: Date = Date()

    // 基本資料中保留
    var phoneNote: String = ""

    // 醫療資訊
    var medicalHistory: String = ""
    var allergyHistory: String = ""
    var medications: String = ""
    var surgeryAndMedicalNote: String = ""

    // 生活、認知、照護需求
    var lifestyle: String = ""
    var cognitiveStatus: String = ""
    var carePreference: String = ""
    var taboo: String = ""

    // 多筆緊急聯絡人與醫療單位
    var emergencyContacts: [EmergencyContact] = []
    var medicalUnits: [MedicalUnit] = []

    var caregivers: [Caregiver] = []
    var documents: [CareDocument] = []
}

struct EmergencyContact: Identifiable, Codable {
    let id: UUID
    var name: String
    var relationship: String
    var phone: String
    var note: String

    init(
        id: UUID = UUID(),
        name: String = "",
        relationship: String = "",
        phone: String = "",
        note: String = ""
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.phone = phone
        self.note = note
    }
}

struct MedicalUnit: Identifiable, Codable {
    let id: UUID
    var name: String
    var department: String
    var doctorName: String
    var phone: String
    var address: String
    var note: String

    init(
        id: UUID = UUID(),
        name: String = "",
        department: String = "",
        doctorName: String = "",
        phone: String = "",
        address: String = "",
        note: String = ""
    ) {
        self.id = id
        self.name = name
        self.department = department
        self.doctorName = doctorName
        self.phone = phone
        self.address = address
        self.note = note
    }
}

struct CareDocument: Identifiable, Codable {
    let id: UUID
    var fileName: String
    var fileType: String
    var addedAt: Date

    init(
        id: UUID = UUID(),
        fileName: String,
        fileType: String,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.fileType = fileType
        self.addedAt = addedAt
    }
}

extension String {
    var containsCareBridgeCJKText: Bool {
        range(of: #"\p{Han}|\p{Hiragana}|\p{Katakana}|\p{Thai}"#, options: .regularExpression) != nil
    }

    var careBridgeEnglishProfileValue: String {
        switch self {
        case "主要管理者":
            return "Main Manager"
        case "女":
            return "Female"
        case "男":
            return "Male"
        case "其他":
            return "Other"
        case "母親":
            return "Mother"
        case "父親":
            return "Father"
        case "祖母":
            return "Grandmother"
        case "祖父":
            return "Grandfather"
        case "配偶":
            return "Spouse"
        case "家人":
            return "Family"
        case "看護":
            return "Caregiver"
        case "本人":
            return "Self"
        case "不確定":
            return "Unknown"
        default:
            return self
        }
    }

    var careBridgeEnglishCareTextValue: String {
        let exactTranslations: [String: String] = [
            "主要管理者": "Main Manager",
            "早餐前吃藥": "Take medication before breakfast",
            "降血壓藥 Amlodipine 5mg": "Amlodipine 5 mg for blood pressure",
            "量血壓": "Measure blood pressure",
            "血壓記錄": "Blood pressure record",
            "午餐後飲水": "Drink water after lunch",
            "提醒補充溫開水": "Remind to drink warm water",
            "睡前復健": "Bedtime rehab exercises",
            "關節活動練習": "Joint mobility exercises",
            "回診：心臟內科": "Follow-up: Cardiology",
            "健檢診所 / 張醫師": "Health clinic / Dr. Chang",
            "復健課程": "Rehab session",
            "物理治療中心": "Physical therapy center",
            "晚上容易腿部抽筋，睡前記得按摩與熱敷。": "Leg cramps happen easily at night. Remember massage and warm compress before bed.",
            "下週二回診，記得攜帶健保卡與目前用藥清單。": "Follow-up visit next Tuesday. Bring insurance card and current medication list.",
            "早餐吃了半碗粥，食慾尚可。": "Ate half a bowl of congee for breakfast. Appetite was fair.",
            "今日 08:00 排便正常。": "Bowel movement was normal at 08:00 today.",
            "情緒穩定，上午有進行散步 20 分鐘。": "Mood was stable. Walked for 20 minutes this morning.",
            "已按時服藥，無異常反應。": "Medication was taken on time with no abnormal reaction.",
            "阿嬤今天早餐吃了一個饅頭、一杯豆漿": "Grandma had a steamed bun and a cup of soy milk for breakfast today.",
            "情緒快速判斷：目前狀態良好。阿嬤早上心情很好": "Mood quick check: current status is Good. Grandma was in a good mood this morning.",
            "情緒快速判斷：目前狀態良好。": "Mood quick check: current status is Good."
        ]

        if let translated = exactTranslations[self] {
            return translated
        }

        var translated = self
        let replacements: [(String, String)] = [
            ("阿嬤", "Grandma"),
            ("早餐", "breakfast"),
            ("午餐", "lunch"),
            ("晚餐", "dinner"),
            ("饅頭", "steamed bun"),
            ("豆漿", "soy milk"),
            ("情緒快速判斷：目前狀態良好。", "Mood quick check: current status is Good."),
            ("情緒穩定", "Mood was stable"),
            ("心情很好", "was in a good mood"),
            ("已按時服藥", "Medication was taken on time"),
            ("無異常反應", "with no abnormal reaction"),
            ("排便正常", "bowel movement was normal"),
            ("主要管理者", "Main Manager")
        ]

        for (source, target) in replacements {
            translated = translated.replacingOccurrences(of: source, with: target)
        }

        return translated.containsCareBridgeCJKText ? self : translated
    }

    var careBridgeEnglishDisplayValue: String {
        let translated = careBridgeEnglishCareTextValue.careBridgeEnglishProfileValue
        return translated.containsCareBridgeCJKText ? "Care Recipient" : translated
    }

    var careBridgeEnglishCareDisplayValue: String {
        let translated = careBridgeEnglishCareTextValue
        return translated.containsCareBridgeCJKText ? "Care detail recorded." : translated
    }

    var careBridgeEnglishTaskDisplayValue: String {
        let translated = careBridgeEnglishCareTextValue
        return translated.containsCareBridgeCJKText ? "Care Task" : translated
    }

    func localizedCareText(_ language: AppLanguage) -> String {
        if language.isChinese && containsCareBridgeCJKText {
            return self
        }

        if !language.isChinese {
            return careBridgeEnglishCareDisplayValue
        }

        let english = careBridgeEnglishCareDisplayValue
        let translations: [String: String] = [
            "Care Recipient": "被照護者",
            "Caregiver": "照護者",
            "Main Manager": "主要管理者",
            "Morning Caregiver": "早班照護者",
            "Day Caregiver": "日班照護者",
            "Family Member": "家屬",
            "Take medication before breakfast": "早餐前用藥",
            "Amlodipine 5 mg for blood pressure": "降血壓藥 Amlodipine 5 mg",
            "Measure blood pressure": "量血壓",
            "Blood pressure record": "血壓紀錄",
            "Drink water after lunch": "午餐後補水",
            "Remind to drink warm water": "提醒補充溫開水",
            "Bedtime rehab exercises": "睡前復健運動",
            "Joint mobility exercises": "關節活動練習",
            "Follow-up: Cardiology": "心臟內科回診",
            "Health clinic / Dr. Chang": "健檢診所 / 張醫師",
            "Rehab session": "復健課程",
            "Physical therapy center": "物理治療中心",
            "Leg cramps happen easily at night. Remember massage and warm compress before bed.": "晚上容易腿部抽筋，睡前記得按摩與熱敷。",
            "Follow-up visit next Tuesday. Bring insurance card and current medication list.": "下週二回診，記得攜帶健保卡與目前用藥清單。",
            "Ate half a bowl of congee for breakfast. Appetite was fair.": "早餐吃了半碗粥，食慾尚可。",
            "Ate half a bowl of congee for breakfast. Water intake was normal.": "早餐吃了半碗粥，喝水正常。",
            "Bowel movement was normal at 08:00 today.": "今日 08:00 排便正常。",
            "Mood was stable. Walked for 20 minutes this morning.": "情緒穩定，上午有散步 20 分鐘。",
            "Medication was taken on time with no abnormal reaction.": "已按時服藥，無異常反應。",
            "Grandma had a steamed bun and a cup of soy milk for breakfast today.": "阿嬤今天早餐吃了一個饅頭、一杯豆漿。",
            "Mood quick check: current status is Good. Grandma was in a good mood this morning.": "情緒快速判斷：目前狀態良好。阿嬤早上心情很好。",
            "Mood quick check: current status is Good.": "情緒快速判斷：目前狀態良好。",
            "Breakfast: finished oatmeal, banana slices, and 250 ml of warm water. Appetite was slightly lower than usual but no choking was observed.": "早餐吃完燕麥、香蕉片與 250 ml 溫水。食慾比平常稍低，但沒有嗆咳。",
            "Blood pressure was 132/78 mmHg before morning medication. Amlodipine 5 mg was taken at 08:10 with no dizziness or nausea reported.": "早藥前血壓 132/78 mmHg。08:10 已服用 Amlodipine 5 mg，沒有回報頭暈或噁心。",
            "Bowel movement at 09:05. Stool was soft and formed. No abdominal pain was reported.": "09:05 排便，糞便偏軟但成形，沒有腹痛。",
            "Mood was calm after a video call with family. Participated in light conversation and followed simple instructions well.": "與家人視訊後情緒平穩，有簡短對話，也能配合簡單指令。",
            "Lunch: ate about 70% of rice, steamed fish, and vegetables. Drank another 200 ml of water. Continue encouraging fluids in the afternoon.": "午餐約吃完 70% 白飯、清蒸魚與蔬菜，另喝 200 ml 水。下午需持續鼓勵補水。",
            "Completed 15 minutes of seated leg exercises. Mild knee stiffness was noted, but pain did not increase.": "完成 15 分鐘坐姿腿部運動。膝蓋略僵硬，但疼痛沒有增加。",
            "The afternoon medication was missed before the meal. Please confirm the next dose with the caregiver and avoid taking a double dose.": "下午飯前漏服藥物，請與照護者確認下一次服藥時間，避免重複服藥。",
            "Morning blood pressure check": "早晨血壓量測",
            "Record systolic, diastolic, and any dizziness before medication.": "服藥前記錄收縮壓、舒張壓與是否頭暈。",
            "Give morning medication": "給早晨藥物",
            "Amlodipine 5 mg after breakfast. Confirm swallowing before leaving.": "早餐後服用 Amlodipine 5 mg，離開前確認已吞嚥。",
            "Hydration reminder": "補水提醒",
            "Offer 200 ml warm water. Use small sips if appetite is low.": "提供 200 ml 溫水；若食慾較差，改用小口慢飲。",
            "Seated leg exercises": "坐姿腿部運動",
            "15 minutes. Stop if knee pain increases.": "15 分鐘；若膝蓋疼痛增加則停止。",
            "Cardiology follow-up": "心臟內科回診",
            "Bring blood pressure log and current medication list.": "攜帶血壓紀錄與目前用藥清單。",
            "Evening medication check": "晚間藥物確認",
            "Confirm pill box compartment is empty before bedtime.": "睡前確認藥盒格已清空。",
            "Prefers warm water and soft foods when appetite is low.": "食慾差時偏好溫水與軟質食物。",
            "Family video calls usually improve mood in the morning.": "早上與家人視訊通常能改善情緒。",
            "Check knee stiffness before starting afternoon exercises.": "下午運動前先確認膝蓋僵硬程度。",
            "No complete care records have been added today. Add food, medication, bowel, or mood records and the system will create a handoff summary automatically.": "今天尚未新增完整照護紀錄。新增飲食、用藥、排便或情緒紀錄後，系統會自動產生交接摘要。",
            "No care records have been added today. No clear abnormal information is available yet.": "今天尚未新增照護紀錄，目前沒有明確異常資訊。",
            "Overall status is currently stable.": "整體狀態目前穩定。",
            "Overall status is stable today. Breakfast and lunch intake were normal, and mood was calm.": "今日整體狀態穩定。早餐與午餐攝取正常，情緒平穩。",
            "record(s) need follow-up observation today.": "筆紀錄今天需要持續觀察。",
            "record(s) indicate poor condition today. Please review promptly.": "筆紀錄顯示狀況不佳，請盡快查看。"
        ]

        if let translated = translations[english] {
            return translated
        }

        var translated = english
        var replacements: [(String, String)] = translations.map { ($0.key, $0.value) }
        replacements.append(contentsOf: [
            ("Food:", "飲食："),
            ("Medication:", "用藥："),
            ("Bowel:", "排便："),
            ("Mood:", "情緒："),
            ("Other:", "其他："),
            ("Food quick check:", "飲食快速判斷："),
            ("Medication quick check:", "用藥快速判斷："),
            ("Bowel quick check:", "排便快速判斷："),
            ("Mood quick check:", "情緒快速判斷："),
            ("Other quick check:", "其他快速判斷："),
            ("current status is Good", "目前狀態良好"),
            ("current status is Fair", "目前狀態普通"),
            ("current status is Poor", "目前狀態不好"),
            ("Overall status is currently stable.", "整體狀態目前穩定。"),
            ("record(s) need follow-up observation today.", "筆紀錄今天需要持續觀察。"),
            ("record(s) indicate poor condition today. Please review promptly.", "筆紀錄顯示狀況不佳，請盡快查看。")
        ])

        for (source, target) in replacements {
            translated = translated.replacingOccurrences(of: source, with: target)
        }

        return translated
    }

    func localizedProfileValue(_ language: AppLanguage) -> String {
        language.isChinese ? self : careBridgeEnglishProfileValue
    }

    func localizedTaskText(_ language: AppLanguage) -> String {
        let translated = localizedCareText(language)
        return translated == "Care detail recorded." ? language.text(en: "Care Task", zhTW: "照護任務") : translated
    }
}
