import Foundation

struct StreamChunkData: Codable {
    var chunk: String?
    var done: Bool?
    var error: String?
    var progress: String?
    var step: String?
    var timestamp: Double?
    var threadId: String?
    var resourceId: String?
    var requestId: String?
    var toolCallId: String?
    var toolName: String?
    var toolArgs: [String: Any]?
    var toolResult: [String: Any]?
    var isToolCall: Bool?
    
    // For JSON decoding of toolArgs and toolResult
    private enum CodingKeys: String, CodingKey {
        case chunk, done, error, progress, step, timestamp, threadId, resourceId, requestId, toolCallId, toolName, isToolCall
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        chunk = try container.decodeIfPresent(String.self, forKey: .chunk)
        done = try container.decodeIfPresent(Bool.self, forKey: .done)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        progress = try container.decodeIfPresent(String.self, forKey: .progress)
        step = try container.decodeIfPresent(String.self, forKey: .step)
        timestamp = try container.decodeIfPresent(Double.self, forKey: .timestamp)
        threadId = try container.decodeIfPresent(String.self, forKey: .threadId)
        resourceId = try container.decodeIfPresent(String.self, forKey: .resourceId)
        requestId = try container.decodeIfPresent(String.self, forKey: .requestId)
        toolCallId = try container.decodeIfPresent(String.self, forKey: .toolCallId)
        toolName = try container.decodeIfPresent(String.self, forKey: .toolName)
        isToolCall = try container.decodeIfPresent(Bool.self, forKey: .isToolCall)
        
        // Tool arguments and results will be handled separately in AgentsService
        toolArgs = nil
        toolResult = nil
    }
    
    init(chunk: String?, done: Bool?, error: String?, 
         threadId: String?, resourceId: String?, 
         isToolCall: Bool? = false, toolCallId: String? = nil, 
         toolName: String? = nil, toolArgs: [String: Any]? = nil,
         toolResult: [String: Any]? = nil) {
        self.chunk = chunk
        self.done = done
        self.error = error
        self.threadId = threadId
        self.resourceId = resourceId
        self.isToolCall = isToolCall
        self.toolCallId = toolCallId
        self.toolName = toolName
        self.toolArgs = toolArgs
        self.toolResult = toolResult
        
        // Default values for other fields
        self.progress = nil
        self.step = nil
        self.timestamp = nil
        self.requestId = nil
    }
} 