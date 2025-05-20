import SwiftUI
import PhosphorSwift

struct ChatContentContainer: View {
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    let isPrivate: Bool
    let isViewFadingOut: Bool
    let commandBarResetID: UUID
    let keyboardHeight: CGFloat
    let isKeyboardVisible: Bool
    
    // Add focus state to track and control keyboard
    @FocusState private var isInputFocused: Bool
    
    var onCreateNewChat: (String) -> Void
    
    var body: some View {
        ZStack {
            if !viewModel.messages.isEmpty {
                // Main chat content for existing chat - including its own CommandBarView
                existingChatContent
            } else {
                // New chat view (empty state with command bar)
                newChatContent
            }
        }
        // Sync our local focus state with the view model to control keyboard
        .onChange(of: isInputFocused) { oldValue, newValue in
            print("📋 ChatContentContainer: isInputFocused changed from \(oldValue) to \(newValue)")
            // Update the CommandBarView's focus state through the view model if needed
            if viewModel.commandBarFocused != newValue {
                print("📋 ChatContentContainer: Updating viewModel.commandBarFocused to \(newValue)")
                viewModel.commandBarFocused = newValue
            } else {
                print("📋 ChatContentContainer: viewModel.commandBarFocused already matches isInputFocused (\(newValue))")
            }
        }
        // ... existing code ...
        .onChange(of: viewModel.commandBarFocused) { oldValue, newValue in
            print("📋 ChatContentContainer: viewModel.commandBarFocused changed from \(oldValue) to \(newValue)")
            // Update our local focus state if the view model changes
            if isInputFocused != newValue {
                print("📋 ChatContentContainer: Updating isInputFocused to \(newValue)")
                isInputFocused = newValue
            } else {
                print("📋 ChatContentContainer: isInputFocused already matches viewModel.commandBarFocused (\(newValue))")
            }
        }
    }
    
    // MARK: - Existing Chat Content
    
    private var existingChatContent: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { contentGeometry in
                ChatContentView(viewModel: viewModel, hideCommandBar: true)
                    .frame(width: contentGeometry.size.width, height: contentGeometry.size.height)
                    .environmentObject(appViewModel)
                    // Add tap gesture to dismiss keyboard when tapping on content area
                    .contentShape(Rectangle()) // Make entire area tappable
                    .onTapGesture {
                        if isKeyboardVisible {
                            dismissKeyboard()
                        }
                    }
            }
            .overlay(
                Group {
                    if viewModel.messages.isEmpty && isPrivate {
                        // Private chat message overlay
                        PrivateMessageOverlay()
                    }
                }
            )
            .opacity(isViewFadingOut ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: isViewFadingOut)
            .onAppear {
                // Ensure keyboard is not shown when existing chat content appears
                print("📋 ChatContentContainer.existingChatContent: onAppear called")
                if !viewModel.messages.isEmpty {
                    // Make sure keyboard is not shown for existing chats with messages
                    viewModel.commandBarFocused = false
                    isInputFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            
            // Bottom command bar - only visible if not fading
            if !isViewFadingOut {
                chatCommandBar
            }
        }
    }
    
    // MARK: - New Chat Content
    
    private var newChatContent: some View {
        ZStack(alignment: .bottom) {
            // Empty background - no animation needed since it's just a background
            GeometryReader { geometry in
                EmptyChatView(geometry: geometry)
                    // Add tap gesture to dismiss keyboard when tapping on empty area
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isKeyboardVisible {
                            dismissKeyboard()
                        }
                    }
            }
                .opacity(isViewFadingOut ? 0 : 1) // Only fade the empty state, not the command bar
                .animation(.easeInOut(duration: 0.3), value: isViewFadingOut)
                .overlay(
                    Group {
                        if isPrivate {
                            // Private chat message overlay
                            PrivateMessageOverlay()
                                .offset(y: isKeyboardVisible ? -keyboardHeight/3 : 0) // Still animate the overlay
                                .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
                        }
                    }
                )
            
            // Command input bar at the bottom - fixed position that moves with keyboard
            VStack {
                Spacer() // Push to bottom
                
                // Add background Rectangle with card color
                ZStack {
                    // Full-width background that extends to the bottom of the screen
                    Rectangle()
                        .fill(Theme.card(scheme: colorScheme))
                        .frame(height: 150) // Adjusted to account for the safe area
                        .offset(y: 75) // Half of the height 
                        .allowsHitTesting(false)
                        
                    CommandBarView(
                        text: $viewModel.inputText,
                        mode: $viewModel.currentMode,
                        isLoading: $viewModel.isLoading,
                        commandBarFocused: $viewModel.commandBarFocused,
                        onSubmit: {
                            // For new chat only - create chat entry, add first message, then navigate
                            let prompt = viewModel.inputText
                            guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            
                            viewModel.inputText = "" // Clear input immediately
                            onCreateNewChat(prompt)
                        }
                    )
                }
                .id(commandBarResetID) // Force refresh when ID changes
                // Adjust bottom padding based on keyboard state
                .padding(.bottom, 0)
                // Add swipe down gesture to dismiss keyboard
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            // If drag is downward with sufficient velocity/distance
                            if value.translation.height > 20 && isKeyboardVisible {
                                dismissKeyboard()
                            }
                        }
                )
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            // Only move the CommandBarView exactly the distance needed to sit above the keyboard
            .offset(y: isKeyboardVisible && keyboardHeight > 0 ? -(keyboardHeight - SafeAreaUtils.getSafeAreaBottom()) : 0)
            .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible && keyboardHeight > 0)
        }
        .onAppear {
            print("📋 ChatContentContainer.newChatContent: onAppear called")
            
            // Try to force focus immediately and with delays
            focusCommandBar()
        }
    }
    
    // Add helper method to focus command bar directly
    private func focusCommandBar() {
        print("📋 ChatContentContainer: focusCommandBar() called")
        
        // Only auto-focus for empty chats
        if viewModel.messages.isEmpty {
            // Use the KeyboardManager's focus request approach - set both states
            viewModel.commandBarFocused = true
            
            // Request focus with a delay to ensure view is fully initialized
            KeyboardManager.requestFocus(focusPoint: $isInputFocused, delay: 1.0)
            
            // Ensure view model state stays in sync with a slightly longer delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                viewModel.commandBarFocused = true
            }
        } else {
            // For chats with existing messages, don't auto-focus
            viewModel.commandBarFocused = false
            isInputFocused = false
        }
    }
    
    // MARK: - Common Command Bar
    
    private var chatCommandBar: some View {
        // Command input bar at the bottom - fixed position that moves with keyboard
        ZStack(alignment: .bottom) {
            // Full-width background that extends to the bottom of the screen
            Rectangle()
                .fill(Theme.card(scheme: colorScheme))
                .frame(height: 150) // Adjusted to account for the safe area
                .offset(y: 75) // Half of the height 
                .allowsHitTesting(false)
                
            VStack(spacing: 0) {
                Spacer() // Push to bottom
                
                CommandBarView(
                    text: $viewModel.inputText,
                    mode: $viewModel.currentMode,
                    isLoading: $viewModel.isLoading,
                    commandBarFocused: $viewModel.commandBarFocused,
                    onSubmit: {
                        viewModel.sendMessage()
                    }
                )
                .id(commandBarResetID) // Force refresh when ID changes
                .padding(.bottom, 0)
            }
            // Add swipe down gesture to dismiss keyboard
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        // If drag is downward with sufficient velocity/distance
                        if value.translation.height > 20 && isKeyboardVisible {
                            dismissKeyboard()
                        }
                    }
            )
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: isViewFadingOut)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .zIndex(10) // Ensure this VStack is on top of the chat content
        // Only move the CommandBarView exactly the distance needed to sit above the keyboard
        .offset(y: isKeyboardVisible && keyboardHeight > 0 ? -(keyboardHeight - SafeAreaUtils.getSafeAreaBottom()) : 0)
        .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible && keyboardHeight > 0)
    }
    
    // Helper function to dismiss keyboard with animation
    private func dismissKeyboard() {
        // Add haptic feedback
        HapticManager.shared.lightImpact()
        
        // Dismiss keyboard with animation
        withAnimation(.easeInOut(duration: 0.25)) {
            isInputFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

#Preview {
    ChatContentContainer(
        viewModel: ChatViewModel(),
        isPrivate: false,
        isViewFadingOut: false,
        commandBarResetID: UUID(),
        keyboardHeight: 0,
        isKeyboardVisible: false,
        onCreateNewChat: { _ in }
    )
    .environmentObject(AppViewModel())
} 
