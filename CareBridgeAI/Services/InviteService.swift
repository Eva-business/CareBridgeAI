import Foundation

enum InviteService {
    static func generateCareRecipientID() -> String {
        let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

        let part1 = String((0..<4).map { _ in characters.randomElement()! })
        let part2 = String((0..<4).map { _ in characters.randomElement()! })

        return "CB-\(part1)-\(part2)"
    }

    static func makeInviteLink(for careRecipientID: String) -> String {
        "carebridge://join/\(careRecipientID)"
    }

    static func makeWebInviteLink(for careRecipientID: String) -> String {
        "https://carebridge.ai/join/\(careRecipientID)"
    }
}
