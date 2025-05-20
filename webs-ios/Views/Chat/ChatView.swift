import SwiftUI
import PhosphorSwift
import Combine

// Toast preference key for sending toast preferences up the view hierarchy
struct ToastPreferenceKey: PreferenceKey {
    static var defaultValue: ToastInfo?
    
    static func reduce(value: inout ToastInfo?, nextValue: () -> ToastInfo?) {
        value = nextValue() ?? value
    }
}

// Toast info struct for preference communication
struct ToastInfo: Equatable {
    let message: String
}

// Height preference key for command bar
struct CommandBarHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var dialogManager: ConfirmationDialogManager
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.colorScheme) private var colorScheme
    @Binding var showSidebar: Bool
    @Binding var sidebarWidth: CGFloat
    @State private var isPrivate: Bool = false
    
    // State for fade animations
    @State private var isViewFadingOut = false
    @State private var isFadingToNewChat = false
    @State private var previousChatId: String?
    @State private var commandBarResetID = UUID() // For forcing CommandBarView refresh
    @State private var forceRefreshID = UUID() // For forcing entire view refresh
    
    // Keyboard state
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    
    @State private var commandBarHeight: CGFloat = 0
    @State private var isLoading = false
    
    @State private var hasAppeared = false

    // Nav menu and dialog states
    @State private var showNavBarMenu = false
    @State private var showRenameDialog = false
    @State private var showShareSheet = false
    @State private var showArchiveConfirmation = false
    @State private var showDeleteConfirmation = false
    
    init(chatId: String?) {
        // If chatId is nil, it's a new chat
        if let id = chatId {
            _viewModel = StateObject(wrappedValue: ChatViewModel(chatId: id))
        } else {
            // For new chat, create a viewModel without loading a specific chat
            _viewModel = StateObject(wrappedValue: ChatViewModel())
        }
        
        // Initialize bindings with constant values for preview purposes
        self._showSidebar = .constant(false)
        self._sidebarWidth = .constant(0)
    }
    
    init(chatId: String?, showSidebar: Binding<Bool>, sidebarWidth: Binding<CGFloat>) {
        // If chatId is nil, it's a new chat
        if let id = chatId {
            _viewModel = StateObject(wrappedValue: ChatViewModel(chatId: id))
        } else {
            // For new chat, create a viewModel without loading a specific chat
            _viewModel = StateObject(wrappedValue: ChatViewModel())
        }
        
        self._showSidebar = showSidebar
        self._sidebarWidth = sidebarWidth
    }
    
    var body: some View {
        GeometryReader { geometry in
            // Use a ZStack to completely separate the navbar from the content area
            ZStack(alignment: .top) {
                // Background for entire view
                Theme.background(scheme: colorScheme)
                    .ignoresSafeArea()
                
                // Content area in a VStack - this starts below the navbar
                VStack(spacing: 0) {
                    // Spacer matching navbar height to position content below navbar
                    Spacer()
                        .frame(height: 44 + SafeAreaUtils.getSafeAreaTop())
                    
                    // Content area wrapped in modularized component
                    ChatContentContainer(
                        viewModel: viewModel,
                        isPrivate: isPrivate,
                        isViewFadingOut: isViewFadingOut,
                        commandBarResetID: commandBarResetID,
                        keyboardHeight: keyboardHeight,
                        isKeyboardVisible: isKeyboardVisible,
                        onCreateNewChat: { prompt in
                            let newChatId = appViewModel.createChatAndAddFirstMessage(prompt: prompt, isPrivate: isPrivate)
                            
                            // Only fade out the content, not the navbar or command bar
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isViewFadingOut = true
                            }
                            
                            // Navigate after a short delay for animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                // Safely unwrap optional String
                                if let chatId = newChatId {
                                    appViewModel.navigateToChat(id: chatId)
                                } else {
                                    // Handle the case when chat ID is nil - perhaps show an error
                                    toastManager.showInfo(message: "Failed to create chat")
                                }
                                
                                // Schedule the fade-in after navigation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isViewFadingOut = false
                                    }
                                }
                            }
                        }
                    )
                    .onPreferenceChange(ToastPreferenceKey.self) { toastInfo in
                        if let info = toastInfo {
                            toastManager.showInfo(message: info.message)
                        }
                    }
                }
                .navigationBarHidden(true) // Hide the default navigation bar
                
                // Custom navigation bar using the new component
                ChatNavigationBar(
                    chatId: viewModel.chatId,
                    messagesExist: !viewModel.messages.isEmpty,
                    isPrivate: isPrivate,
                    onSidebarButtonTap: openSidebar,
                    onMenuButtonTap: showNavMenu,
                    onPrivacyToggle: {
                        // Add haptic feedback
                        HapticManager.shared.lightImpact()
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPrivate.toggle()
                            viewModel.setPrivateMode(isPrivate)
                        }
                    },
                    onNewChatButtonTap: {
                        // Add haptic feedback
                        HapticManager.shared.lightImpact()
                        
                        // First reset all values with animation
                        withAnimation(.easeInOut(duration: 0.3)) {
                            // Clear input text with fade animation
                            viewModel.inputText = ""
                            
                            // Reset to main mode
                            viewModel.currentMode = .main
                            
                            // Make sure loading state is off
                            viewModel.isLoading = false
                        }
                        
                        // Generate new ID to force CommandBarView refresh with clean state
                        commandBarResetID = UUID()
                        
                        // Navigate to new chat immediately - don't wait for animation
                        appViewModel.navigateToNewChat()
                    }
                )
                
                // Toast notification using the new component
                ChatToastView(
                    toastMessage: toastManager.toastMessage,
                    isVisible: toastManager.showToast
                )
                
                // Menus and dialogs using the new component
                ChatMenusManager(
                    showNavBarMenu: $showNavBarMenu,
                    showRenameDialog: $showRenameDialog,
                    showShareSheet: $showShareSheet,
                    showArchiveConfirmation: $showArchiveConfirmation,
                    showDeleteConfirmation: $showDeleteConfirmation,
                    chatId: viewModel.chatId,
                    chatTitle: viewModel.chatId != nil ? (appViewModel.chats.first(where: { $0.id == viewModel.chatId })?.title ?? "Chat") : "New Chat",
                    onHandleNavMenuAction: handleNavMenuAction,
                    onRenameChat: renameChat
                )
            }
            .ignoresSafeArea(edges: .vertical) // Ensures content extends fully
            .opacity(hasAppeared ? 1 : 0) // Start with 0 opacity
            .animation(.easeIn(duration: 0.4), value: hasAppeared) // Fade in when appeared
            .onAppear {
                // Trigger fade-in animation
                withAnimation(.easeIn(duration: 0.4)) {
                    hasAppeared = true
                }
                
                // Reset the fade state when view appears
                isViewFadingOut = false
                
                // Track the previous chat ID for animation decisions
                previousChatId = viewModel.chatId
                
                // For new chats, focus on the command bar directly
                if viewModel.messages.isEmpty && viewModel.chatId == nil {
                    print("📋 ChatView: New chat detected")
                    // We'll let ChatContentContainer handle the focus
                }
            }
            // Use keyboard manager instead of direct observers
            .manageKeyboard(height: $keyboardHeight, isVisible: $isKeyboardVisible)
            
            // Animate when messages change in the ViewModel
            .onChange(of: viewModel.messages.count) { oldCount, newCount in
                print("🔍 ChatView: Messages count changed from \(oldCount) to \(newCount)")
                // Trigger animation if needed
                if oldCount == 0 || newCount == 0 {
                    // Simple state change to force animation
                    let temp = viewModel.messages.isEmpty
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            // This is just to ensure the animation system recognizes a change
                            _ = temp
                            // Generate a new ID to force view refresh
                            forceRefreshID = UUID()
                        }
                    }
                }
            }
            // Force refresh ID based on the viewModel messages count and the forceRefreshID for explicit refreshes
            .id("chat-\(viewModel.chatId ?? "new")-\(viewModel.messages.count)-\(forceRefreshID)")
            
            // Share sheet - presented modally
            .sheet(isPresented: $showShareSheet) {
                if let chatId = viewModel.chatId, 
                   let chat = appViewModel.chats.first(where: { $0.id == chatId }) {
                    ShareSheet(
                        chatId: chatId,
                        chatTitle: chat.title,
                        isPresented: $showShareSheet
                    )
                }
            }
            
            // Confirmation dialogs
            .onChange(of: showArchiveConfirmation) { _, show in
                if show {
                    dialogManager.showDialog(
                        title: "archive this chat?",
                        message: "you can access archived chats from the settings menu.",
                        confirmLabel: "archive",
                        cancelLabel: "cancel",
                        confirmRole: .destructive,
                        onConfirm: {
                            // Archive action would go here
                            // For now, just show a toast
                            toastManager.showInfo(message: "chat archived")
                            showArchiveConfirmation = false
                        },
                        onCancel: {
                            showArchiveConfirmation = false
                        }
                    )
                }
            }
            
            .onChange(of: showDeleteConfirmation) { _, show in
                if show {
                    dialogManager.showDialog(
                        title: "delete this chat?",
                        message: "this action cannot be undone.",
                        confirmLabel: "delete",
                        cancelLabel: "cancel",
                        confirmRole: .destructive,
                        onConfirm: {
                            deleteChat()
                        },
                        onCancel: {
                            showDeleteConfirmation = false
                        }
                    )
                }
            }
        }
        .background(Theme.background(scheme: colorScheme))
        .onPreferenceChange(CommandBarHeightKey.self) { height in
            commandBarHeight = height
        }
    }
    
    // Helper methods for sidebar animation
    private func openSidebar() {
        // Add haptic feedback before opening sidebar
        HapticManager.shared.lightImpact()
        
        // First set the width to match the current position (0)
        sidebarWidth = 0
        
        // Then set the showSidebar state
        showSidebar = true
        
        // No need to animate here, the ContentView will handle the animation through binding
    }
    
    // MARK: - Nav Menu Methods
    
    private func showNavMenu() {
        // Don't show menu for new chats
        if viewModel.chatId == nil {
            return
        }
        
        // Add haptic feedback 
        HapticManager.shared.lightImpact()
        
        // Show the nav menu
        withAnimation {
            showNavBarMenu = true
        }
    }
    
    private func handleNavMenuAction(_ action: NavBarMenuAction) {
        switch action {
        case .rename:
            showRenameDialog = true
        case .share:
            showShareSheet = true
        case .invite:
            // Not implemented yet
            toastManager.showInfo(message: "invite feature coming soon")
        case .archive:
            showArchiveConfirmation = true
        case .delete:
            showDeleteConfirmation = true
        }
    }
    
    private func renameChat(_ newName: String) {
        // Make sure we have a chat ID
        guard let chatId = viewModel.chatId,
              var chat = appViewModel.chats.first(where: { $0.id == chatId }) else {
            return
        }
        
        // Update the chat title
        chat.title = newName
        
        // Save the updated chat using Task for async operation
        Task {
            do {
                let chatService = ChatService()
                let _ = try await chatService.updateChat(chat)
                
                // Refresh chats in the app view model
                await appViewModel.refreshChats() // Use the public refresh method instead
                
                // After loading chats, we should also reload the current chat to update UI
                if let chatId = viewModel.chatId {
                    await appViewModel.loadChat(chatId: chatId)
                }
                
                // Show confirmation toast on the main thread
                await MainActor.run {
                    toastManager.showInfo(message: "chat renamed")
                }
            } catch {
                // Handle error on the main thread
                await MainActor.run {
                    print("Error renaming chat: \(error)")
                    toastManager.showInfo(message: "Failed to rename chat")
                }
            }
        }
    }
    
    private func deleteChat() {
        // Make sure we have a chat ID
        guard let chatId = viewModel.chatId else {
            showDeleteConfirmation = false
            return
        }
        
        // Use Task to handle the async deleteChat operation
        Task {
            // Delete the chat
            appViewModel.deleteChat(id: chatId)
            
            // Hide the confirmation dialog on the main thread
            await MainActor.run {
                showDeleteConfirmation = false
                
                // Show confirmation toast
                toastManager.showInfo(message: "chat deleted")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ChatView(chatId: nil)
        .environmentObject(AppViewModel())
        .environmentObject(ToastManager())
}
