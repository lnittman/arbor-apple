import SwiftUI
import PhosphorSwift

struct MessageView: View {
    let message: ChatMessage
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @State private var elapsedSeconds = 2
    @State private var timer: Timer?
    @State private var hasAppeared = false
    @State private var isContentFinal = false // To track if content is finalized
    @State private var showToolDetails = false
    
    // For feedback toast
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var toastManager: ToastManager
    @State private var toastMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Message content with alignment based on type
            if message.type == .ai {
                if message.mode == .think {
                    // Thinking token display
                    ThinkingView(elapsedSeconds: elapsedSeconds)
                        .padding(.horizontal, 8)
                } else {
                    // AI message - left aligned as plain text
                    AIMessageTextView(content: message.content)
                        .environment(\.openURL, OpenURLAction { url in
                            openURL(url)
                            return .handled
                        })
                    
                    // Add Feedback Buttons below AI message (only when content is finalized)
                    if isContentFinal && message.mode != .think && !message.hasToolCallAfter { 
                        FeedbackButtonsView(
                            onCopy: {
                                UIPasteboard.general.string = message.content
                                showToast(message: "copied to clipboard")
                            },
                            onThumbsUp: {
                                // Handle thumbs up feedback
                                showToast(message: "thanks for your feedback!")
                            },
                            onThumbsDown: {
                                // Handle thumbs down feedback
                                showToast(message: "thanks for your feedback!")
                            }
                        )
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    }
                }
            } else if message.type == .user {
                // User message - right aligned with blue background
                UserMessageBubbleView(content: message.content)
            } else if message.type == .toolCall {
                // Tool Call Message View
                ToolCallBubbleView(
                    toolName: message.toolName ?? "Unknown Tool",
                    args: message.toolArgs ?? [:],
                    showDetails: $showToolDetails
                )
            } else if message.type == .toolResult {
                // Tool Result Message View
                ToolResultBubbleView(
                    content: message.content,
                    result: message.toolResult ?? [:],
                    showDetails: $showToolDetails
                )
            } else if message.type == .error {
                // Error message
                ErrorMessageBubbleView(content: message.content)
            }
        }
        .padding(.vertical, 4)
        .opacity(hasAppeared ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: hasAppeared)
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = message.content
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            if message.type == .ai {
                Button(action: {
                    let activityController = UIActivityViewController(
                        activityItems: [message.content],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(activityController, animated: true)
                    }
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .id(message.id) // Ensure unique ID for scrolling
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                hasAppeared = true
            }
            
            if message.type == .ai && message.mode == .think {
                // Start timer for "Thinking for X seconds" display
                startTimer()
            } else if message.type == .ai {
                // For AI messages, mark content as final after a brief delay
                // This prevents feedback buttons from showing during streaming
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        isContentFinal = true
                    }
                }
            } else {
                // User messages are always final
                isContentFinal = true
            }
        }
        .onChange(of: message.content) { _, _ in
            // When content changes (during streaming), reset finalized state
            if message.type == .ai && message.mode != .think {
                isContentFinal = false
                
                // Set it to final again after a delay when streaming stops
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        isContentFinal = true
                    }
                }
            }
        }
        .onDisappear {
            // Clean up timer
            timer?.invalidate()
            timer = nil
        }
        .sheet(isPresented: $showToolDetails) {
            ToolDetailsSheet(message: message)
        }
    }
    
    // Timer functionality for thinking mode
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }
    
    // Helper to show the feedback toast
    private func showToast(message: String) {
        print("📱 Showing toast message: \(message)")
        // Use the toast manager to show messages
        toastManager.showInfo(message: message)
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageView(message: ChatMessage.createUserMessage(content: "Tell me about quantum physics"))
        
        MessageView(message: ChatMessage.createAIMessage(
            content: "Quantum physics is a fascinating field that explores the behavior of matter and energy at the atomic and subatomic scales.",
            mode: .main
        ))
        
        MessageView(message: ChatMessage.createAIMessage(
            content: "Let me think about quantum physics deeply...",
            mode: .think
        ))
        
        MessageView(message: ChatMessage.createErrorMessage(content: "Sorry, there was an error processing your request."))
        
        // Tool call preview
        MessageView(message: ChatMessage.createToolCallMessage(
            name: "web_search",
            args: ["query": "quantum physics", "limit": "5"]
        ))
        
        // Tool result preview
        MessageView(message: ChatMessage.createToolResultMessage(
            content: "Found information from 3 sources",
            toolCallId: "tool123",
            result: ["content": "Quantum physics information retrieved"]
        ))
    }
    .padding()
    .background(Color(.systemBackground))
    .environmentObject(ToastManager())
} 
