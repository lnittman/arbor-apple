import SwiftUI

// Bottom fade gradient overlay that provides a seamless transition to the command bar
struct BottomFadeGradient: View {
    @Environment(\.colorScheme) private var colorScheme
    let height: CGFloat = 100  // Further increased height for better coverage
    let commandBarHeight: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            // Upper part of the gradient - subtle fade
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Theme.background(scheme: colorScheme).opacity(0),
                        Theme.background(scheme: colorScheme).opacity(0.7)
                    ]
                ),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height * 0.6)
            
            // Lower part - solid background to ensure complete coverage
            Rectangle()
                .fill(Theme.background(scheme: colorScheme))
                .frame(height: commandBarHeight)
        }
        .padding(.bottom, -commandBarHeight) // Position it right above the command bar
        .allowsHitTesting(false) // Allow touches to pass through to the content below
    }
}

struct ChatContentView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isMessageSending = false
    @State private var commandBarHeight: CGFloat = 0
    var hideCommandBar: Bool = false // New parameter to hide command bar
    @EnvironmentObject var chatViewModel: ChatViewModel
    @State private var scrollTarget: String?
    @State private var scrolledToBottom = true
    private let scrollViewID = "chatScrollView"
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background
                Theme.background(scheme: colorScheme)
                    .ignoresSafeArea()
                
                // Messages list in a scrollable area - now in a container with padding
                VStack(spacing: 0) {
                    MessagesScrollView(viewModel: viewModel, isMessageSending: $isMessageSending, commandBarHeight: commandBarHeight)
                        .background(Theme.background(scheme: colorScheme))
                        .opacity(isMessageSending ? 0 : 1) // Fade out entire view when sending
                        .animation(.easeInOut(duration: 0.3), value: isMessageSending)
                    
                    // Add explicit spacing for command bar instead of using safeAreaInset
                    if !hideCommandBar {
                        // Solid blocker that prevents content from appearing behind command bar
                        ZStack(alignment: .top) {
                            // Solid background
                            Rectangle()
                                .fill(Theme.background(scheme: colorScheme))
                                .frame(height: commandBarHeight + 36)
                            
                            // Fade gradient for smooth transition
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        Theme.background(scheme: colorScheme).opacity(0.5),
                                        Theme.background(scheme: colorScheme)
                                    ]
                                ),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 36)
                            .offset(y: -36)
                        }
                        .frame(height: commandBarHeight + 16)
                        .allowsHitTesting(false)
                    }
                }
                // Make the VStack fill the available space exactly
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Show error message if present
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        ErrorBannerView(message: errorMessage)
                            .padding(.bottom, commandBarHeight + 8)
                    }
                }
                
                // Command input bar - only show if not hidden
                if !hideCommandBar {
                    VStack(spacing: 0) {
                        // Add a spacer that pushes content up from the command bar
                        Spacer(minLength: 0)
                        
                        // Overlay the fade gradient right above command bar
                        BottomFadeGradient(commandBarHeight: commandBarHeight)
                            .frame(height: 100)
                        
                        // Command input bar with background that extends to edges
                        ZStack {
                            // Extended background behind command bar
                            Theme.background(scheme: colorScheme)
                                .frame(height: commandBarHeight)
                                .opacity(0.98)
                            
                            CommandBarView(
                                text: $viewModel.inputText,
                                mode: $viewModel.currentMode,
                                isLoading: $viewModel.isLoading,
                                commandBarFocused: $viewModel.commandBarFocused,
                                onSubmit: {
                                    // Ensure input is valid
                                    print("📱 ChatContentView: onSubmit called with input: \(viewModel.inputText)")
                                    guard !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
                                        print("📱 ChatContentView: Empty input, not proceeding")
                                        return 
                                    }
                                    
                                    // Animate fade out before sending message
                                    print("📱 ChatContentView: Animating fade out before sending")
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        isMessageSending = true
                                    }
                                    
                                    // Create and add the user message immediately so it appears in the UI
                                    let userPrompt = viewModel.inputText
                                    // Clear the input field right away
                                    viewModel.inputText = ""
                                    
                                    // Delay message sending slightly to allow animation
                                    print("📱 ChatContentView: Scheduling message send")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        print("📱 ChatContentView: Calling viewModel.sendMessage()")
                                        
                                        // Restore the view before sending message so user message is visible
                                        withAnimation(.easeIn(duration: 0.2)) {
                                            isMessageSending = false
                                        }
                                        
                                        // Set the input text back for the sendMessage method
                                        viewModel.inputText = userPrompt
                                        viewModel.sendMessage()
                                        // Clear it again right after to avoid showing in input field
                                        viewModel.inputText = ""
                                    }
                                }
                            )
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(key: ViewHeightKey.self, value: geo.size.height)
                                }
                            )
                        }
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .zIndex(10) // Ensure command bar is above other content
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onPreferenceChange(ViewHeightKey.self) { height in
            // Store command bar height for correct padding
            self.commandBarHeight = height
        }
    }
}

// Height preference key to measure CommandBarView height
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Encapsulating the message scroll view logic
struct MessagesScrollView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isMessageSending: Bool
    @State private var isMessageSent = false
    @State private var showPreviousMessages = true
    let commandBarHeight: CGFloat
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    // Always include spacer at the top for proper alignment
                    Color.clear.frame(height: 8)
                    
                    // All messages - no more special handling of latest user message
                    if !viewModel.messages.isEmpty {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                                .transition(
                                    message.type == .user
                                        ? .asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)),
                                                     removal: .opacity)
                                        : .opacity
                                )
                                .environmentObject(viewModel) // Pass the viewModel if needed by MessageView
                        }
                    }
                    
                    // Show typing indicator when loading
                    if viewModel.isLoading {
                        TypingIndicatorView()
                            .padding(.leading, 16)
                            .transition(.opacity)
                    }
                    
                    // Empty state for no messages - helps maintain layout
                    if viewModel.messages.isEmpty {
                        Spacer(minLength: 20)
                    }
                    
                    // Always include spacer at the bottom for stable layout
                    // Add very large bottom padding to ensure nothing gets cut off
                    Color.clear.frame(height: commandBarHeight + 120)
                        .id("bottomSpacer")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 80) // Significantly increased bottom padding
                // Make content fill width but don't set a minimum height
                .frame(maxWidth: .infinity)
                .animation(.easeInOut(duration: 0.3), value: viewModel.messages)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            }
            // Explicitly remove ScrollView's default content insets
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            // Use contentInsets to remove default spacing
            .contentMargins(0)
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: viewModel.messages.count) { _, _ in
                // Always scroll to the bottom when messages change
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo("bottomSpacer", anchor: .top)
                    }
                }
            }
            // Also scroll to bottom when content is streamed (when message content changes)
            .onChange(of: viewModel.messages.last?.content) { _, _ in
                if viewModel.isLoading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("bottomSpacer", anchor: .top)
                        }
                    }
                }
            }
            // Scroll when loading state changes
            .onChange(of: viewModel.isLoading) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("bottomSpacer", anchor: .top)
                        }
                    }
                }
            }
        }
    }
}

// Error message banner
struct ErrorBannerView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.white)
            .padding()
            .background(Color.red.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    // Create a static preview with pre-populated data
    let viewModel = ChatViewModel()
    
    // Manually add messages for preview
    let userMessage = ChatMessage.createUserMessage(content: "Hello, how can you help me today?")
    let aiMessage = ChatMessage.createAIMessage(content: "I'm an AI assistant. I can help you with information, answer questions, assist with tasks, brainstorm ideas, and more. What would you like help with today?", mode: .main)
    
    // Add messages directly to the view model
    viewModel.messages = [userMessage, aiMessage]
    
    return ChatContentView(viewModel: viewModel)
} 
