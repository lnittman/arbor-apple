import SwiftUI
import PhosphorSwift

struct CommandBarView: View {
    @Binding var text: String
    @Binding var mode: ChatMessage.AgentMode
    @Binding var isLoading: Bool
    @Binding var commandBarFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    var onSubmit: () -> Void
    
    @FocusState private var isInputFocused: Bool
    @State private var spinActive = false
    @State private var thinkActive = false
    @State private var showAttachmentSheet = false
    @State private var wasKeyboardOpen = false // Track if keyboard was open before showing sheet
    @State private var textHeight: CGFloat = 40 // Default height for single line
    
    var body: some View {
        VStack(spacing: 0) {
            // Command bar sheet
            commandBarSheet
        }
        .onTapGesture {
            isInputFocused = true
        }
        .onAppear {
            print("📋 CommandBarView: onAppear called, commandBarFocused = \(commandBarFocused)")
            updateUIFromMode()
            
            // Let ChatContentContainer handle the focusing
        }
        .onChange(of: mode) { oldValue, newValue in
            updateUIFromMode()
        }
        // Sync FocusState with external binding
        .onChange(of: commandBarFocused) { oldValue, newValue in
            print("📋 CommandBarView: commandBarFocused changed from \(oldValue) to \(newValue)")
            if isInputFocused != newValue {
                print("📋 CommandBarView: Updating isInputFocused to \(newValue)")
                isInputFocused = newValue
                
                // If we're setting focus to true, also use UIKit-level focus request
                if newValue {
                    print("📋 CommandBarView: Using UIKit to request keyboard")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        // Force the keyboard to appear using UIKit
                        let keyWindow = UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .flatMap { $0.windows }
                            .first { $0.isKeyWindow }
                        
                        keyWindow?.endEditing(false) // End any existing editing
                        keyWindow?.subviews.first?.becomeFirstResponder() // Try to force a responder
                        isInputFocused = true // And set SwiftUI focus state again
                    }
                }
            } else {
                print("📋 CommandBarView: isInputFocused already matches commandBarFocused (\(newValue))")
            }
        }
        .onChange(of: isInputFocused) { oldValue, newValue in
            print("📋 CommandBarView: isInputFocused changed from \(oldValue) to \(newValue)")
            if commandBarFocused != newValue {
                print("📋 CommandBarView: Updating commandBarFocused to \(newValue)")
                commandBarFocused = newValue
            } else {
                print("📋 CommandBarView: commandBarFocused already matches isInputFocused (\(newValue))")
            }
        }
        .sheet(isPresented: $showAttachmentSheet, onDismiss: {
            // When sheet is dismissed, restore keyboard if it was open before
            if wasKeyboardOpen {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isInputFocused = true
                }
            }
        }) {
            AttachmentSheetView(isPresented: $showAttachmentSheet)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(false)
                .background(Theme.background(scheme: colorScheme))
        }
    }
    
    // Main command bar sheet
    private var commandBarSheet: some View {
        VStack(spacing: 0) {
            // Text input area - expanding TextEditor with no top padding
            textInputArea
            
            // Add a subtle divider above the button row
            Divider()
                .background(Theme.border(scheme: colorScheme))
                .opacity(0.3)
            
            // Bottom controls row in a fixed-height container
            ZStack {
                Theme.card(scheme: colorScheme) // Use card color
                    .frame(height: 56) // Fixed height for button area
                
                // Button row
                commandButtons
                    .padding(.horizontal, 12)
            }
            .frame(height: 56) // Fix button row height
        }
        .background(Theme.card(scheme: colorScheme)) // Use card color
        .cornerRadius(20, corners: [.topLeft, .topRight]) // Rounded only on top
        .padding(.horizontal, 0)
        // Properly account for safe area
        .padding(.bottom, getSafeAreaBottom())
        .animation(.easeInOut(duration: 0.2), value: textHeight) // Animate height changes
    }
    
    // Expanding text input area
    private var textInputArea: some View {
        TextEditor(text: $text)
            .font(Font.iosevkaBody())
            .focused($isInputFocused)
            .frame(height: max(40, textHeight))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .padding(.top, 0) // Ensure no top padding
            .background(Color.clear)
            .disabled(isLoading)
            .onChange(of: isInputFocused) { oldValue, newValue in
                print("📋 CommandBarView TextEditor: isInputFocused changed from \(oldValue) to \(newValue)")
                if newValue {
                    // If focus state is true, ensure keyboard appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .onChange(of: text) { oldValue, newValue in
                // Calculate height based on text content
                let lineCount = max(1, newValue.components(separatedBy: "\n").count)
                let baseHeight: CGFloat = 20 // Base height for font
                let padding: CGFloat = 20 // Total vertical padding
                textHeight = CGFloat(lineCount) * baseHeight + padding
                
                // Limit to reasonable height
                textHeight = min(textHeight, 120)
            }
            .scrollContentBackground(.hidden) // Hide default TextEditor background
            .foregroundStyle(Theme.foreground(scheme: colorScheme))
            .overlay(
                // Placeholder overlay positioned to match default cursor behavior
                Group {
                    if text.isEmpty {
                        Text("ask anything")
                            .font(Font.iosevkaBody())
                            .foregroundStyle(Theme.mutedForeground(scheme: colorScheme))
                            .padding(.leading, 4) // Add just a little offset from the text cursor
                            .allowsHitTesting(false)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                }
                .padding(.leading, 16) // Match TextEditor's horizontal padding
            )
    }
    
    // Command buttons row
    private var commandButtons: some View {
        HStack(spacing: 12) {
            // Plus button
            CircleIconButton(
                icon: Ph.plus.duotone,
                action: {
                    // Remember if keyboard is currently open
                    wasKeyboardOpen = isInputFocused
                    
                    // First dismiss keyboard
                    isInputFocused = false
                    
                    // Provide haptic feedback
                    HapticManager.shared.lightImpact()
                    
                    // Give keyboard time to dismiss before showing sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showAttachmentSheet = true
                    }
                }
            )
            
            // Comment out the mode buttons as requested
            /*
            // Spin button
            CommandButton(
                icon: Ph.spiral.duotone,
                label: "spin",
                isActive: spinActive,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        thinkActive = false
                        spinActive.toggle()
                        updateMode()
                    }
                }
            )
            
            // Think button
            CommandButton(
                icon: Ph.person.duotone,
                label: "think",
                isActive: thinkActive,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        spinActive = false
                        thinkActive.toggle()
                        updateMode()
                    }
                }
            )
            */
            
            Spacer()
            
            // Send button
            SendButton(
                isEnabled: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                isLoading: isLoading, 
                action: {
                    // Provide haptic feedback
                    HapticManager.shared.lightImpact()
                    
                    print("📱 CommandBarView: Send button tapped")
                    onSubmit()
                }
            )
            .animation(.easeInOut(duration: 0.3), value: text.isEmpty) // Animate button enabled state
            .animation(.easeInOut(duration: 0.3), value: isLoading) // Animate loading state
        }
    }
    
    // Update mode based on button states
    private func updateMode() {
        if spinActive {
            mode = .spin
        } else if thinkActive {
            mode = .think
        } else {
            mode = .main
        }
    }
    
    // Update UI based on mode
    private func updateUIFromMode() {
        withAnimation(.easeInOut(duration: 0.3)) { // Slightly longer animation
            switch mode {
            case .spin:
                spinActive = true
                thinkActive = false
            case .think:
                spinActive = false
                thinkActive = true
            case .main:
                spinActive = false
                thinkActive = false
            }
        }
    }
    
    // Reset command bar to initial state with animation
    public func resetState() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Reset text with a fade effect
            text = ""
            textHeight = 40 // Reset height to single line
            
            // Reset mode to main
            mode = .main
            spinActive = false
            thinkActive = false
            
            // Ensure loading state is off
            isLoading = false
            
            // Close attachment sheet if open
            showAttachmentSheet = false
        }
    }
    
    // Helper to get safe area bottom inset
    private func getSafeAreaBottom() -> CGFloat {
        if #available(iOS 15.0, *) {
            // For iOS 15 and newer
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            return windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
        } else {
            // For older iOS versions
            return UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        }
    }
}

// Custom button style for subtle scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    VStack {
        Spacer()
        CommandBarView(
            text: .constant(""),
            mode: .constant(.think),
            isLoading: .constant(false),
            commandBarFocused: .constant(true),
            onSubmit: {}
        )
    }
    .background(Color(.systemBackground))
} 
