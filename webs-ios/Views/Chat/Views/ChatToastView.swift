import SwiftUI
import PhosphorSwift

struct ChatToastView: View {
    let toastMessage: String
    let isVisible: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if isVisible {
            VStack {
                // Position toast below the navbar with a bit of extra padding
                Spacer().frame(height: 44 + SafeAreaUtils.getSafeAreaTop() + 10)
                
                // Toast content
                HStack(spacing: 8) {
                    Ph.checkCircle.fill
                        .color(Theme.primary(scheme: colorScheme))
                        .frame(width: 16, height: 16)
                    
                    Text(toastMessage)
                        .font(Font.iosevkaCaption())
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                        .padding(.trailing, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Theme.card(scheme: colorScheme))
                        .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
                )
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                
                Spacer()
            }
            .transition(.opacity)
            .zIndex(100) // Ensure toast appears above everything
        }
    }
}

#Preview {
    ChatToastView(toastMessage: "Message copied to clipboard", isVisible: true)
} 
