import SwiftUI

struct RuleRowView: View {
    @Binding var rule: Rule
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button {
            rule.isSelected.toggle()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.name)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                    
                    Text(rule.description)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                }
                
                Spacer()
                
                Image(systemName: rule.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(rule.isSelected ? Theme.primary(scheme: colorScheme) : Theme.mutedForeground(scheme: colorScheme))
                    .font(.system(size: 20))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.card(scheme: colorScheme))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RuleRowView(rule: .constant(Rule(name: "Test Rule", description: "This is a test rule")))
} 
