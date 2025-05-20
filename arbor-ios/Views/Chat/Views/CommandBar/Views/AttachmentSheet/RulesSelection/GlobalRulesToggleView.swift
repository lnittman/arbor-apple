import SwiftUI

struct GlobalRulesToggleView: View {
    @Binding var includeGlobalRules: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Text("include global rules")
                .font(.headline)
                .foregroundColor(Theme.foreground(scheme: colorScheme))
            
            Spacer()
            
            Toggle("", isOn: $includeGlobalRules)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Theme.primary(scheme: colorScheme)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.card(scheme: colorScheme))
        )
        .padding(.horizontal)
    }
}

#Preview {
    GlobalRulesToggleView(includeGlobalRules: .constant(true))
} 
