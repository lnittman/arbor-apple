import SwiftUI
import PhosphorSwift

struct ToastView: View {
    let message: String
    let icon: Image
    let iconColor: Color
    @Binding var isShowing: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    init(message: String, 
         icon: Image = Ph.checkCircle.fill, 
         iconColor: Color? = nil, 
         isShowing: Binding<Bool>) {
        self.message = message
        self.icon = icon
        self.iconColor = iconColor ?? Theme.primary(scheme: .dark)
        self._isShowing = isShowing
    }
    
    var body: some View {
        // Full-width toast with rounded corners
        HStack(spacing: 12) {
            // Icon
            icon
                .color(iconColor)
                .frame(width: 20, height: 20)
            
            // Message
            Text(message)
                .font(Font.iosevkaBody())
                .foregroundColor(Theme.foreground(scheme: colorScheme))
                .lineLimit(1)
            
            Spacer()
            
            // Dismiss button
            Button {
                // Trigger haptic feedback first
                provideHapticFeedback()
                
                // Then dismiss the toast after a tiny delay to ensure the haptic is felt
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // Update the binding, animation is handled by the parent view
                    isShowing = false
                }
            } label: {
                Ph.x.duotone
                    .color(Theme.mutedForeground(scheme: colorScheme))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle()) // Improves tap target
                    .padding(4) // Add padding to make button easier to tap
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16) // Increased vertical padding
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.card(scheme: colorScheme))
                .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
        )
        .padding(.horizontal, 16) // Add some padding from edges of screen
    }
    
    // Haptic feedback
    private func provideHapticFeedback() {
        // Use the centralized HapticManager instead of direct implementation
        HapticManager.shared.mediumImpact()
    }
}

// Predefined toast types for common use cases
extension ToastView {
    static func success(message: String, isShowing: Binding<Bool>) -> ToastView {
        ToastView(
            message: message,
            icon: Ph.checkCircle.fill,
            iconColor: Color.green,
            isShowing: isShowing
        )
    }
    
    static func info(message: String, isShowing: Binding<Bool>) -> ToastView {
        ToastView(
            message: message,
            icon: Ph.info.fill,
            iconColor: Color(.systemBlue),
            isShowing: isShowing
        )
    }
    
    static func warning(message: String, isShowing: Binding<Bool>) -> ToastView {
        ToastView(
            message: message,
            icon: Ph.warning.fill,
            iconColor: Color.orange,
            isShowing: isShowing
        )
    }
    
    static func error(message: String, isShowing: Binding<Bool>) -> ToastView {
        ToastView(
            message: message,
            icon: Ph.x.fill,
            iconColor: Color.red,
            isShowing: isShowing
        )
    }
    
    static func loggedOut(isShowing: Binding<Bool>) -> ToastView {
        ToastView(
            message: "logged out",
            icon: Ph.signOut.fill,
            iconColor: Color(.systemBlue),
            isShowing: isShowing
        )
    }
    
    static func copied(isShowing: Binding<Bool>) -> ToastView {
        ToastView(
            message: "copied to clipboard",
            icon: Ph.copySimple.fill,
            iconColor: Color(.systemBlue),
            isShowing: isShowing
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ToastView.success(message: "successfully saved", isShowing: .constant(true))
        ToastView.info(message: "copied to clipboard", isShowing: .constant(true))
        ToastView.warning(message: "connection lost", isShowing: .constant(true))
        ToastView.error(message: "failed to send", isShowing: .constant(true))
        ToastView.loggedOut(isShowing: .constant(true))
    }
    .padding()
    .background(Color(.systemBackground))
} 
