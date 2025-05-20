import SwiftUI
import PhosphorSwift

struct TypingIndicatorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var blinkOpacity = 1.0
    @State private var isBlinking = false
    @State private var isActive = false
    
    var isProcessing: Bool = true  // Default to true
    var isWaiting: Bool = false    // Waiting between chunks or for tool calls
    
    var body: some View {
        HStack(spacing: 8) {
            // Phosphor human icon that blinks during processing
            Ph.user.duotone
                .color(Theme.primary(scheme: colorScheme))
                .frame(width: 18, height: 18)
                .opacity(isWaiting ? blinkOpacity : 1.0)
            
            // Typing dots animation (optional - can be shown alongside the icon)
            if isProcessing {
                TypingDotsView()
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.card(scheme: colorScheme).opacity(0.7))
        )
        .transition(.opacity)
        .onAppear {
            isActive = true
            startBlinkingEffect()
        }
        .onDisappear {
            isActive = false
        }
        .onChange(of: isWaiting) { _, newValue in
            if newValue {
                startBlinkingEffect()
            } else {
                // Reset to full opacity when not waiting
                blinkOpacity = 1.0
            }
        }
    }
    
    private func startBlinkingEffect() {
        guard isActive && isWaiting else { return }
        
        // Use a repeating animation for the blinking effect
        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            blinkOpacity = 0.4
        }
    }
}

// Separated the dots animation into its own component
struct TypingDotsView: View {
    @State private var showDot1 = false
    @State private var showDot2 = false
    @State private var showDot3 = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .frame(width: 6, height: 6)
                .opacity(showDot1 ? 0.4 : 0.8)
            Circle()
                .frame(width: 6, height: 6)
                .opacity(showDot2 ? 0.4 : 0.8)
            Circle()
                .frame(width: 6, height: 6)
                .opacity(showDot3 ? 0.4 : 0.8)
        }
        .foregroundColor(Color.gray)
        .onAppear {
            startDotsAnimation()
        }
    }
    
    private func startDotsAnimation() {
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) {
            self.showDot1 = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) {
                self.showDot2 = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) {
                self.showDot3 = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TypingIndicatorView(isProcessing: true, isWaiting: false)
            .padding()
            .previewDisplayName("Processing")
        
        TypingIndicatorView(isProcessing: true, isWaiting: true)
            .padding()
            .previewDisplayName("Waiting")
    }
    .background(Color(.systemBackground))
} 
