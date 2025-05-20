import Foundation
import UIKit

struct Project: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var projectDescription: String?
    var userId: String
    var createdAt: Date
    var updatedAt: Date
    
    // Client-side property - not from API
    var imageData: Data?
    
    // Optional fields that might come from the API
    var chats: [ChatPreview]?
    
    // Computed property to get UIImage from data (not Codable)
    var image: UIImage? {
        if let imageData = imageData {
            return UIImage(data: imageData)
        }
        return nil
    }
    
    init(id: String = UUID().uuidString, name: String, description: String? = nil, userId: String, createdAt: Date = Date(), updatedAt: Date = Date(), imageData: Data? = nil) {
        self.id = id
        self.name = name
        self.projectDescription = description
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.imageData = imageData
    }
    
    static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Coding keys to handle the API response
    enum CodingKeys: String, CodingKey {
        case id, name
        case projectDescription = "description"
        case userId, createdAt, updatedAt, chats
        // imageData is excluded as it's client-side only
    }
    
    // Custom init for decoding from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        projectDescription = try container.decodeIfPresent(String.self, forKey: .projectDescription)
        userId = try container.decode(String.self, forKey: .userId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        chats = try container.decodeIfPresent([ChatPreview].self, forKey: .chats)
        
        // Client-side property
        imageData = nil
    }
    
    // Custom encode to only include API fields
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(projectDescription, forKey: .projectDescription)
        try container.encode(userId, forKey: .userId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        // imageData is not encoded
    }
}

// For chat previews in project responses
struct ChatPreview: Codable, Identifiable {
    var id: String
    var title: String
    var updatedAt: Date
} 