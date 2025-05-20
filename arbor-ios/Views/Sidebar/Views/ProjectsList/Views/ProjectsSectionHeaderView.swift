import SwiftUI
import PhosphorSwift

// Projects Section Header
struct ProjectsSectionHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showNewProjectSheet = false
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        HStack {
            Text("projects")
                .font(Font.iosevkaSubheadline())
                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                .padding(.leading, 16)
            
            Spacer()
            
            // Only show the + button if there are projects
            if !appViewModel.projects.isEmpty {
                Button {
                    showNewProjectSheet = true
                } label: {
                    Ph.plus.duotone
                        .color(Theme.mutedForeground(scheme: colorScheme))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.trailing, 16)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .sheet(isPresented: $showNewProjectSheet) {
            NewProjectSheetView(isPresented: $showNewProjectSheet)
        }
        .animation(.easeInOut(duration: 0.2), value: appViewModel.projects.isEmpty)
    }
} 
