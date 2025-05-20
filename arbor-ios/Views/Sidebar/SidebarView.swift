import SwiftUI

struct SidebarView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isInputFocused = false
    @Binding var pushOffset: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            // This approach ensures we fill the entire screen when searching
            let fullScreenWidth = UIScreen.main.bounds.width
            
            ZStack {
                // Background
                Theme.background(scheme: colorScheme)
                    .edgesIgnoringSafeArea(.all)
                
                // Content container
                VStack(spacing: 0) {
                    // Top search bar
                    SidebarSearchBar(searchText: $searchText, isSearching: $isSearching)
                        // Force focus when isSearching becomes true
                        .onChange(of: isSearching) { _, newValue in
                            if newValue {
                                // Request first responder status for text field
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                                }
                                
                                // Update push offset when expanding to full width
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    pushOffset = fullScreenWidth
                                }
                            } else {
                                // Reset push offset when returning to sidebar
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    pushOffset = isShowing ? geometry.size.width * 0.8 : 0
                                }
                            }
                        }
                        // Monitor changes to isShowing to handle sidebar close after search
                        .onChange(of: isShowing) { oldValue, newValue in
                            print("🔍 SidebarView - isShowing changed from \(oldValue) to \(newValue)")
                            if !newValue && !isSearching {
                                // If sidebar is being closed and not in search mode, reset push offset
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    pushOffset = 0
                                }
                            }
                        }
                        // Add border-bottom to search row
                        .padding(.bottom, 8)
                        .overlay(
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Theme.border(scheme: colorScheme))
                                .padding(.top, 8),
                            alignment: .bottom
                        )
                    
                    // Contents
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Projects section
                            ProjectsList(isShowing: $isShowing, searchText: $searchText)
                                .id("projects") // Force refresh when selection changes
                                .animation(.easeInOut, value: appViewModel.currentProject?.id)
                                .animation(.easeInOut, value: appViewModel.currentChatId)
                            
                            // Chats section - always show, filter when searching
                            RecentChatsListView(isShowing: $isShowing, searchFilter: isSearching ? searchText : "")
                                .id("chats") // Force refresh when selection changes
                                .animation(.easeInOut, value: appViewModel.currentChatId)
                            
                            Spacer(minLength: 20)
                        }
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded { _ in
                            if isSearching {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                    )
                    
                    // User info at bottom - always show
                    UserProfileFooter()
                }
                .frame(maxHeight: .infinity)
                // This ensures the width is either the original sidebar width or the full screen width
                .frame(width: isSearching ? fullScreenWidth : nil)
            }
            // When in search mode, this ensures we're properly centered on screen
            .position(
                x: isSearching ? fullScreenWidth/2 : geometry.size.width/2,
                y: geometry.size.height/2
            )
        }
        // Apply the animation to all changes when isSearching changes
        .animation(.easeInOut(duration: 0.25), value: isSearching)
        .onAppear {
            print("🔍 SidebarView appeared with isShowing: \(isShowing)")
        }
    }
}

#Preview {
    NavigationStack {
        SidebarView(isShowing: .constant(true), pushOffset: .constant(0))
            .environmentObject(AppViewModel())
    }
} 
