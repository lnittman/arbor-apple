import SwiftUI
import PhosphorSwift

// Empty Projects View
struct EmptyProjectsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Text("no projects yet...")
                .font(Font.iosevkaBody())
                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity)
    }
} 
