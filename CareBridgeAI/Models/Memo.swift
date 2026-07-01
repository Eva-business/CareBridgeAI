import Foundation

struct Memo: Identifiable, Codable {
    let id: UUID
    var ownerID: UUID?
    var content: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        ownerID: UUID? = nil,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.ownerID = ownerID
        self.content = content
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case ownerID
        case content
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ownerID = try container.decodeIfPresent(UUID.self, forKey: .ownerID)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
