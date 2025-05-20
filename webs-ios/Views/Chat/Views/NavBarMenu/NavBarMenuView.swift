import SwiftUI
import PhosphorSwift

// Menu action types for the navbar menu
enum NavBarMenuAction {
    case rename
    case share
    case invite
    case archive
    case delete
}

struct NavBarMenuView: View {
    let chatId: String?
    let onAction: (NavBarMenuAction) -> Void
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            // Position the menu below the navbar
            VStack(alignment: .center) {
                // Add top space to position below navbar (44 + safe area)
                Spacer()
                    .frame(height: 44 + getSafeAreaTop() + 8)
                
                // Menu content
                VStack(spacing: 0) {
                    // Menu header
                    Text("chat options")
                        .font(Font.iosevkaHeadline())
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                        .padding(.vertical, 16)
                    
                    Divider()
                        .background(Theme.border(scheme: colorScheme))
                    
                    // Menu items
                    MenuItemButton(
                        title: "rename",
                        icon: Ph.pencilSimple.duotone,
                        iconColor: Theme.primary(scheme: colorScheme)
                    ) {
                        handleAction(.rename)
                    }
                    
                    Divider()
                        .background(Theme.border(scheme: colorScheme))
                    
                    MenuItemButton(
                        title: "share",
                        icon: Ph.share.duotone,
                        iconColor: Theme.primary(scheme: colorScheme)
                    ) {
                        handleAction(.share)
                    }
                    
                    Divider()
                        .background(Theme.border(scheme: colorScheme))
                    
                    MenuItemButton(
                        title: "invite",
                        icon: Ph.userPlus.duotone,
                        iconColor: Theme.primary(scheme: colorScheme)
                    ) {
                        handleAction(.invite)
                    }
                    
                    Divider()
                        .background(Theme.border(scheme: colorScheme))
                    
                    MenuItemButton(
                        title: "archive",
                        icon: Ph.archive.duotone,
                        iconColor: .blue
                    ) {
                        handleAction(.archive)
                    }
                    
                    Divider()
                        .background(Theme.border(scheme: colorScheme))
                    
                    MenuItemButton(
                        title: "delete",
                        icon: Ph.trash.duotone,
                        iconColor: .red
                    ) {
                        handleAction(.delete)
                    }
                }
                .background(Theme.card(scheme: colorScheme))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .frame(width: 280)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .opacity(isPresented ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
    
    // Helper to get safe area top inset
    private func getSafeAreaTop() -> CGFloat {
        if #available(iOS 15.0, *) {
            // For iOS 15 and newer
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            return windowScene?.windows.first?.safeAreaInsets.top ?? 0
        } else {
            // For older iOS versions
            return UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
        }
    }
    
    private func handleAction(_ action: NavBarMenuAction) {
        // Trigger haptic feedback
        HapticManager.shared.lightImpact()
        
        // Dismiss the menu
        withAnimation(.easeOut(duration: 0.2)) {
            isPresented = false
        }
        
        // Add a slight delay before executing action to allow menu to close
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onAction(action)
        }
    }
}

// Menu item button
struct MenuItemButton: View {
    let title: String
    let icon: Image
    let iconColor: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                icon
                    .color(iconColor)
                    .frame(width: 20, height: 20)
                    .padding(.trailing, 12)
                
                Text(title)
                    .font(Font.iosevkaBody())
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
} 
