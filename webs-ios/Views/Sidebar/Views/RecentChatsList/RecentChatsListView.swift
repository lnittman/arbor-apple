import SwiftUI
import PhosphorSwift

// Recent chats list
struct RecentChatsListView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Binding var isShowing: Bool
    @Environment(\.colorScheme) private var colorScheme
    var searchFilter: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Section header
            ChatsSectionHeaderView {
                navigateToNewChat()
            }
            
            if !appViewModel.chats.isEmpty {
                // Chat list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(filteredChats) { chat in
                            RecentChatRowView(chat: chat, isShowing: $isShowing)
                        }
                    }
                    .padding(.top, 12)
                }
            } else {
                // Empty state with new chat button
                VStack(spacing: 16) {
                    // New chat button
                    Button {
                        navigateToNewChat()
                    } label: {
                        HStack {
                            Ph.notePencil.duotone
                                .color(Theme.mutedForeground(scheme: colorScheme))
                                .frame(width: 20, height: 20)
                            
                            Text("new chat")
                                .font(Font.iosevkaBody())
                                .foregroundColor(Theme.primaryForeground(scheme: colorScheme))
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 8)
                    .padding(.top, 12)
                }
                .padding(.bottom, 16)
            }
        }
    }
    
    // Helper function to navigate to new chat
    private func navigateToNewChat() {
        appViewModel.navigateToNewChat()
        withAnimation {
            isShowing = false
        }
    }
    
    // Filter chats based on search text if provided
    private var filteredChats: [Chat] {
        if searchFilter.isEmpty {
            return appViewModel.chats
        } else {
            return appViewModel.chats.filter { chat in
                chat.title.localizedCaseInsensitiveContains(searchFilter)
            }
        }
    }
} 
