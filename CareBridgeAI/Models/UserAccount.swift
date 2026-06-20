import Foundation

struct UserAccount: Identifiable, Codable {

    let id: UUID

    var email: String

    var password: String

    var caregiver: Caregiver

    var careRecipientID: String

    init(

        id: UUID = UUID(),

        email: String,

        password: String,

        caregiver: Caregiver,

        careRecipientID: String

    ) {

        self.id = id

        self.email = email

        self.password = password

        self.caregiver = caregiver

        self.careRecipientID = careRecipientID

    }

}

enum LoginResult {

    case success(draft: CareRecipientDraft, user: Caregiver)

    case pending

    case rejected

    case wrongPassword

    case notFound

}
