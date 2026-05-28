import Foundation

struct ClipboardEntry: Codable, Identifiable {
    var id: UUID
    var text: String
    var createdAt: Date
    var pinned: Bool

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
        self.pinned = false
    }
}
