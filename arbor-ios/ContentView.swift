//
//  ContentView.swift
//  webs-ios
//
//  Created by Luke Nittmann on 3/31/25.
//

import SwiftUI
import Clerk
import PhosphorSwift

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var dialogManager = ConfirmationDialogManager()
    @StateObject private var toastManager = ToastManager()
    @StateObject private var chatViewModel = ChatViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(Clerk.self) private var clerk
    
    // State to control view transitions
    @State private var isLoading = true
    @State private var showAuthView = false
    @State private var isTransitioning = false // Track when we're switching between online/offline
    
    // Simplified state management for sidebar
    @State private var showSidebar = false
    @State private var sidebarOffset: CGFloat = 0
    @State private var maxSidebarWidth: CGFloat = 0
    @State private var sidebarPushOffset: CGFloat = 0
    
    // App settings stored in UserDefaults
    @AppStorage("colorScheme") private var userColorScheme: String = "system"
    
    // Animation configuration to use consistently
    private var sidebarAnimation: Animation {
        .interpolatingSpring(mass: 1.0, stiffness: 350, damping: 35, initialVelocity: 0)
    }
    
    var body: some View {
        ZStack {
            // Background that's always visible
            Theme.background(scheme: colorScheme)
                .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                // Show loading indicator
                EmptyView()
            } else {
                Group {
                    if clerk.user != nil {
                        // User is authenticated
                        ZStack {
                            // Main view - shown when online
                            mainAppView
                                .opacity(appViewModel.isOnline && !isTransitioning ? 1 : 0)
                                .opacity(appViewModel.isLoggingOut ? 0 : 1) // Fade out during logout
                            
                            // Offline view - shown when offline
                            if !appViewModel.isOnline || isTransitioning {
                                OfflineView {
                                    // When retry is tapped, check connectivity
                                    Task {
                                        // Remember the current online state
                                        let wasOnlineBefore = appViewModel.isOnline
                                        
                                        // Start transition only if checking from offline state
                                        if !wasOnlineBefore {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                isTransitioning = true
                                            }
                                        }
                                        
                                        // Check connectivity
                                        await appViewModel.checkConnectivity()
                                        
                                        // Only animate if state changed or we were checking
                                        if wasOnlineBefore != appViewModel.isOnline || isTransitioning {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    isTransitioning = false
                                                }
                                            }
                                        }
                                    }
                                }
                                .opacity(!appViewModel.isOnline || isTransitioning ? 1 : 0)
                            }
                        }
                        .animation(.easeInOut(duration: 0.5), value: appViewModel.isOnline)
                    } else {
                        // User is not authenticated, show sign-in view
                        SignInView()
                            .transition(.opacity)
                            // Initially transparent if coming from logout, then fade in
                            .opacity(appViewModel.isLoggingOut ? 0 : 1)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: clerk.user != nil) // Animate auth state changes
                .environmentObject(appViewModel)
                .environmentObject(dialogManager)
                .environmentObject(toastManager)
                .environmentObject(chatViewModel)
                .tint(Theme.primary(scheme: colorScheme))
                .environment(\.colorScheme, colorScheme)
            }
            
            // Custom confirmation dialog at the app level - always on top
            if dialogManager.isShowingDialog {
                ConfirmationDialogView(
                    title: dialogManager.dialogTitle,
                    message: dialogManager.dialogMessage,
                    confirmLabel: dialogManager.confirmLabel,
                    cancelLabel: dialogManager.cancelLabel,
                    confirmRole: dialogManager.confirmRole,
                    isPresented: $dialogManager.isShowingDialog,
                    confirmAction: dialogManager.confirmAction,
                    cancelAction: dialogManager.cancelAction
                )
            }
            
            // Toast notification - always on top
            // Always render the VStack and control visibility with opacity
            VStack {
                if toastManager.displayLocation == .top {
                    toastManager.toastView()
                        .padding(.top, 20)
                    Spacer()
                } else if toastManager.displayLocation == .middle {
                    Spacer()
                    toastManager.toastView()
                    Spacer()
                } else { // .bottom
                    Spacer()
                    toastManager.toastView()
                        .padding(.bottom, 20)
                }
            }
            .opacity(toastManager.showToast ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: toastManager.showToast)
        }
        .task {
            // Wait for Clerk to finish loading before showing the appropriate view
            try? await clerk.load()
            
            // Check connectivity and API authentication
            await appViewModel.checkConnectivity()
            
            // Update AppViewModel with user info after Clerk loads
            appViewModel.updateUserFromClerk()
            
            // Fade in the appropriate view with a smooth animation
            withAnimation(.easeIn(duration: 0.3)) {
                isLoading = false
            }
        }
        .preferredColorScheme(getPreferredColorScheme())
        .onChange(of: clerk.user) { oldValue, newValue in
            // When user changes (sign in or sign out)
            if oldValue == nil && newValue != nil {
                // User just signed in - reset states
                showSidebar = false
                sidebarOffset = 0
                sidebarPushOffset = 0
                
                // Reset current chat in AppViewModel to ensure we start with a new chat
                appViewModel.currentChatId = nil
                
                // Update user from Clerk and trigger data loading
                appViewModel.updateUserFromClerk()
                
                // Check connectivity
                Task {
                    await appViewModel.checkConnectivity()
                }
            }
            // Show "logged out" toast when user changes to nil (logged out)
            else if oldValue != nil && newValue == nil {
                // Update user from Clerk
                appViewModel.updateUserFromClerk()
                
                toastManager.showLoggedOut()
            }
        }
        .onChange(of: appViewModel.isOnline) { oldValue, newValue in
            // When online status changes, use a smooth transition
            withAnimation(.easeInOut(duration: 0.3)) {
                isTransitioning = true
            }
            
            // Dismiss keyboard when going offline
            if !newValue {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
            // Complete the transition after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isTransitioning = false
                }
            }
        }
    }
    
    private var mainAppView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Main content (always present)
                NavigationStack {
                    // Always show ChatView, it will handle both new and existing chats
                    ChatView(
                        chatId: appViewModel.currentChatId,
                        showSidebar: $showSidebar, 
                        sidebarWidth: $sidebarOffset
                    )
                    .environmentObject(appViewModel)
                    .id("chat-view-\(appViewModel.currentChatId ?? "new")")
                    .background(Theme.background(scheme: colorScheme))
                    .preferredColorScheme(colorScheme)
                    .font(Font.iosevkaBody())
                }
                // Always use the same offset for main content
                .offset(x: max(sidebarOffset, sidebarPushOffset))
                
                // Overlay that only covers the content area when sidebar is open
                if showSidebar || sidebarOffset > 0 {
                    Color.black.opacity(0.3 * min(sidebarOffset / maxSidebarWidth, 1.0))
                        .frame(width: geometry.size.width)
                        .offset(x: sidebarOffset)
                        .ignoresSafeArea()
                        .onTapGesture(perform: closeSidebar)
                }
                
                // Sidebar with exact positioning to connect with content edge
                if showSidebar || sidebarOffset > 0 {
                    SidebarView(isShowing: $showSidebar, pushOffset: $sidebarPushOffset)
                        .frame(width: maxSidebarWidth)
                        .offset(x: sidebarOffset - maxSidebarWidth)
                        .transition(.move(edge: .leading))
                        .zIndex(1) // Ensure sidebar is above other elements
                }
            }
            .onAppear {
                // Set max sidebar width on appear
                maxSidebarWidth = geometry.size.width * 0.8
                print("🔍 ContentView appeared, showSidebar: \(showSidebar)")
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                // Update max sidebar width if screen size changes
                maxSidebarWidth = newWidth * 0.8
            }
            .onChange(of: showSidebar) { oldValue, newValue in
                print("🔍 ContentView - showSidebar changed from \(oldValue) to \(newValue)")
                if newValue {
                    // Dismiss keyboard if sidebar is opening
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                withAnimation(sidebarAnimation) {
                    sidebarOffset = newValue ? maxSidebarWidth : 0
                }
            }
            // Simplified gesture - use a single DragGesture for better control
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let translation = value.translation.width
                        
                        // For opening (right swipe)
                        if !showSidebar && translation > 0 {
                            sidebarOffset = min(translation, maxSidebarWidth)
                            sidebarPushOffset = min(translation, maxSidebarWidth)
                        }
                        // For closing (left swipe)
                        else if showSidebar && translation < 0 {
                            let newOffset = max(0, maxSidebarWidth + translation)
                            sidebarOffset = newOffset
                            sidebarPushOffset = newOffset
                        }
                    }
                    .onEnded { value in
                        let translation = value.translation.width
                        let velocity = value.predictedEndTranslation.width
                        
                        // For opening gesture (right swipe)
                        if !showSidebar && translation > 0 {
                            if translation > maxSidebarWidth/3 || 
                               (translation > 20 && velocity > translation) {
                                // Dismiss keyboard if it's open
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                openSidebar()
                            } else {
                                closeSidebar()
                            }
                        }
                        // For closing gesture (left swipe)
                        else if showSidebar && translation < 0 {
                            if -translation > maxSidebarWidth/3 || 
                               (translation < -20 && velocity < translation) {
                                closeSidebar()
                            } else {
                                openSidebar()
                            }
                        }
                    }
            )
        }
    }
    
    // Helper methods for sidebar animation - now set both offsets simultaneously
    private func openSidebar() {
        // Dismiss keyboard if it's open
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Provide light haptic feedback
        HapticManager.shared.lightImpact()
        
        showSidebar = true
        withAnimation(sidebarAnimation) {
            sidebarOffset = maxSidebarWidth
            sidebarPushOffset = maxSidebarWidth 
        }
    }
    
    private func closeSidebar() {
        // Provide light haptic feedback
        HapticManager.shared.lightImpact()
        
        withAnimation(sidebarAnimation) {
            sidebarOffset = 0
            sidebarPushOffset = 0
        }
        // Delay setting showSidebar to false until animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showSidebar = false
        }
    }
    
    // Get color scheme from UserDefaults
    private func getPreferredColorScheme() -> ColorScheme? {
        switch userColorScheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // System default
        }
    }
}

#Preview {
    ContentView()
}
