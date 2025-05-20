import Foundation

struct AgentStreamRequest: Codable {
    let messages: [[String: String]]
    let threadId: String?
    let resourceId: String?
    
    init(prompt: String, threadId: String?, resourceId: String?) {
        // Create a messages array with a single user message
        self.messages = [
            ["role": "user", "content": prompt]
        ]
        self.threadId = threadId
        
        // If threadId is provided, we must also provide a resourceId
        if threadId != nil && resourceId == nil {
            // Use the threadId as the resourceId if none is provided
            self.resourceId = threadId
        } else {
            self.resourceId = resourceId
        }
    }
}

enum AgentApiError: Error {
    case networkError(Error)
    case serverError(String)
    case decodingError(Error)
    case invalidResponse
    case unauthorized
    case unknown
}

class AgentsService {
    // Ngrok server URL
    private let baseURL: URL
    
    init(baseURL: URL? = nil) {
        print("🔌 AgentsService: Initializing...")
        
        if let customURL = baseURL {
            self.baseURL = customURL
            print("🔌 AgentsService: Using provided URL: \(customURL.absoluteString)")
        } else {
            // Try to get the URL from UserDefaults
            let savedURLString = UserDefaults.standard.string(forKey: "AgentsServiceBaseURL")
            if let urlString = savedURLString, let url = URL(string: urlString + "/api/agents") {
                self.baseURL = url
                print("🔌 AgentsService: Using URL from UserDefaults: \(url.absoluteString)")
            } else {
                // Fall back to the default ngrok URL
                self.baseURL = URL(string: "https://f130bbe682f0.ngrok.app/api/agents")!
                print("🔌 AgentsService: Using default ngrok URL: \(self.baseURL.absoluteString)")
            }
        }
        
        // Validate URL format
        print("🔌 AgentsService: Final baseURL: \(self.baseURL.absoluteString)")
        if let streamURL = URL(string: self.baseURL.absoluteString + "/chat/stream") {
            print("🔌 AgentsService: Stream URL would be: \(streamURL.absoluteString)")
        } else {
            print("🔌 AgentsService: WARNING - Cannot form valid stream URL!")
        }
        
        // Test connection asynchronously
        Task {
            do {
                print("🔌 AgentsService: Testing connection to base URL...")
                let request = URLRequest(url: self.baseURL)
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔌 AgentsService: Connection test status: \(httpResponse.statusCode)")
                }
            } catch {
                print("🔌 AgentsService: Connection test failed: \(error.localizedDescription)")
            }
        }
    }
    
    // Stream response from the chat agent
    func streamChatResponse(prompt: String, mode: ChatMessage.AgentMode = .main, threadId: String? = nil, resourceId: String? = nil) -> AsyncThrowingStream<StreamChunkData, Error> {
        print("🔌 AgentsService: streamChatResponse called with prompt: \(prompt)")
        
        // If threadId is provided but resourceId is not, use threadId as resourceId
        let effectiveResourceId = threadId != nil && resourceId == nil ? threadId : resourceId
        
        print("🔌 AgentsService: Using threadId: \(threadId ?? "nil"), resourceId: \(effectiveResourceId ?? "nil")")
        
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // Use the correct endpoint format from the API docs
                    // The default agent endpoint format is /api/agents/{agentId}/stream
                    // For now we'll use "/api/agents/chat/stream" as endpoint
                    var baseURLString = baseURL.absoluteString
                    
                    // Remove trailing slash if present
                    if baseURLString.hasSuffix("/") {
                        baseURLString.removeLast()
                    }
                    
                    let streamURLString = "\(baseURLString)/chat/stream"
                    print("🔌 AgentsService: Using stream URL: \(streamURLString)")
                    
                    guard let streamURL = URL(string: streamURLString) else {
                        print("🔌 AgentsService: ERROR - Invalid stream URL: \(streamURLString)")
                        throw AgentApiError.networkError(NSError(domain: "AgentsService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid stream URL"]))
                    }
                    
                    print("🔌 AgentsService: Making request to: \(streamURL.absoluteString)")
                    
                    var urlRequest = URLRequest(url: streamURL)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    
                    // Create the request body
                    let request = AgentStreamRequest(
                        prompt: prompt,
                        threadId: threadId,
                        resourceId: effectiveResourceId
                    )
                    
                    // Log the request body for debugging
                    if let requestData = try? JSONEncoder().encode(request),
                       let requestString = String(data: requestData, encoding: .utf8) {
                        print("🔌 AgentsService: Request payload: \(requestString)")
                    }
                    
                    urlRequest.httpBody = try JSONEncoder().encode(request)
                    
                    print("🔌 AgentsService: Starting stream request...")
                    // Start the stream request
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("🔌 AgentsService: Invalid response type")
                        throw AgentApiError.invalidResponse
                    }
                    
                    print("🔌 AgentsService: Received HTTP response with status code: \(httpResponse.statusCode)")
                    
                    // Print response headers for debugging
                    print("🔌 AgentsService: Response headers:")
                    for (key, value) in httpResponse.allHeaderFields {
                        print("🔌 AgentsService:   \(key): \(value)")
                    }
                    
                    // Check for HTTP errors
                    switch httpResponse.statusCode {
                    case 200...299: // Success
                        print("🔌 AgentsService: Successful response, starting to process stream")
                        break
                    case 400:
                        print("🔌 AgentsService: Bad request error (400)")
                        // Try to read the error response body
                        var errorData = Data()
                        for try await byte in bytes {
                            errorData.append(byte)
                        }
                        if let errorString = String(data: errorData, encoding: .utf8) {
                            print("🔌 AgentsService: Error response body: \(errorString)")
                            throw AgentApiError.serverError("Bad Request: \(errorString)")
                        } else {
                            throw AgentApiError.serverError("Bad Request (400)")
                        }
                    case 401:
                        print("🔌 AgentsService: Unauthorized error")
                        throw AgentApiError.unauthorized
                    default:
                        print("🔌 AgentsService: Server error with status code: \(httpResponse.statusCode)")
                        throw AgentApiError.serverError("HTTP status code: \(httpResponse.statusCode)")
                    }
                    
                    // Process the SSE stream
                    var buffer = ""
                    print("🔌 AgentsService: Processing stream lines...")
                    
                    // Track response content
                    var fullResponseContent = ""
                    var isDone = false
                    
                    for try await line in bytes.lines {
                        if Task.isCancelled {
                            print("🔌 AgentsService: Task cancelled, breaking stream processing")
                            break
                        }
                        
                        print("🔌 AgentsService: Received line: \(line)")
                        
                        // Handle the different line prefixes from the streaming format
                        if line.hasPrefix("f:") {
                            // First line with message ID - just log it
                            print("🔌 AgentsService: Message ID info: \(line)")
                            
                        } else if line.hasPrefix("0:") {
                            // Content chunk - extract the content part
                            if let contentStart = line.firstIndex(of: ":") {
                                let contentPart = String(line.suffix(from: line.index(after: contentStart)))
                                
                                // Remove surrounding quotes if present (JSON format)
                                let cleanContent = contentPart.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                                print("🔌 AgentsService: Content chunk: \(cleanContent)")
                                
                                // Append to full response
                                fullResponseContent += cleanContent
                                
                                // Create a chunk data object and yield it
                                let chunkData = StreamChunkData(
                                    chunk: cleanContent, 
                                    done: false,
                                    error: nil,
                                    threadId: threadId,
                                    resourceId: resourceId
                                )
                                continuation.yield(chunkData)
                            }
                            
                        } else if line.hasPrefix("9:") {
                            // Tool call data - extract and parse JSON
                            if let contentStart = line.firstIndex(of: ":") {
                                let jsonString = String(line.suffix(from: line.index(after: contentStart)))
                                
                                do {
                                    if let jsonData = jsonString.data(using: .utf8),
                                       let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                        
                                        let toolCallId = jsonDict["toolCallId"] as? String ?? ""
                                        let toolName = jsonDict["toolName"] as? String ?? ""
                                        let args = jsonDict["args"] as? [String: Any] ?? [:]
                                        
                                        print("🔌 AgentsService: Tool call: \(toolName) with ID: \(toolCallId)")
                                        
                                        // Create tool call chunk data
                                        let toolCallData = StreamChunkData(
                                            chunk: "Tool Call: \(toolName)",
                                            done: false,
                                            error: nil,
                                            threadId: threadId,
                                            resourceId: resourceId,
                                            isToolCall: true,
                                            toolCallId: toolCallId,
                                            toolName: toolName,
                                            toolArgs: args
                                        )
                                        
                                        continuation.yield(toolCallData)
                                    }
                                } catch {
                                    print("🔌 AgentsService: Failed to parse tool call JSON: \(error)")
                                }
                            }
                        } else if line.hasPrefix("a:") {
                            // Tool call result data
                            if let contentStart = line.firstIndex(of: ":") {
                                let jsonString = String(line.suffix(from: line.index(after: contentStart)))
                                
                                do {
                                    if let jsonData = jsonString.data(using: .utf8),
                                       let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                        
                                        let toolCallId = jsonDict["toolCallId"] as? String ?? ""
                                        let result = jsonDict["result"] as? [String: Any] ?? [:]
                                        
                                        print("🔌 AgentsService: Tool result for ID: \(toolCallId)")
                                        
                                        // Create tool result chunk data
                                        let toolResultData = StreamChunkData(
                                            chunk: "Tool Result",
                                            done: false,
                                            error: nil,
                                            threadId: threadId,
                                            resourceId: resourceId,
                                            isToolCall: true,
                                            toolCallId: toolCallId,
                                            toolResult: result
                                        )
                                        
                                        continuation.yield(toolResultData)
                                    }
                                } catch {
                                    print("🔌 AgentsService: Failed to parse tool result JSON: \(error)")
                                }
                            }
                            
                        } else if line.hasPrefix("e:") || line.hasPrefix("d:") {
                            // End marker - stream complete
                            print("🔌 AgentsService: Stream completion marker: \(line)")
                            isDone = true
                            
                        } else if line.hasPrefix("data: ") {
                            // Try original SSE format as fallback
                            let jsonString = String(line.dropFirst(6))
                            if jsonString.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                                print("🔌 AgentsService: Empty data line, continuing")
                                continue
                            }
                            
                            do {
                                if let data = jsonString.data(using: .utf8) {
                                    let decodedData = try JSONDecoder().decode(StreamChunkData.self, from: data)
                                    print("🔌 AgentsService: Successfully decoded chunk: \(decodedData.chunk ?? "")")
                                    continuation.yield(decodedData)
                                    
                                    // If the stream is marked as done, finish the stream
                                    if decodedData.done == true {
                                        print("🔌 AgentsService: Stream marked as done, finishing")
                                        isDone = true
                                    }
                                }
                            } catch {
                                print("🔌 AgentsService: Failed to decode chunk: \(error)")
                                print("🔌 AgentsService: Raw chunk data: \(jsonString)")
                                // Continue processing instead of failing completely
                            }
                        }
                    }
                    
                    // Send a final chunk with done=true if we got any content
                    if !fullResponseContent.isEmpty {
                        print("🔌 AgentsService: Sending final chunk with full response")
                        let finalChunkData = StreamChunkData(
                            chunk: fullResponseContent,
                            done: true,
                            error: nil,
                            threadId: threadId,
                            resourceId: resourceId
                        )
                        continuation.yield(finalChunkData)
                    }
                    
                    print("🔌 AgentsService: Finished processing stream")
                    // If we get here without receiving done=true, still finish the stream
                    continuation.finish()
                    
                } catch {
                    print("🔌 AgentsService: Error during streaming: \(error.localizedDescription)")
                    if let apiError = error as? AgentApiError {
                        continuation.finish(throwing: apiError)
                    } else {
                        continuation.finish(throwing: AgentApiError.networkError(error))
                    }
                }
            }
            
            // Set up cancellation handler
            continuation.onTermination = { @Sendable _ in
                print("🔌 AgentsService: Stream terminated, cancelling task")
                task.cancel()
            }
        }
    }
    
    // Get agent info
    func getAgentInfo() async throws -> [String: Any] {
        print("🔌 AgentsService: Getting agent info from \(baseURL.absoluteString)")
        let request = URLRequest(url: baseURL)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔌 AgentsService: Invalid response when getting agent info")
            throw AgentApiError.invalidResponse
        }
        
        print("🔌 AgentsService: Agent info response status code: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200...299:
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔌 AgentsService: Successfully retrieved agent info")
                return json
            } else {
                print("🔌 AgentsService: Failed to parse agent info JSON")
                throw AgentApiError.decodingError(NSError(domain: "AgentsService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"]))
            }
        case 401:
            print("🔌 AgentsService: Unauthorized when getting agent info")
            throw AgentApiError.unauthorized
        default:
            print("🔌 AgentsService: Server error when getting agent info: \(httpResponse.statusCode)")
            throw AgentApiError.serverError("HTTP status code: \(httpResponse.statusCode)")
        }
    }
} 
