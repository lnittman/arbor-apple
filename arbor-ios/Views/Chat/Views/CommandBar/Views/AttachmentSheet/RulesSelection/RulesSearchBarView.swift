import SwiftUI

struct RulesSearchBarView: View {
    @Binding var searchText: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
            
            TextField("search rules", text: $searchText)
                .font(.body)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.card(scheme: colorScheme))
        )
        .padding(.horizontal)
    }
}

#Preview {
    RulesSearchBarView(searchText: .constant(""))
} 
