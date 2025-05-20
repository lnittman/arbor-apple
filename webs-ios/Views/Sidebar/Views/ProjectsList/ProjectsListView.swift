import SwiftUI
import PhosphorSwift

struct ProjectsList: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Binding var isShowing: Bool
    @Binding var searchText: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var showNewProjectSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Section header
            ProjectsSectionHeaderView()
            
            if !appViewModel.projects.isEmpty {
                // Projects list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(filteredProjects) { project in
                            ProjectRowView(project: project, isShowing: $isShowing)
                        }
                    }
                    .padding(.top, 12)
                }
            } else {
                // Empty state with new project button
                VStack(spacing: 16) {
                    // New project button
                    Button {
                        showNewProjectSheet = true
                    } label: {
                        HStack {
                            Ph.folderPlus.duotone
                                .color(Theme.mutedForeground(scheme: colorScheme))
                                .frame(width: 20, height: 20)
                            
                            Text("new project")
                                .font(Font.iosevkaBody())
                                .foregroundColor(Theme.primaryForeground(scheme: colorScheme))
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 8)
                    .padding(.top, 12)
                }
                .padding(.bottom, 16)
                .sheet(isPresented: $showNewProjectSheet) {
                    NewProjectSheetView(isPresented: $showNewProjectSheet)
                }
            }
        }
    }
    
    // Filter projects based on search text if provided
    private var filteredProjects: [Project] {
        if searchText.isEmpty {
            return appViewModel.projects
        } else {
            return appViewModel.projects.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

#Preview {
    ProjectsList(isShowing: .constant(true), searchText: .constant(""))
        .environmentObject(AppViewModel())
} 
