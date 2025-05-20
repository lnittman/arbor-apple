import SwiftUI

struct EmptyRulesView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Text("no rules found")
            .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
            .padding()
    }
}

#Preview {
    EmptyRulesView()
} 
