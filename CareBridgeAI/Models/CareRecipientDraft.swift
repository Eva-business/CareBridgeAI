import Foundation

struct CareRecipientDraft {
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
