import SwiftUI
import PhosphorSwift

struct PrivateMessageOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Ghost icon
            Ph.ghost.duotone
                .color(Theme.mutedForeground(scheme: colorScheme))
                .frame(width: 32, height: 32)
                .padding(.bottom, 4)
            
            // Temporary chat title
            Text("temporary chat")
                .font(Font.iosevkaBody())
                .foregroundColor(Theme.foreground(scheme: colorScheme))
                .padding(.bottom, 2)
            
            // Description text
            Text("this chat will not appear in history or create memories. for safety reasons, we may keep a copy of this chat for up to 30 days.")
                .font(Font.iosevkaCaption())
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                .padding(.horizontal, 40)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: -60) // Move upward for better visual centering
        .transition(.opacity)
    }
}

#Preview {
    PrivateMessageOverlay()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
} 
