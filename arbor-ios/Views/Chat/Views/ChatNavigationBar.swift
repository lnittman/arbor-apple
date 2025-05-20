import SwiftUI
import PhosphorSwift

struct ChatNavigationBar: View {
    let title: String = "arbor"
    let chatId: String?
    let messagesExist: Bool
    let isPrivate: Bool
    
    var onSidebarButtonTap: () -> Void
    var onMenuButtonTap: () -> Void
    var onPrivacyToggle: () -> Void
    var onNewChatButtonTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background with blur
            ZStack {
                // Blur effect for the glassy look
                BlurView(style: colorScheme == .dark ? .dark : .light)
                    .opacity(0.9)
                
                // Overlay with a slight tint matching the background color
                Theme.background(scheme: colorScheme)
                    .opacity(0.6)
            }
            .edgesIgnoringSafeArea(.top)
            
            // Navbar content
            VStack(spacing: 0) {
                HStack {
                    // Left sidebar button with list icon
                    Button {
                        onSidebarButtonTap()
                    } label: {
                        Ph.list.duotone
                            .color(Theme.foreground(scheme: colorScheme))
                            .frame(width: 20, height: 20)
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    // Center title - now a button to show the menu
                    Button {
                        onMenuButtonTap()
                    } label: {
                        Text(title)
                            .font(Font.iosevkaHeadline())
                            .foregroundColor(Theme.foreground(scheme: colorScheme))
                    }
                    
                    Spacer()
                    
                    // Right button container (fixed width to maintain layout)
                    ZStack(alignment: .center) {
                        // Eye toggle button when no messages
                        if !messagesExist {
                            Button {
                                onPrivacyToggle()
                            } label: {
                                Group {
                                    if isPrivate {
                                        Ph.eyeSlash.duotone
                                            .color(Theme.foreground(scheme: colorScheme))
                                            .frame(width: 20, height: 20)
                                    } else {
                                        Ph.eye.duotone
                                            .color(Theme.foreground(scheme: colorScheme))
                                            .frame(width: 20, height: 20)
                                    }
                                }
                            }
                            .transition(AnyTransition.opacity.combined(with: .scale(scale: 0.8)))
                        } 
                        
                        // New chat button (pencil) after chat has started
                        if messagesExist {
                            Button {
                                onNewChatButtonTap()
                            } label: {
                                Ph.notePencil.duotone
                                    .color(Theme.foreground(scheme: colorScheme))
                                    .frame(width: 20, height: 20)
                            }
                            .transition(AnyTransition.opacity.combined(with: .scale(scale: 0.8)))
                        }
                    }
                    // Add explicit animation modifier with slower duration
                    .animation(.easeInOut(duration: 0.5), value: messagesExist)
                    .frame(width: 20, height: 20) // Fixed size to maintain layout
                    .padding(.trailing, 16)
                }
                .frame(height: 53)
                .padding(.top, SafeAreaUtils.getSafeAreaTop()) // Use full safe area top inset
                
                // Bottom border - directly attached
                Rectangle()
                    .frame(height: 0.5) // Thinner border for a more subtle line
                    .foregroundColor(Theme.border(scheme: colorScheme))
                    .opacity(0.5)
            }
        }
        .frame(height: 44 + SafeAreaUtils.getSafeAreaTop())
    }
}

#Preview {
    ChatNavigationBar(
        chatId: "test-chat-id",
        messagesExist: true,
        isPrivate: false,
        onSidebarButtonTap: {},
        onMenuButtonTap: {},
        onPrivacyToggle: {},
        onNewChatButtonTap: {}
    )
} 
