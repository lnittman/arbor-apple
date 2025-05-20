import SwiftUI
import PhosphorSwift

// Chats Section Header
struct ChatsSectionHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var appViewModel: AppViewModel
    var onAdd: () -> Void // Closure for the add button action

    var body: some View {
        HStack {
            Text("chats")
                .font(Font.iosevkaSubheadline())
                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                .padding(.leading, 16) // Match the leading padding of list items

            Spacer()

            // Only show the + button if there are chats
            if !appViewModel.chats.isEmpty {
                Button {
                    onAdd() // Call the provided closure
                } label: {
                    Ph.plus.duotone
                        .color(Theme.mutedForeground(scheme: colorScheme))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.trailing, 16) // Consistent trailing padding
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 8) // Match the outer padding of chat rows
        .padding(.vertical, 12) // Add vertical padding for consistent spacing
        .animation(.easeInOut(duration: 0.2), value: appViewModel.chats.isEmpty)
    }
} 
