import SwiftUI
import PhosphorSwift

struct AttachmentOptionButtonView: View {
    let icon: Image
    let label: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                PhosphorIcon.large(icon)
                
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
            }
            .frame(width: 90, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.card(scheme: colorScheme))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
