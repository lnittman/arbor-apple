import SwiftUI
import PhosphorSwift

struct RulesHeaderView: View {
    @Binding var isShowing: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isShowing = false
                }
            } label: {
                HStack(spacing: 6) {
                    PhosphorIcon.medium(Ph.caretLeft.duotone)
                    Text("back")
                        .font(.headline)
                }
                .foregroundColor(Theme.primary(scheme: colorScheme))
            }
            
            Spacer()
            
            Text("assign rules")
                .font(.headline)
                .foregroundColor(Theme.foreground(scheme: colorScheme))
            
            Spacer()
            
            // Empty view for symmetry (same width as back button)
            HStack(spacing: 6) {
                PhosphorIcon.medium(Ph.caretLeft.duotone)
                Text("back")
                    .font(.headline)
            }
            .opacity(0)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

#Preview {
    RulesHeaderView(isShowing: .constant(true))
} 
