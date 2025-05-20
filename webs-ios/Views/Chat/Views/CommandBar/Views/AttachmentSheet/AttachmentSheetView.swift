import SwiftUI
import PhosphorSwift

struct AttachmentSheetView: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var showRulesSelection = false
    @State private var appliedRulesCount = 0
    @State private var showProjectsSelection = false
    
    var body: some View {
        ZStack {
            // Background to match chat view
            Theme.background(scheme: colorScheme)
                .ignoresSafeArea()
                
            // Main attachment options view
            mainAttachmentView
                .offset(x: showRulesSelection ? -UIScreen.main.bounds.width : 0)
                .offset(x: showProjectsSelection ? -UIScreen.main.bounds.width : 0)
                .animation(.spring(response: 0.3), value: showRulesSelection)
                .animation(.spring(response: 0.3), value: showProjectsSelection)
            
            // Rules selection view sliding in from right
            if showRulesSelection {
                GeometryReader { geometry in
                    RulesSelectionView(isShowing: $showRulesSelection)
                        .background(Theme.background(scheme: colorScheme))
                        .offset(x: 0)
                        .frame(width: geometry.size.width)
                }
                .transition(.move(edge: .trailing))
                .onChange(of: showRulesSelection) { oldValue, newValue in
                    if !newValue {
                        // Update the applied rules count when returning from rules view
                        // This is just a placeholder - in a real app this would come from your rules data
                        appliedRulesCount = Int.random(in: 0...3)
                    }
                }
                .presentationDragIndicator(.hidden)
            }
            
            // Projects selection view sliding in from right
            if showProjectsSelection {
                GeometryReader { geometry in
                    ProjectsSelectionView(isShowing: $showProjectsSelection)
                        .background(Theme.background(scheme: colorScheme))
                        .offset(x: 0)
                        .frame(width: geometry.size.width)
                }
                .transition(.move(edge: .trailing))
                .presentationDragIndicator(.hidden)
            }
        }
        .animation(.spring(response: 0.3), value: showRulesSelection)
        .animation(.spring(response: 0.3), value: showProjectsSelection)
        .background(Theme.background(scheme: colorScheme))
    }
    
    private var mainAttachmentView: some View {
        VStack(spacing: 20) {
            // Top row - 3 main attachment options as horizontal rectangles
            HStack(spacing: 12) {
                // Camera Button
                AttachmentHorizontalButton(
                    icon: Ph.camera.duotone,
                    label: "camera"
                ) {
                    isPresented = false
                }
                
                // Photos Button
                AttachmentHorizontalButton(
                    icon: Ph.images.duotone,
                    label: "photos"
                ) {
                    isPresented = false
                }
                
                // Files Button
                AttachmentHorizontalButton(
                    icon: Ph.fileArrowUp.duotone,
                    label: "files"
                ) {
                    isPresented = false
                }
            }
            .frame(height: 56)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            // Additional options (similar to Claude)
            VStack(spacing: 16) {
                // Assign rules option (formerly "Choose style")
                StyleRuleRow(appliedRulesCount: appliedRulesCount) {
                    withAnimation(.spring(response: 0.3)) {
                        showRulesSelection = true
                    }
                }
                
                
                // Manage tools option
                SettingsOptionRowView(
                    icon: Ph.gear.duotone,
                    title: "manage tools",
                    trailingContent: {
                        ChevronLabelView(label: "2 enabled")
                    }
                )

                // Project selection option (replacing "use extended thinking")
                SettingsOptionRowView(
                    icon: Ph.folder.duotone,
                    title: "project",
                    trailingContent: {
                        ChevronLabelView(label: "none")
                    },
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            showProjectsSelection = true
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
        }
    }
}

// Projects selection view
struct ProjectsSelectionView: View {
    @Binding var isShowing: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with back button
            HStack {
                Button {
                    withAnimation {
                        isShowing = false
                    }
                } label: {
                    Ph.caretLeft.duotone
                        .color(Theme.mutedForeground(scheme: colorScheme))
                        .frame(width: 24, height: 24)
                }
                
                Spacer()
                
                Text("select project")
                    .font(Font.iosevkaHeadline())
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
                
                Spacer()
                
                // Spacer for the right side to center the title
                Ph.caretLeft.duotone
                    .opacity(0)
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Empty state for projects list
            Spacer()
            
            VStack(spacing: 12) {
                Ph.folder.duotone
                    .color(Theme.mutedForeground(scheme: colorScheme))
                    .frame(width: 40, height: 40)
                
                Text("no projects yet")
                    .font(Font.iosevkaBody())
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
                
                Text("projects keep your chats and files organized")
                    .font(Font.iosevkaCaption())
                    .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Create project button
            Button {
                // Action to create a new project
            } label: {
                Text("create project")
                    .font(Font.iosevkaBody())
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 100)
                            .fill(Theme.primary(scheme: colorScheme))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Theme.background(scheme: colorScheme))
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

