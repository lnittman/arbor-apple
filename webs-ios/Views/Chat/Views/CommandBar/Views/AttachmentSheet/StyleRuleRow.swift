import SwiftUI
import PhosphorSwift

struct StyleRuleRow: View {
    let appliedRulesCount: Int
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                HStack(spacing: 10) {
                    PhosphorIcon.medium(Ph.notepad.duotone)
                    
                    Text("assign rules")
                        .font(Font.iosevkaBody())
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if appliedRulesCount > 0 {
                        Text("\(appliedRulesCount) applied")
                            .font(Font.iosevkaBody())
                            .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                    } else {
                        Text("none")
                            .font(Font.iosevkaBody())
                            .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                    }
                    
                    PhosphorIcon.small(Ph.caretRight.duotone, color: Theme.mutedForeground(scheme: colorScheme))
                }
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

#Preview {
    VStack(spacing: 16) {
        StyleRuleRow(appliedRulesCount: 0, action: {})
        StyleRuleRow(appliedRulesCount: 3, action: {})
    }
    .padding()
    .background(Color(.systemBackground))
} 
