import Foundation
import SwiftUI
import Clerk
import Network

@MainActor
class AppViewModel: ObservableObject {
    @Published var currentChatId: String?
    @Published var isSignedIn: Bool = false
    @Published var user: User? = nil
    
    // Added for logout animation
    @Published var isLoggingOut = false
    
    // Projects
    @Published var projects: [Project] = []
    @Published var currentProject: Project?
    
    // Chats
    @Published var chats: [Chat] = []
    @Published var currentChat: Chat?
    
    // Loading states
    @Published var isLoadingChats = false
    @Published var isLoadingProjects = false
    @Published var errorMessage: String? = nil
    
    // Services
    private let chatService = ChatService()
    private let projectService = ProjectService()
    
    // Network state
    @Published var isOnline = true
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        // Set up network monitoring
        startNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    /// Check connectivity to the API
    func checkConnectivity() async {
        do {
            // Simple network check
            let isAuthenticated = await APIManager.shared.checkAuthentication()
            await MainActor.run {
                self.isOnline = isAuthenticated
            }
        } catch {
            await MainActor.run {
                self.isOnline = false
            }
        }
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Logout with a fade animation of the entire UI
    func logoutWithAnimation() {
        // Start the fade-out animation
        withAnimation(.easeOut(duration: 0.5)) {
            isLoggingOut = true
        }
        
        // Perform the actual logout after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            Task {
                do {
                    try await self.signOut()
                    
                    // Keep isLoggingOut true for a moment to ensure SignInView starts hidden
                    // Then fade in the SignInView with a smooth animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeIn(duration: 0.6)) {
                            self.isLoggingOut = false
                        }
                    }
                } catch {
                    print("Error during logout: \(error)")
                    // Reset animation state if logout fails
                    withAnimation {
                        self.isLoggingOut = false
                    }
                }
            }
        }
    }
    
    /// Create a new chat and navigate to it
    func createNewChat() {
        guard isOnline else {
            self.errorMessage = "Cannot create new chat while offline"
            return
        }
        
        Task {
            do {
                let newChat = try await chatService.createChat()
                await loadChats() // Refresh chats list
                currentChatId = newChat.id
            } catch {
                self.errorMessage = "Failed to create chat: \(error.localizedDescription)"
                print("Error creating chat: \(error)")
            }
        }
    }
    
    /// Delete a chat
    func deleteChat(id: String) {
        guard isOnline else {
            self.errorMessage = "Cannot delete chat while offline"
            return
        }
        
        Task {
            do {
                try await chatService.deleteChat(id: id)
                await loadChats() // Refresh chats list
                
                // If we deleted the current chat, navigate away
                if currentChatId == id {
                    // If there are other chats, navigate to most recent, otherwise go to new chat screen
                    if let mostRecentChat = chats.first {
                        currentChatId = mostRecentChat.id
                    } else {
                        currentChatId = nil
                    }
                }
            } catch {
                self.errorMessage = "Failed to delete chat: \(error.localizedDescription)"
                print("Error deleting chat: \(error)")
            }
        }
    }
    
    /// Navigate to a specific chat
    func navigateToChat(id: String) {
        print("🔍 AppViewModel - Navigating to chat: \(id), current: \(String(describing: currentChatId))")
        // Force refresh by first setting to nil briefly
        let oldId = currentChatId
        self.objectWillChange.send()
        
        // If we're already on this chat, force a refresh by briefly setting to nil
        if oldId == id {
            print("🔍 AppViewModel - Force refreshing same chat ID")
            currentChatId = nil
            
            // Use a very short delay to allow SwiftUI to register the change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.currentChatId = id
                self.objectWillChange.send()
            }
        } else {
            currentChatId = id
        }
        
        // Load the chat data
        Task {
            await loadChat(chatId: id)
        }
    }
    
    /// Navigate to the new chat screen
    func navigateToNewChat() {
        print("🔍 AppViewModel - Navigating to new chat, current: \(String(describing: currentChatId))")
        currentChatId = nil
    }
    
    /// Create a new project
    func createNewProject(name: String, description: String? = nil, imageData: Data? = nil) {
        guard isOnline else {
            self.errorMessage = "Cannot create project while offline"
            return
        }
        
        Task {
            do {
                let newProject = try await projectService.createProject(name: name, description: description, imageData: imageData)
                await loadProjects() // Refresh projects list
                
                // Select the new project and clear any chat selection
                currentProject = newProject
                currentChatId = nil
            } catch {
                self.errorMessage = "Failed to create project: \(error.localizedDescription)"
                print("Error creating project: \(error)")
            }
        }
    }
    
    /// Delete a project
    func deleteProject(id: String) {
        guard isOnline else {
            self.errorMessage = "Cannot delete project while offline"
            return
        }
        
        Task {
            do {
                try await projectService.deleteProject(id: id)
                await loadProjects() // Refresh projects list
                
                // If we deleted the current project, navigate away
                if currentProject?.id == id {
                    // If there are other projects, navigate to most recent, otherwise clear current project
                    if let mostRecentProject = projects.first {
                        currentProject = mostRecentProject
                        currentChatId = nil // Clear any chat selection when changing projects
                    } else {
                        currentProject = nil
                        currentChatId = nil
                    }
                }
            } catch {
                self.errorMessage = "Failed to delete project: \(error.localizedDescription)"
                print("Error deleting project: \(error)")
            }
        }
    }
    
    /// Load a specific project
    func loadProject(projectId: String) {
        guard isOnline else {
            self.errorMessage = "Cannot load project while offline"
            return
        }
        
        Task {
            do {
                let project = try await projectService.getProject(id: projectId)
                currentProject = project
                
                // Clear any chat selection when explicitly loading a project
                currentChatId = nil
            } catch {
                self.errorMessage = "Failed to load project: \(error.localizedDescription)"
                print("Error loading project: \(error)")
            }
        }
    }
    
    /// Sign out the user using Clerk
    func signOut() async throws {
        try await Clerk.shared.signOut()
        // Clear any local user data
        user = nil
        isSignedIn = false
        chats = []
        projects = []
        currentChat = nil
        currentProject = nil
        currentChatId = nil
    }
    
    /// Load a specific chat
    func loadChat(chatId: String) async {
        guard isOnline else {
            self.errorMessage = "Cannot load chat while offline"
            return
        }
        
        do {
            let chat = try await chatService.getChat(id: chatId)
            currentChat = chat
        } catch {
            self.errorMessage = "Failed to load chat: \(error.localizedDescription)"
            print("Error loading chat: \(error)")
        }
    }
    
    /// Create a new chat, add the first message, and return the ID.
    /// This allows the UI to initiate navigation, and the new ChatViewModel will handle sending.
    func createChatAndAddFirstMessage(prompt: String, isPrivate: Bool) -> String? {
        guard isOnline else {
            self.errorMessage = "Cannot create chat while offline"
            return nil
        }
        
        print("🔍 AppViewModel - Creating chat and adding first message")
        
        var chatId: String? = nil
        
        Task {
            do {
                // Create a new chat with the message as initial content
                let newChat = try await chatService.createChat(
                    title: "New Chat",
                    initialMessage: isPrivate ? nil : prompt
                )
                chatId = newChat.id
                print("🔍 AppViewModel - New chat created with ID: \(newChat.id)")
                
                // Update our state with the new chats list
                await loadChats()
                
                // If already navigated to the chat, load its details
                if currentChatId == newChat.id {
                    await loadChat(chatId: newChat.id)
                }
            } catch {
                self.errorMessage = "Failed to create chat: \(error.localizedDescription)"
                print("Error creating chat with first message: \(error)")
            }
        }
        
        // Create a temporary ID for immediate navigation
        // This will be replaced when the Task completes
        let tempId = UUID().uuidString
        return chatId ?? tempId
    }
    
    /// Update user data from Clerk
    func updateUserFromClerk() {
        if let clerkUser = Clerk.shared.user {
            // Create a local User object from Clerk user data
            self.user = User(
                id: clerkUser.id,
                clerkId: clerkUser.id, // Use the same ID for now
                email: clerkUser.emailAddresses.first?.emailAddress,
                firstName: clerkUser.firstName,
                lastName: clerkUser.lastName,
                imageUrl: nil, // Set to nil to avoid URL conversion issues
                createdAt: Date(), // Default to current date
                updatedAt: Date(), // Default to current date
                hideSharedWarning: false // Default to false
            )
            self.isSignedIn = true
            
            // Load initial data after authentication
            Task {
                print("🔐 User authenticated, loading initial data")
                // Check network connectivity
                await checkConnectivity()
                if isOnline {
                    await loadChats()
                    await loadProjects()
                }
            }
        } else {
            self.user = nil
            self.isSignedIn = false
        }
    }
    
    /// Public method to refresh chats
    func refreshChats() async {
        guard isOnline else {
            self.errorMessage = "Cannot refresh chats while offline"
            return
        }
        
        await loadChats()
    }
    
    // MARK: - Private Methods
    
    private func loadChats() async {
        guard isOnline else { return }
        
        isLoadingChats = true
        errorMessage = nil
        
        do {
            let apiChats = try await chatService.getAllChats()
            chats = apiChats
            isLoadingChats = false
        } catch {
            isLoadingChats = false
            errorMessage = "Failed to load chats: \(error.localizedDescription)"
            print("Error loading chats: \(error)")
        }
    }
    
    private func loadProjects() async {
        guard isOnline else { return }
        
        isLoadingProjects = true
        errorMessage = nil
        
        do {
            let apiProjects = try await projectService.getAllProjects()
            projects = apiProjects
            isLoadingProjects = false
        } catch {
            isLoadingProjects = false
            errorMessage = "Failed to load projects: \(error.localizedDescription)"
            print("Error loading projects: \(error)")
        }
    }
} 
