import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var currentMode: ChatMessage.AgentMode = .main
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isPrivateChat: Bool = false
    @Published var commandBarFocused: Bool = false {
        didSet {
            print("📋 ChatViewModel: commandBarFocused changed from \(oldValue) to \(commandBarFocused)")
        }
    }
    
    // Can be nil for new chats
    let chatId: String?
    
    private let agentsService = AgentsService()
    private let chatService = ChatService()
    private var streamingTask: Task<Void, Never>? = nil
    
    // Constructor for existing chat
    init(chatId: String) {
        self.chatId = chatId
        print("📱 ChatViewModel init for existing chat: \(chatId)")
        
        // Load messages immediately
        Task {
            await loadMessagesAndSendInitialIfNeeded()
        }
    }
    
    // Constructor for new chat
    init() {
        self.chatId = nil
        // No messages to load for a new chat
    }
    
    // MARK: - Public Methods
    
    /// Set the privacy mode of the chat
    func setPrivateMode(_ isPrivate: Bool) {
        self.isPrivateChat = isPrivate
    }
    
    /// Start a new chat with the current input text and return the ID and prompt
    func startNewChat(isPrivate: Bool = false) async -> (chatId: String, prompt: String)? {
        print("📱 ChatViewModel: startNewChat() called, isPrivate: \(isPrivate)")
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("📱 ChatViewModel: Empty input, not starting new chat")
            return nil
        }
        // Do not check isLoading here, as this is just creating the chat entry

        // Store the prompt text
        let promptToSend = inputText
        print("📱 ChatViewModel: Stored prompt: \(promptToSend)")

        do {
            // Create a new chat with the initial message if not private
            print("📱 ChatViewModel: Creating new chat entry")
            let initialMessage = isPrivate ? nil : promptToSend
            let newChat = try await chatService.createChat(
                title: "New Chat",
                initialMessage: initialMessage
            )
            print("📱 ChatViewModel: New chat created with ID: \(newChat.id)")

            // Clear input text after storing prompt
            inputText = ""

            // Return the new chat ID and the prompt
            return (chatId: newChat.id, prompt: promptToSend)
        } catch {
            errorMessage = "Failed to create new chat: \(error.localizedDescription)"
            print("📱 ChatViewModel: Error creating new chat: \(error)")
            return nil
        }
    }
    
    /// Send a message to the AI agent
    func sendMessage() {
        print("📱 ChatViewModel: sendMessage() called with input: \(inputText)")
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            print("📱 ChatViewModel: Empty input, not sending message")
            return 
        }
        guard !isLoading else { 
            print("📱 ChatViewModel: Already loading, not sending message")
            return 
        }
        guard let id = chatId else { 
            // Cannot send message without a chatId - startNewChat should be used first
            print("📱 ChatViewModel: No chatId, can't send message. startNewChat() should be used first")
            return
        }
        
        print("📱 ChatViewModel: Creating user message for chatId: \(id)")
        // Create and add user message
        let userMessage = ChatMessage.createUserMessage(content: inputText)
        messages.append(userMessage)
        
        // Only save to history if not in private mode
        if !isPrivateChat {
            print("📱 ChatViewModel: Saving message to chat history")
            Task {
                do {
                    let _ = try await chatService.addMessage(userMessage, to: id)
                } catch {
                    print("📱 ChatViewModel: Error saving message to history: \(error)")
                    // We continue with the chat even if saving fails
                }
            }
        } else {
            print("📱 ChatViewModel: Private chat, not saving to history")
        }
        
        // Store prompt and clear input text
        let prompt = inputText
        inputText = ""
        
        // Cancel any ongoing stream
        streamingTask?.cancel()
        
        // Start new streaming task using our streamResponse method
        streamingTask = Task {
            do {
                try await streamResponse(prompt: prompt)
            } catch {
                print("Error in streaming task: \(error)")
                // Error handling is already in streamResponse
            }
        }
    }
    
    /// Cancel any ongoing API stream
    func cancelStream() {
        streamingTask?.cancel()
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func loadMessages() async {
        // Load messages from storage
        if let id = chatId {
            do {
                messages = try await chatService.getMessages(for: id)
                print("📱 ChatViewModel loaded \(messages.count) messages for chat \(id)")
            } catch {
                errorMessage = "Failed to load messages: \(error.localizedDescription)"
                print("📱 ChatViewModel error loading messages: \(error)")
            }
        }
    }
    
    private func loadMessagesAndSendInitialIfNeeded() async {
        guard let id = chatId else { return }
        
        // Load messages from storage
        do {
            messages = try await chatService.getMessages(for: id)
            print("📱 ChatViewModel loaded \(messages.count) messages for chat \(id)")
            
            // Check if we need to send the initial message
            if messages.count == 1, let firstMessage = messages.first, firstMessage.type == .user {
                print("📱 ChatViewModel detected initial user message: \(firstMessage.content)")
                // We have exactly one user message, likely the one just added.
                // Trigger the streaming process for this message.
                
                // Mark as loading
                isLoading = true
                errorMessage = nil
                
                // Cancel any ongoing stream
                streamingTask?.cancel()
                
                print("📱 ChatViewModel starting initial streaming task for prompt: \(firstMessage.content)")
                let prompt = firstMessage.content
                let isChatPrivate = self.isPrivateChat // Capture current private state
                
                streamingTask = Task {
                    var currentResponseContent = ""
                    var responseMessageId: String? = nil
                    var lastChunkWasToolCall = false
                    var lastResponseIndex: Int? = nil
                    
                    do {
                        print("📱 ChatViewModel calling agentsService.streamChatResponse() for initial message")
                        let stream = agentsService.streamChatResponse(
                            prompt: prompt,
                            mode: currentMode,
                            threadId: id,
                            resourceId: nil
                        )
                        
                        print("📱 ChatViewModel stream created, processing chunks for initial message...")
                        for try await chunkData in stream {
                            if Task.isCancelled { 
                                print("📱 ChatViewModel task cancelled during initial streaming")
                                break 
                            }
                            
                            if let errorMsg = chunkData.error {
                                print("📱 ChatViewModel error in initial stream chunk: \(errorMsg)")
                                throw NSError(domain: "AgentApiError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                            }
                            
                            // Check if this is a tool call chunk
                            if let isToolCall = chunkData.isToolCall, isToolCall {
                                // If we were accumulating text before this tool call, mark that message
                                if let lastRespIdx = lastResponseIndex, lastRespIdx < messages.count {
                                    await MainActor.run {
                                        messages[lastRespIdx].hasToolCallAfter = true
                                    }
                                }
                                
                                await handleToolCallChunk(chunkData)
                                lastChunkWasToolCall = true
                                continue
                            }
                            
                            if let chunk = chunkData.chunk, 
                               !chunk.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                               // Skip the final "done" chunk that contains the entire message
                               !(chunkData.done == true && chunk.count > 100) {
                                
                                print("📱 ChatViewModel received initial chunk: \(chunk)")
                                
                                // If the last chunk was a tool call, we should start a new message
                                // to avoid mixing tool call responses with regular text
                                if lastChunkWasToolCall || responseMessageId == nil {
                                    let aiMessage = ChatMessage.createAIMessage(content: chunk, mode: currentMode)
                                    await MainActor.run {
                                        messages.append(aiMessage)
                                        lastResponseIndex = messages.count - 1
                                    }
                                    responseMessageId = aiMessage.id
                                    currentResponseContent = chunk
                                    print("📱 ChatViewModel created new AI message with id: \(aiMessage.id)")
                                    lastChunkWasToolCall = false
                                } else {
                                    currentResponseContent += chunk
                                    
                                    if let index = await MainActor.run(body: { messages.firstIndex(where: { $0.id == responseMessageId }) }) {
                                        await MainActor.run {
                                            messages[index].content = currentResponseContent
                                        }
                                    }
                                }
                            }
                            
                            if chunkData.done == true {
                                print("📱 ChatViewModel initial stream completed")
                                break
                            }
                        }
                        
                        if let respId = responseMessageId, let index = messages.firstIndex(where: { $0.id == respId }) {
                            let finalizedMessage = messages[index]
                            if !isChatPrivate {
                                print("📱 ChatViewModel saving finalized initial AI message to history")
                                Task {
                                    do {
                                        let _ = try await chatService.addMessage(finalizedMessage, to: id)
                                    } catch {
                                        print("📱 ChatViewModel error saving AI message to history: \(error)")
                                    }
                                }
                            }
                        }
                        
                    } catch {
                        if !Task.isCancelled {
                            print("Initial streaming error: \(error.localizedDescription)")
                            errorMessage = "Failed to get response: \(error.localizedDescription)"
                            let errorMsg = ChatMessage.createErrorMessage(content: "Error: \(error.localizedDescription)")
                            messages.append(errorMsg)
                            if !isChatPrivate {
                                Task {
                                    do {
                                        let _ = try await chatService.addMessage(errorMsg, to: id)
                                    } catch {
                                        print("📱 ChatViewModel error saving error message to history: \(error)")
                                    }
                                }
                            }
                        }
                    }
                    isLoading = false
                }
            } else if !messages.isEmpty {
                print("📱 ChatViewModel found \(messages.count) messages, not sending initial message.")
            }
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
            print("📱 ChatViewModel error loading messages: \(error)")
        }
    }
    
    private func streamResponse(prompt: String) async throws {
        isLoading = true
        errorMessage = nil
        
        // Reset responseText for accumulating streaming response
        var responseText = ""
        var responseMessageId: String? = nil
        var currentToolCallId: String? = nil
        var lastChunkWasToolCall = false
        var lastResponseIndex: Int? = nil
        
        // Log details for debugging
        print("🔄 ChatViewModel: Streaming response for prompt: \(prompt)")
        print("🔄 ChatViewModel: Using mode: \(currentMode)")
        
        do {
            for try await chunk in await agentsService.streamChatResponse(
                prompt: prompt,
                mode: currentMode,
                threadId: chatId,
                resourceId: nil
            ) {
                // Check if this is a tool call
                if let isToolCall = chunk.isToolCall, isToolCall {
                    // If we were accumulating text before this tool call, mark that message
                    if let lastRespIdx = lastResponseIndex, lastRespIdx < messages.count {
                        await MainActor.run {
                            messages[lastRespIdx].hasToolCallAfter = true
                        }
                    }
                    
                    await handleToolCallChunk(chunk)
                    lastChunkWasToolCall = true
                    continue
                }
                
                // Skip empty chunks and the final chunk that has the complete message
                guard let chunkText = chunk.chunk, 
                      !chunkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      // Skip the final "done" chunk that contains the entire message
                      !(chunk.done == true && chunkText.count > 100) else { continue }
                
                // For the first chunk, create a new AI message or update the last AI message
                if lastChunkWasToolCall || responseMessageId == nil {
                    // Create a new AI message after a tool call or for the first message
                    let newMessage = ChatMessage.createAIMessage(content: chunkText, mode: currentMode)
                    responseMessageId = newMessage.id
                    responseText = chunkText
                    
                    await MainActor.run {
                        // Add the new message to the array
                        messages.append(newMessage)
                        lastResponseIndex = messages.count - 1
                    }
                    
                    lastChunkWasToolCall = false
                } else {
                    // For subsequent chunks, append to the responseText
                    responseText += chunkText
                    
                    // Find the AI message by ID and update it
                    if let index = await MainActor.run(body: { messages.firstIndex(where: { $0.id == responseMessageId }) }) {
                        await MainActor.run {
                            // Update the message content with accumulated text
                            messages[index].content = responseText
                        }
                    }
                }
            }
            
            // Save the message to chat history if needed
            if let responseId = responseMessageId, 
               let index = messages.firstIndex(where: { $0.id == responseId }),
               !isPrivateChat, let id = chatId {
                // Only save to history service, don't create a new message object
                Task {
                    do {
                        let _ = try await chatService.addMessage(messages[index], to: id)
                    } catch {
                        print("❌ ChatViewModel: Error saving AI response to history: \(error.localizedDescription)")
                    }
                }
            }
            
        } catch {
            // Handle errors during streaming
            print("❌ ChatViewModel: Error streaming response: \(error.localizedDescription)")
            errorMessage = "Unable to get a response. Please try again."
            
            // Add an error message to the chat if needed
            if let responseId = responseMessageId, 
               let index = messages.firstIndex(where: { $0.id == responseId }) {
                // Update the existing message with error indicator
                await MainActor.run {
                    messages[index].content = "Sorry, there was an error getting a complete response."
                    // Now we can use the hasError property
                    messages[index].hasError = true
                }
            } else {
                // Create a new error message
                let errorMessage = ChatMessage.createErrorMessage(content: "Sorry, there was an error getting a response.")
                await MainActor.run {
                    messages.append(errorMessage)
                }
            }
        }
        
        // Complete and reset loading state
        await MainActor.run {
            isLoading = false
        }
    }
    
    // Add a method for handling tool call chunks
    @MainActor
    private func handleToolCallChunk(_ chunk: StreamChunkData) async {
        // Handle tool call
        if let toolCallId = chunk.toolCallId, let toolName = chunk.toolName, let args = chunk.toolArgs {
            print("🔄 ChatViewModel: Processing tool call: \(toolName)")
            
            // Convert args to string dictionary for storage
            let stringArgs = args.reduce(into: [String: String]()) { result, pair in
                result[pair.key] = String(describing: pair.value)
            }
            
            // Create tool call message
            let toolCallMessage = ChatMessage.createToolCallMessage(
                name: toolName,
                args: stringArgs,
                id: toolCallId
            )
            
            messages.append(toolCallMessage)
            
            // Save to history if not private
            if !isPrivateChat, let id = chatId {
                Task {
                    do {
                        let _ = try await chatService.addMessage(toolCallMessage, to: id)
                    } catch {
                        print("❌ ChatViewModel: Error saving tool call to history: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Handle tool result
        if let toolCallId = chunk.toolCallId, let result = chunk.toolResult {
            print("🔄 ChatViewModel: Processing tool result for ID: \(toolCallId)")
            
            // Convert result to string dictionary for storage
            let stringResult = result.reduce(into: [String: String]()) { result, pair in
                result[pair.key] = String(describing: pair.value)
            }
            
            // Format result for display
            var resultContent = "Tool result received"
            if let content = result["content"] {
                if let contentArray = content as? [[String: Any]], !contentArray.isEmpty {
                    resultContent = "Found information from \(contentArray.count) sources"
                }
            }
            
            // Create tool result message
            let toolResultMessage = ChatMessage.createToolResultMessage(
                content: resultContent,
                toolCallId: toolCallId,
                result: stringResult
            )
            
            messages.append(toolResultMessage)
            
            // Save to history if not private
            if !isPrivateChat, let id = chatId {
                Task {
                    do {
                        let _ = try await chatService.addMessage(toolResultMessage, to: id)
                    } catch {
                        print("❌ ChatViewModel: Error saving tool result to history: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
} 
