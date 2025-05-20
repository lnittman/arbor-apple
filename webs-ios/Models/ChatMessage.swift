import Foundation

struct ChatMessage: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let chatId: String
    let userId: String
    var content: String
    let type: MessageType
    let mode: AgentMode?
    let createdAt: Date
    
    // Client-side properties (not from API)
    var hasError: Bool = false
    var hasToolCallAfter: Bool = false
    var toolCallId: String?
    var toolName: String?
    var toolArgs: [String: String]?
    var toolResult: [String: String]?
    var toolCallApproved: Bool?
    
    enum MessageType: String, Codable {
        case user, ai, system, error, toolCall, toolResult
    }
    
    enum AgentMode: String, Codable, CaseIterable {
        case main, spin, think
        
        var displayName: String {
            switch self {
            case .main: return "Main"
            case .spin: return "Spin"
            case .think: return "Think"
            }
        }
        
        var iconName: String {
            switch self {
            case .main: return "text.bubble.fill"
            case .spin: return "arrow.triangle.2.circlepath"
            case .think: return "lightbulb.fill"
            }
        }
    }
    
    // Factory methods for creating messages (these will need to be updated with API data later)
    static func createUserMessage(content: String, chatId: String = "", userId: String = "") -> ChatMessage {
        return ChatMessage(
            id: UUID().uuidString,
            chatId: chatId,
            userId: userId,
            content: content,
            type: .user,
            mode: nil,
            createdAt: Date(),
            hasError: false
        )
    }
    
    static func createAIMessage(content: String, mode: AgentMode, chatId: String = "", userId: String = "") -> ChatMessage {
        return ChatMessage(
            id: UUID().uuidString,
            chatId: chatId,
            userId: userId,
            content: content,
            type: .ai,
            mode: mode,
            createdAt: Date(),
            hasError: false
        )
    }
    
    static func createErrorMessage(content: String, chatId: String = "", userId: String = "") -> ChatMessage {
        return ChatMessage(
            id: UUID().uuidString,
            chatId: chatId,
            userId: userId,
            content: content,
            type: .error,
            mode: nil,
            createdAt: Date(),
            hasError: true
        )
    }
    
    static func createToolCallMessage(name: String, args: [String: String], chatId: String = "", userId: String = "", id: String? = nil) -> ChatMessage {
        return ChatMessage(
            id: id ?? UUID().uuidString,
            chatId: chatId,
            userId: userId,
            content: "Tool Call: \(name)",
            type: .toolCall,
            mode: nil,
            createdAt: Date(),
            hasError: false,
            hasToolCallAfter: false,
            toolCallId: id,
            toolName: name,
            toolArgs: args,
            toolResult: nil,
            toolCallApproved: nil
        )
    }
    
    static func createToolResultMessage(content: String, toolCallId: String, result: [String: String], chatId: String = "", userId: String = "") -> ChatMessage {
        return ChatMessage(
            id: UUID().uuidString,
            chatId: chatId,
            userId: userId,
            content: content,
            type: .toolResult,
            mode: nil,
            createdAt: Date(),
            hasError: false,
            hasToolCallAfter: false,
            toolCallId: toolCallId,
            toolName: nil,
            toolArgs: nil,
            toolResult: result,
            toolCallApproved: true
        )
    }
    
    // Coding keys to map between API fields and our model
    enum CodingKeys: String, CodingKey {
        case id, chatId, userId, content, type, mode, createdAt
        // The following won't be encoded/decoded from API
        case hasError, hasToolCallAfter, toolCallId, toolName, toolArgs, toolResult, toolCallApproved
    }
    
    // Custom init from decoder to handle the timestamp/createdAt mapping
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        chatId = try container.decode(String.self, forKey: .chatId)
        userId = try container.decode(String.self, forKey: .userId)
        content = try container.decode(String.self, forKey: .content)
        type = try container.decode(MessageType.self, forKey: .type)
        mode = try container.decodeIfPresent(AgentMode.self, forKey: .mode)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Client-side properties with default values
        hasError = false
        hasToolCallAfter = false
        toolCallId = nil
        toolName = nil
        toolArgs = nil
        toolResult = nil
        toolCallApproved = nil
    }
    
    // Custom init for creating messages with all properties
    init(id: String, chatId: String, userId: String, content: String, type: MessageType, mode: AgentMode?, createdAt: Date, hasError: Bool = false, hasToolCallAfter: Bool = false, toolCallId: String? = nil, toolName: String? = nil, toolArgs: [String: String]? = nil, toolResult: [String: String]? = nil, toolCallApproved: Bool? = nil) {
        self.id = id
        self.chatId = chatId
        self.userId = userId
        self.content = content
        self.type = type
        self.mode = mode
        self.createdAt = createdAt
        self.hasError = hasError
        self.hasToolCallAfter = hasToolCallAfter
        self.toolCallId = toolCallId
        self.toolName = toolName
        self.toolArgs = toolArgs
        self.toolResult = toolResult
        self.toolCallApproved = toolCallApproved
    }
    
    // Custom encode to only include API fields
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(chatId, forKey: .chatId)
        try container.encode(userId, forKey: .userId)
        try container.encode(content, forKey: .content)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(mode, forKey: .mode)
        try container.encode(createdAt, forKey: .createdAt)
        
        // Client-side properties are not encoded
    }
} 