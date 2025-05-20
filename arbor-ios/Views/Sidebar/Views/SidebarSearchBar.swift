import SwiftUI
import PhosphorSwift

struct SidebarSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    
    var body: some View {
        // Outer HStack to contain both search container and cancel button
        HStack(spacing: 8) {
            // Container with background - search input only
            HStack(spacing: 8) {
                // Search icon
                Ph.magnifyingGlass.duotone
                    .color(Theme.mutedForeground(scheme: colorScheme))
                    .frame(width: 16, height: 16)
                
                // Search text field
                TextField("search", text: $searchText)
                    .font(Font.iosevkaBody())
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
                    .focused($isFocused)
                    .onChange(of: isFocused) { _, newValue in
                        // If the field becomes focused, enter search mode
                        if newValue {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isSearching = true
                            }
                        }
                    }
                
                // Clear button when searching
                if !searchText.isEmpty && isSearching {
                    Button {
                        searchText = ""
                    } label: {
                        Ph.x.duotone
                            .color(Theme.mutedForeground(scheme: colorScheme))
                            .frame(width: 14, height: 14)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.card(scheme: colorScheme))
            )
            .animation(.easeInOut(duration: 0.25), value: searchText.isEmpty)
            
            // Exit search mode button when searching - outside the container
            if isSearching {
                Button {
                    isSearching = false
                    searchText = ""
                    isFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                } label: {
                    Text("cancel")
                        .font(Font.iosevkaFootnote())
                        .foregroundColor(Theme.accentColor(scheme: colorScheme))
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity) // Fade in/out rather than sliding
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
        .background(Theme.background(scheme: colorScheme))
        .animation(.easeInOut(duration: 0.25), value: isSearching) // Match SidebarView animation
    }
}

#Preview {
    SidebarSearchBar(searchText: .constant(""), isSearching: .constant(false))
} 
