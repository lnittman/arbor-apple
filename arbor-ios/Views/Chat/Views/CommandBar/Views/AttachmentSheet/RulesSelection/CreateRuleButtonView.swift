import SwiftUI
import PhosphorSwift

struct CreateRuleButtonView: View {
    var onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                PhosphorIcon.small(Ph.plus.duotone)
                Text("create new rule")
                    .fontWeight(.medium)
            }
            .foregroundColor(Theme.primary(scheme: colorScheme))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.primary(scheme: colorScheme), lineWidth: 1.5)
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
}

#Preview {
    CreateRuleButtonView(onTap: {})
} 
