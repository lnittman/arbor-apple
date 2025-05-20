import SwiftUI
import PhosphorSwift

struct ChatMenusManager: View {
    @Binding var showNavBarMenu: Bool
    @Binding var showRenameDialog: Bool
    @Binding var showShareSheet: Bool
    @Binding var showArchiveConfirmation: Bool
    @Binding var showDeleteConfirmation: Bool
    
    let chatId: String?
    let chatTitle: String
    
    var onHandleNavMenuAction: (NavBarMenuAction) -> Void
    var onRenameChat: (String) -> Void
    
    var body: some View {
        ZStack {
            // Nav bar menu
            if showNavBarMenu {
                NavBarMenuView(
                    chatId: chatId,
                    onAction: onHandleNavMenuAction,
                    isPresented: $showNavBarMenu
                )
                .zIndex(150)
            }
            
            // Rename dialog
            if showRenameDialog {
                RenameDialogView(
                    chatTitle: chatTitle,
                    isPresented: $showRenameDialog,
                    onSave: onRenameChat
                )
                .zIndex(150)
            }
        }
    }
}

#Preview {
    ChatMenusManager(
        showNavBarMenu: .constant(true),
        showRenameDialog: .constant(false),
        showShareSheet: .constant(false),
        showArchiveConfirmation: .constant(false),
        showDeleteConfirmation: .constant(false),
        chatId: "test-chat-id",
        chatTitle: "Test Chat",
        onHandleNavMenuAction: { _ in },
        onRenameChat: { _ in }
    )
} 