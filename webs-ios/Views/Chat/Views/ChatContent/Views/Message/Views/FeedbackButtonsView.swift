import SwiftUI
import PhosphorSwift

struct FeedbackButtonsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var copied = false
    
    var onCopy: () -> Void
    var onThumbsUp: () -> Void
    var onThumbsDown: () -> Void
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Copy Button
            Button {
                triggerHaptic()
                onCopy()
                withAnimation(.easeInOut(duration: 0.2)) {
                    copied = true
                }
                // Reset copy animation after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        copied = false
                    }
                }
            } label: {
                if copied {
                    PhosphorIcon.small(Ph.check.duotone, color: Theme.primary(scheme: colorScheme))
                        .transition(.opacity.combined(with: .scale))
                } else {
                    PhosphorIcon.small(Ph.copy.duotone, color: Theme.mutedForeground(scheme: colorScheme))
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(6)
            .background(Theme.card(scheme: colorScheme).opacity(0.8))
            .clipShape(Circle())
            
            // Thumbs Up Button - always shown
            Button {
                triggerHaptic()
                onThumbsUp()
                // No animation to hide buttons
            } label: {
                PhosphorIcon.small(Ph.thumbsUp.duotone, color: Theme.mutedForeground(scheme: colorScheme))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(6)
            .background(Theme.card(scheme: colorScheme).opacity(0.8))
            .clipShape(Circle())
            
            // Thumbs Down Button - always shown
            Button {
                triggerHaptic()
                onThumbsDown()
                // No animation to hide buttons
            } label: {
                PhosphorIcon.small(Ph.thumbsDown.duotone, color: Theme.mutedForeground(scheme: colorScheme))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(6)
            .background(Theme.card(scheme: colorScheme).opacity(0.8))
            .clipShape(Circle())
            
            Spacer() // Align buttons to the left
        }
        .padding(.leading, 8)
        .padding(.top, 6)
    }
}

#Preview {
    FeedbackButtonsView(onCopy: {}, onThumbsUp: {}, onThumbsDown: {})
        .padding()
        .background(Color.gray.opacity(0.2))
} 
