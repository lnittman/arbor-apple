import SwiftUI
import PhosphorSwift
import Combine
import PhotosUI

struct NewProjectSheetView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @Binding var isPresented: Bool
    
    @State private var projectName: String = ""
    @FocusState private var isNameFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var selectedImage: UIImage?
    @State private var isKeyboardVisible = false
    
    // For PhotosPicker
    @State private var selectedItem: PhotosPickerItem?
    
    // Fixed vertical spacing
    private let topSpacing: CGFloat = 16
    private let headerHeight: CGFloat = 60
    private let contentSpacing: CGFloat = 24
    private let formContentHeight: CGFloat = 360  // Approximate height of form content
    
    var body: some View {
        GeometryReader { geometry in
            // Get the total height
            let totalHeight = geometry.size.height
            
            ZStack {
                // Background
                Theme.background(scheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with title and close button
                    ZStack {
                        Text("new project")
                            .font(Font.iosevkaHeadline())
                            .foregroundColor(Theme.foreground(scheme: colorScheme))
                            .frame(maxWidth: .infinity)
                        
                        HStack {
                            Spacer()
                            Button {
                                // Dismiss keyboard if showing
                                if isKeyboardVisible {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                                
                                // Small delay before dismissing sheet to ensure smooth animations
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    dismiss()
                                }
                            } label: {
                                Ph.x.duotone
                                    .color(Theme.mutedForeground(scheme: colorScheme))
                                    .frame(width: 20, height: 20)
                            }
                            .padding(.trailing, 16)
                        }
                    }
                    .frame(height: headerHeight)
                    .padding(.top, topSpacing)
                    
                    Spacer()
                }
                
                // Content container - positioned with vertical offset
                VStack(spacing: contentSpacing) {
                    // Avatar container with fixed size
                    HStack {
                        Spacer()
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(Theme.mutedBackground(scheme: colorScheme))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Group {
                                            if let selectedImage {
                                                Image(uiImage: selectedImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .clipShape(Circle())
                                            } else {
                                                Ph.folder.duotone
                                                    .color(Theme.mutedForeground(scheme: colorScheme))
                                                    .frame(width: 40, height: 40)
                                            }
                                        }
                                    )
                                
                                // Edit badge
                                Circle()
                                    .fill(Theme.accentColor(scheme: colorScheme))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Ph.pencilSimple.duotone
                                            .color(Color.white)
                                            .frame(width: 16, height: 16)
                                    )
                                    .offset(x: 4, y: 4)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    
                    // Form fields with fixed sizes and spacing
                    VStack(alignment: .leading, spacing: 16) {
                        // Text field with clear button
                        ZStack(alignment: .trailing) {
                            TextField("", text: $projectName)
                                .font(Font.iosevkaBody())
                                .foregroundColor(Theme.foreground(scheme: colorScheme))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.mutedBackground(scheme: colorScheme))
                                )
                                .overlay(
                                    HStack {
                                        Text("project name")
                                            .font(Font.iosevkaBody())
                                            .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                                            .opacity(projectName.isEmpty ? 1 : 0)
                                            .padding(.leading, 12)
                                        Spacer()
                                    }
                                )
                                .focused($isNameFieldFocused)
                            
                            // Clear button
                            if !projectName.isEmpty {
                                Button {
                                    projectName = ""
                                } label: {
                                    Ph.x.duotone
                                        .color(Theme.mutedForeground(scheme: colorScheme))
                                        .frame(width: 14, height: 14)
                                }
                                .padding(.trailing, 12)
                                .transition(.opacity)
                            }
                        }
                        
                        // Description text - left aligned 
                        Text("projects keep chats, files, and custom instructions in one place. use them for ongoing work, or just to keep things tidy.")
                            .font(Font.iosevkaCaption())
                            .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                            .multilineTextAlignment(.leading)
                        
                        // Create project button - positioned under subtitle
                        Button {
                            createProject()
                        } label: {
                            Text("create project")
                                .font(Font.iosevkaBody())
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.primary(scheme: colorScheme))
                                        .opacity(projectName.isEmpty ? 0.5 : 1.0)
                                )
                        }
                        .disabled(projectName.isEmpty)
                        .padding(.top, 24)
                    }
                    .padding(.horizontal, 32)
                }
                .frame(width: geometry.size.width)
                .frame(height: formContentHeight)
                // Calculate the vertical offset based on keyboard visibility
                .offset(y: calculateVerticalOffset(totalHeight: totalHeight))
            }
        }
        .onAppear {
            // Start keyboard observers
            setupKeyboardObservers()
            
            // Focus the name field immediately when the sheet appears
            isNameFieldFocused = true
        }
        // Use animation modifier with spring animation for smooth keyboard transitions
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isKeyboardVisible)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: keyboardHeight)
        .animation(.easeInOut(duration: 0.2), value: projectName)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
    
    // Calculate the vertical offset for content positioning
    private func calculateVerticalOffset(totalHeight: CGFloat) -> CGFloat {
        let headerOffset = headerHeight + topSpacing
        
        if isKeyboardVisible {
            // When keyboard is visible, position content to be centered in remaining space
            let visibleAreaHeight = totalHeight - keyboardHeight - headerOffset
            return (visibleAreaHeight / 2) - (formContentHeight / 2) + headerOffset
        } else {
            // When no keyboard, center in sheet minus header space
            return (totalHeight / 2) - (formContentHeight / 2)
        }
    }
    
    private func createProject() {
        let name = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !name.isEmpty {
            // Convert the selected image to Data if available
            let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
            
            appViewModel.createNewProject(
                name: name,
                description: nil,
                imageData: imageData
            )
            
            isPresented = false
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                // Get animation curve and duration from the notification
                let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
                let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
                
                // Create a matching animation
                let animation = Animation.timingCurve(0.2, 0.8, 0.2, 1.0, duration: duration)
                
                // Animate with the keyboard's timing
                withAnimation(animation) {
                    keyboardHeight = keyboardFrame.height
                    isKeyboardVisible = true
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { notification in
            // Get animation curve and duration from the notification
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
            
            // Create a matching animation
            let animation = Animation.timingCurve(0.2, 0.8, 0.2, 1.0, duration: duration)
            
            // Animate with the keyboard's timing
            withAnimation(animation) {
                keyboardHeight = 0
                isKeyboardVisible = false
            }
        }
    }
}

#Preview {
    NewProjectSheetView(isPresented: .constant(true))
        .environmentObject(AppViewModel())
} 
