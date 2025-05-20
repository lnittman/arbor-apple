import Foundation

struct Chat: Codable, Identifiable, Equatable, Hashable {
    let id: String
    var title: String
    let userId: String
    var projectId: String?
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date
    
    // These are optional and might not be included in all API responses
    var participants: [ChatParticipant]?
    var sharedLinks: [SharedLink]?
    
    static func createNewChat() -> Chat {
        let now = Date()
        return Chat(
            id: UUID().uuidString,
            title: "New Chat",
            userId: "", // This will be set by the server
            projectId: nil,
            messages: [],
            createdAt: now,
            updatedAt: now
        )
    }
    
    // Generate a title from the first user message if available
    mutating func updateTitleFromContent() {
        if let firstUserMessage = messages.first(where: { $0.type == .user }),
           title == "New Chat" {
            let content = firstUserMessage.content
            // Limit title length to a reasonable value (e.g., 30 characters)
            let maxLength = 30
            if content.count > maxLength {
                title = content.prefix(maxLength) + "..."
            } else {
                title = content
            }
        }
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        // Just hash the id since it's unique
        hasher.combine(id)
    }
    
    // Coding keys to handle snake_case to camelCase conversion if needed
    enum CodingKeys: String, CodingKey {
        case id, title, userId, projectId, messages, createdAt, updatedAt, participants, sharedLinks
    }
} 