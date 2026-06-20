import Foundation

struct Memo: Identifiable, Codable {
    let id: UUID
    var content: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }
}
