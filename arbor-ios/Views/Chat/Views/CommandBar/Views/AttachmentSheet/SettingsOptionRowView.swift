import SwiftUI
import PhosphorSwift

struct SettingsOptionRowView<TrailingContent: View>: View {
    let icon: Image
    let title: String
    let trailingContent: TrailingContent
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        icon: Image,
        title: String,
        @ViewBuilder trailingContent: () -> TrailingContent,
        action: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.title = title
        self.trailingContent = trailingContent()
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Leading icon and title
                HStack(spacing: 10) {
                    PhosphorIcon.medium(icon)
                    
                    Text(title)
                        .font(Font.iosevkaBody())
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                }
                
                Spacer()
                
                // Trailing content (passed in)
                trailingContent
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.card(scheme: colorScheme))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Common trailing views
struct ChevronLabelView: View {
    let label: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(Font.iosevkaBody())
                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
            
            PhosphorIcon.small(Ph.caretRight.duotone, color: Theme.mutedForeground(scheme: colorScheme))
        }
    }
}

struct ProToggleView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Text("PRO")
                .font(Font.iosevkaCaption())
                .fontWeight(.bold)
                .foregroundColor(Theme.primary(scheme: colorScheme))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.primary(scheme: colorScheme).opacity(0.2))
                )
            
            Circle()
                .fill(Theme.card(scheme: colorScheme))
                .frame(width: 24, height: 24)
                .overlay(
                    Capsule()
                        .stroke(Theme.mutedForeground(scheme: colorScheme), lineWidth: 1)
                )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // Style option
        SettingsOptionRowView(
            icon: Ph.paintBrush.duotone,
            title: "choose style"
        ) {
            ChevronLabelView(label: "Normal")
        }
        
        // Pro feature
        SettingsOptionRowView(
            icon: Ph.brain.duotone,
            title: "use extended thinking"
        ) {
            ProToggleView()
        }
        
        // Manage tools
        SettingsOptionRowView(
            icon: Ph.gear.duotone,
            title: "manage tools"
        ) {
            ChevronLabelView(label: "2 enabled")
        }
    }
    .padding()
    .background(Color(.systemBackground))
} 
