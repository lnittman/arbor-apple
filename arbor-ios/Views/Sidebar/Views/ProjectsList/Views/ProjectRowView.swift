import SwiftUI
import PhosphorSwift

// Individual project row
struct ProjectRowView: View {
    var project: Project
    @Binding var isShowing: Bool
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isSelected: Bool = false
    @State private var showSelectionAnimation: Bool = false
    
    var body: some View {
        Button(action: {
            // Set the selection state immediately
            showSelectionAnimation = true
            
            // Clear any current chat selection first (will trigger fade out on chat items)
            if appViewModel.currentChatId != nil {
                appViewModel.currentChatId = nil
            }
            
            // Load the project (will trigger selection change notifications)
            appViewModel.loadProject(projectId: project.id)
            
            // Close the sidebar after a very short delay to allow the selection animation to be visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation {
                    isShowing = false
                }
            }
        }) {
            HStack {
                // Project icon or image
                if let projectImage = project.image {
                    Image(uiImage: projectImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                } else {
                    Ph.folder.duotone
                        .color(Theme.mutedForeground(scheme: colorScheme))
                        .frame(width: 20, height: 20)
                }
                
                // Project name
                Text(project.name)
                    .font(Font.iosevkaBody())
                    .foregroundColor(Theme.primaryForeground(scheme: colorScheme))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.leading, 8)
                
                Spacer()
            }
            .padding(.vertical, 10) // Match chat row height
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .background(
                Group {
                    if isSelected || showSelectionAnimation {
                        Theme.mutedBackground(scheme: colorScheme).cornerRadius(8)
                            .transition(.opacity)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8) // This creates space for the active highlight
        .onChange(of: showSelectionAnimation) { _, newValue in
            if newValue {
                // Very short animation for the selection highlight
                withAnimation(.easeIn(duration: 0.15)) {
                    isSelected = true
                }
            }
        }
        .onAppear {
            // Only set selection state without animation on appear
            isSelected = appViewModel.currentProject?.id == project.id && appViewModel.currentChatId == nil
        }
        .onChange(of: appViewModel.currentProject?.id) { _, _ in
            // Update selection state with animation when current project changes
            withAnimation(.easeInOut(duration: 0.15)) {
                isSelected = appViewModel.currentProject?.id == project.id && appViewModel.currentChatId == nil
            }
        }
        .onChange(of: appViewModel.currentChatId) { _, _ in
            // Update selection state with animation when current chat changes
            withAnimation(.easeInOut(duration: 0.15)) {
                isSelected = appViewModel.currentProject?.id == project.id && appViewModel.currentChatId == nil
            }
        }
    }
} 
