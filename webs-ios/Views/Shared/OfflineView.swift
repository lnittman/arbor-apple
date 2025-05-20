import SwiftUI
import PhosphorSwift

/// A view displayed when the app is offline
struct OfflineView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Ph.wifiSlash.duotone
                .color(Theme.mutedForeground(scheme: colorScheme))
                .frame(width: 56, height: 56)
            
            Text("the internet connection appears to be offline")
                .font(Font.iosevkaBody())
                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            
            // Retry button
            Button(action: {
                HapticManager.shared.lightImpact()
                onRetry()
            }) {
                HStack {
                    Ph.arrowClockwise.duotone
                        .color(colorScheme == .dark ? .white : .black)
                        .frame(width: 20, height: 20)
                    
                    Text("retry")
                        .font(Font.iosevkaBody())
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .frame(width: 200)
                .padding(.vertical, 16)
                .background(colorScheme == .dark ? Color(hex: "202123") : .white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OfflineView(onRetry: {})
} 
