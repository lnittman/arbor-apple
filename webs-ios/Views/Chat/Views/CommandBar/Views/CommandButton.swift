import SwiftUI
import PhosphorSwift

struct CommandButton: View {
    let icon: Image
    let label: String
    let isActive: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                PhosphorIcon.small(
                    icon,
                    color: isActive ? Theme.primary(scheme: colorScheme) : Theme.mutedForeground(scheme: colorScheme)
                )
                
                Text(label)
                    .font(Font.iosevkaSubheadline())
            }
            .foregroundColor(isActive ? Theme.primary(scheme: colorScheme) : Theme.mutedForeground(scheme: colorScheme))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isActive ? Theme.primary(scheme: colorScheme).opacity(0.15) : Theme.card(scheme: colorScheme))
                    .overlay(
                        Capsule()
                            .stroke(isActive ? Theme.primary(scheme: colorScheme).opacity(0.5) : Theme.border(scheme: colorScheme), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct CircleIconButton: View {
    let icon: Image
    let action: () -> Void
    var color: Color? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            PhosphorIcon.medium(icon, color: color ?? Theme.mutedForeground(scheme: colorScheme))
                .padding(6)
        }
        .background(
            Circle()
                .stroke(Theme.border(scheme: colorScheme), lineWidth: 1)
                .background(
                    Circle()
                        .fill(Theme.card(scheme: colorScheme))
                )
        )
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SendButton: View {
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: isEnabled ? .white : Theme.mutedForeground(scheme: colorScheme)))
                } else {
                    PhosphorIcon.small(Ph.arrowUp.duotone, color: isEnabled ? .white : Theme.mutedForeground(scheme: colorScheme))
                }
            }
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(isEnabled ? Theme.primary(scheme: colorScheme) : Color.clear)
            )
            .overlay(
                Circle()
                    .stroke(isEnabled ? Color.clear : Theme.border(scheme: colorScheme), lineWidth: 1)
            )
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(ScaleButtonStyle())
        .animation(.easeInOut(duration: 0.25), value: isEnabled)
        .animation(.easeInOut(duration: 0.25), value: isLoading)
    }
}

#Preview {
    HStack(spacing: 20) {
        CircleIconButton(icon: Ph.plus.duotone, action: {})
        
        CommandButton(
            icon: Ph.arrowsClockwise.duotone,
            label: "spin",
            isActive: true,
            action: {}
        )
        
        CommandButton(
            icon: Ph.lightbulb.duotone,
            label: "think",
            isActive: false,
            action: {}
        )
        
        SendButton(isEnabled: true, isLoading: false, action: {})
    }
    .padding()
    .background(Color(.systemBackground))
} 
