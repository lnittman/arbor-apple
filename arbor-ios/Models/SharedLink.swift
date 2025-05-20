import Foundation

struct SharedLink: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let chatId: String
    let ownerId: String
    let accessToken: String
    let isActive: Bool
    let messageCountAtShare: Int
    let createdAt: Date
    let updatedAt: Date
    let expiresAt: Date?
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        // Just hash the id since it's unique
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, chatId, ownerId, accessToken, isActive, messageCountAtShare, createdAt, updatedAt, expiresAt
    }
    
    // Generate share URL based on the accessToken
    var shareUrl: URL? {
        // This will need to match the URL format used by your web app
        let baseShareUrl = "https://webs-xyz.vercel.app/share"
        return URL(string: "\(baseShareUrl)/\(accessToken)")
    }
    
    // Check if the link has expired
    var isExpired: Bool {
        if let expiresAt = expiresAt {
            return Date() > expiresAt
        }
        return false
    }
    
    // Check if the link is valid (active and not expired)
    var isValid: Bool {
        return isActive && !isExpired
    }
    
    // Create a new share link
    static func createNew(for chatId: String, ownerId: String, messageCount: Int = 0, expiresIn: TimeInterval? = nil) -> SharedLink {
        let now = Date()
        var expiresAt: Date? = nil
        
        if let expiresIn = expiresIn {
            expiresAt = now.addingTimeInterval(expiresIn)
        }
        
        return SharedLink(
            id: UUID().uuidString,
            chatId: chatId,
            ownerId: ownerId,
            accessToken: UUID().uuidString,
            isActive: true,
            messageCountAtShare: messageCount,
            createdAt: now,
            updatedAt: now,
            expiresAt: expiresAt
        )
    }
} 