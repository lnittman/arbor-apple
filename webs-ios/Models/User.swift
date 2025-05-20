import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let clerkId: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let imageUrl: URL?
    let createdAt: Date
    let updatedAt: Date
    let hideSharedWarning: Bool
    
    // These properties may not be included in all API responses
    var chats: [Chat]?
    var projects: [Project]?
    var participations: [ChatParticipant]?
    var sharedLinks: [SharedLink]?
    
    var displayName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            return firstName
        } else if let email = email {
            return email
        } else {
            return "User"
        }
    }
    
    var initials: String {
        if let firstName = firstName, let lastName = lastName {
            let firstInitial = String(firstName.prefix(1))
            let lastInitial = String(lastName.prefix(1))
            return "\(firstInitial)\(lastInitial)"
        } else if let firstName = firstName {
            return String(firstName.prefix(1))
        } else if let email = email {
            return String(email.prefix(1))
        } else {
            return "U"
        }
    }
    
    // CodingKeys to handle API mapping
    enum CodingKeys: String, CodingKey {
        case id, clerkId, email, firstName, lastName, imageUrl, createdAt, updatedAt, hideSharedWarning
        case chats, projects, participations, sharedLinks
    }
} 