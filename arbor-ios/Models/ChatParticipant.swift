import Foundation

struct ChatParticipant: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let chatId: String
    let userId: String
    let role: ParticipantRole
    let joinedAt: Date
    let invitedBy: String?
    let inviteToken: String?
    let inviteEmail: String?
    let isActive: Bool
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        // Just hash the id since it's unique
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, chatId, userId, role, joinedAt, invitedBy, inviteToken, inviteEmail, isActive
    }
}

enum ParticipantRole: String, Codable, CaseIterable {
    case owner = "OWNER"
    case moderator = "MODERATOR"
    case participant = "PARTICIPANT"
    case viewer = "VIEWER"
    
    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .moderator: return "Moderator"
        case .participant: return "Participant"
        case .viewer: return "Viewer"
        }
    }
    
    var canEdit: Bool {
        switch self {
        case .owner, .moderator: return true
        case .participant, .viewer: return false
        }
    }
    
    var canInvite: Bool {
        switch self {
        case .owner, .moderator: return true
        case .participant, .viewer: return false
        }
    }
    
    var canDelete: Bool {
        switch self {
        case .owner: return true
        case .moderator, .participant, .viewer: return false
        }
    }
} 