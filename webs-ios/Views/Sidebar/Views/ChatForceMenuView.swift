import SwiftUI
import PhosphorSwift

// Action types for the chat force menu
enum ChatMenuAction {
    case archive
    case rename
    case delete
}

// A wrapper view that handles long press gesture and shows the menu
struct ChatForceMenuTrigger<Content: View>: View {
    let chat: Chat
    let content: Content
    let onArchive: (Chat) -> Void
    let onRename: (Chat) -> Void
    let onDelete: (Chat) -> Void
    
    @State private var showMenu = false
    @State private var menuPosition: CGPoint = .zero
    @GestureState private var isLongPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        chat: Chat,
        @ViewBuilder content: () -> Content,
        onArchive: @escaping (Chat) -> Void,
        onRename: @escaping (Chat) -> Void,
        onDelete: @escaping (Chat) -> Void
    ) {
        self.chat = chat
        self.content = content()
        self.onArchive = onArchive
        self.onRename = onRename
        self.onDelete = onDelete
        print("🔍 ChatForceMenuTrigger initialized for chat: \(chat.id)")
    }
    
    var body: some View {
        ZStack {
            // The main content (chat row)
            content
                .scaleEffect(isLongPressed ? 0.96 : 1.0)
                .opacity(isLongPressed ? 0.7 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isLongPressed)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                print("🔍 Row size: \(geo.size), position: \(geo.frame(in: .global))")
                                menuPosition = CGPoint(
                                    x: UIScreen.main.bounds.width / 2,
                                    y: geo.frame(in: .global).midY
                                )
                            }
                    }
                )
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .updating($isLongPressed) { currentState, gestureState, _ in
                            gestureState = currentState
                        }
                        .onEnded { _ in
                            print("🔍 Long press detected")
                            
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                            generator.impactOccurred()
                            
                            // Show menu
                            withAnimation {
                                showMenu = true
                            }
                        }
                )
            
            // Fullscreen overlay with menu
            if showMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        print("🔍 Background tapped")
                        withAnimation {
                            showMenu = false
                        }
                    }
                    .transition(.opacity)
                
                // Menu
                VStack(spacing: 0) {
                    // Menu header
                    VStack(spacing: 8) {
                        Text(chat.title)
                            .font(Font.iosevkaBody())
                            .foregroundColor(Theme.foreground(scheme: colorScheme))
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        
                        Divider()
                            .background(Theme.border(scheme: colorScheme))
                    }
                    
                    // Menu actions
                    ForceMenuButton(
                        title: "archive chat",
                        icon: Ph.archive.duotone,
                        iconColor: .blue
                    ) {
                        handleDismiss {
                            onArchive(chat)
                        }
                    }
                    
                    Divider().background(Theme.border(scheme: colorScheme))
                    
                    ForceMenuButton(
                        title: "rename chat",
                        icon: Ph.pencilSimple.duotone,
                        iconColor: .orange
                    ) {
                        handleDismiss {
                            onRename(chat)
                        }
                    }
                    
                    Divider().background(Theme.border(scheme: colorScheme))
                    
                    ForceMenuButton(
                        title: "delete chat",
                        icon: Ph.trash.duotone,
                        iconColor: .red
                    ) {
                        handleDismiss {
                            onDelete(chat)
                        }
                    }
                }
                .frame(width: 250)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.card(scheme: colorScheme))
                        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 5)
                )
                .position(x: UIScreen.main.bounds.width / 2, y: menuPosition.y)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .onChange(of: showMenu) { oldValue, newValue in
            print("🔍 showMenu changed: \(oldValue) -> \(newValue)")
        }
    }
    
    private func handleDismiss(action: @escaping () -> Void) {
        print("🔍 Menu action triggered")
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Hide menu first with animation
        withAnimation {
            showMenu = false
        }
        
        // Execute the action after a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            action()
        }
    }
}

// Simple button for the force touch menu
struct ForceMenuButton: View {
    let title: String
    let icon: Image
    let iconColor: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon
                    .color(iconColor)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(Font.iosevkaBody())
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
} 
