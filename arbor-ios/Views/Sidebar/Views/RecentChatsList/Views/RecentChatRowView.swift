import SwiftUI
import PhosphorSwift

// Individual recent chat row
struct RecentChatRowView: View {
    var chat: Chat
    @Binding var isShowing: Bool
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isSelected: Bool = false
    @State private var showSelectionAnimation: Bool = false
    
    var body: some View {
        Button(action: {
            // Set the selection state immediately
            showSelectionAnimation = true
            
            Task {
                // First update currentChatId which will trigger fade-out on other selections
                await MainActor.run {
                    appViewModel.currentChatId = chat.id
                }
                
                // Then load the chat content
                await appViewModel.loadChat(chatId: chat.id)
            }
            
            // Close the sidebar after a very short delay to allow the selection animation to be visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation {
                    isShowing = false
                }
            }
        }) {
            HStack {
                // Chat title
                Text(chat.title)
                    .font(Font.iosevkaBody())
                    .foregroundColor(Theme.primaryForeground(scheme: colorScheme))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
            }
            .padding(.vertical, 10) // Taller rows
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .background(
                Group {
                    if isSelected || showSelectionAnimation {
                        Theme.mutedBackground(scheme: colorScheme).cornerRadius(8)
                            .transition(.opacity)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8) // This creates space for the active highlight
        .onChange(of: showSelectionAnimation) { _, newValue in
            if newValue {
                // Very short animation for the selection highlight
                withAnimation(.easeIn(duration: 0.15)) {
                    isSelected = true
                }
            }
        }
        .onAppear {
            // Only set selection state without animation on appear
            isSelected = appViewModel.currentChatId == chat.id
        }
        .onChange(of: appViewModel.currentChatId) { _, newId in
            // Update selection state with animation when current chat changes
            let shouldBeSelected = newId == chat.id
            
            // Only animate if the selection is changing
            if isSelected != shouldBeSelected {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isSelected = shouldBeSelected
                }
            }
        }
    }
} 
