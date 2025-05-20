import Foundation

class ChatService {
    private let apiManager = APIManager.shared
    
    // MARK: - Public Methods
    
    /// Get all chats
    func getAllChats() async throws -> [Chat] {
        let chats = try await apiManager.request(endpoint: "/api/chats", decodingType: [Chat].self)
        return chats.sorted(by: { $0.updatedAt > $1.updatedAt })
    }
    
    /// Get a specific chat by ID
    func getChat(id: String) async throws -> Chat {
        return try await apiManager.request(endpoint: "/api/chats/\(id)", decodingType: Chat.self)
    }
    
    /// Create a new chat
    @discardableResult
    func createChat(title: String = "New Chat", initialMessage: String? = nil, projectId: String? = nil) async throws -> Chat {
        var body: [String: Any] = ["title": title]
        
        if let initialMessage = initialMessage {
            body["message"] = initialMessage
        }
        
        if let projectId = projectId {
            body["projectId"] = projectId
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        return try await apiManager.request(endpoint: "/api/chats", method: "POST", body: bodyData, decodingType: Chat.self)
    }
    
    /// Update an existing chat
    func updateChat(_ chat: Chat) async throws -> Chat {
        let body = ["title": chat.title]
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        return try await apiManager.request(endpoint: "/api/chats/\(chat.id)", method: "PUT", body: bodyData, decodingType: Chat.self)
    }
    
    /// Delete a chat
    func deleteChat(id: String) async throws {
        try await apiManager.requestVoid(endpoint: "/api/chats/\(id)", method: "DELETE")
    }
    
    /// Get all messages for a chat
    func getMessages(for chatId: String) async throws -> [ChatMessage] {
        return try await apiManager.request(endpoint: "/api/chats/\(chatId)/messages", decodingType: [ChatMessage].self)
    }
    
    /// Add a message to a chat
    func addMessage(_ message: ChatMessage, to chatId: String) async throws -> ChatMessage {
        let body: [String: Any] = [
            "content": message.content,
            "type": message.type.rawValue,
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        return try await apiManager.request(
            endpoint: "/api/chats/\(chatId)/messages",
            method: "POST",
            body: bodyData,
            decodingType: ChatMessage.self
        )
    }
} 
