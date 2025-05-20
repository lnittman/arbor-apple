import SwiftUI
import PhosphorSwift

struct RenameDialogView: View {
    let chatTitle: String
    let onSave: (String) -> Void
    @Binding var isPresented: Bool
    @State private var newName: String
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    // Track keyboard height and visibility for repositioning
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    
    init(chatTitle: String, isPresented: Binding<Bool>, onSave: @escaping (String) -> Void) {
        self.chatTitle = chatTitle
        self._isPresented = isPresented
        self.onSave = onSave
        _newName = State(initialValue: chatTitle)
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissDialog()
                }
            
            // Dialog content
            VStack(spacing: 24) {
                // Title
                Text("rename conversation")
                    .font(Font.iosevkaHeadline())
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
                
                // Subtitle
                Text("enter a new name")
                    .font(Font.iosevkaBody())
                    .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                
                // Text field
                TextField("", text: $newName)
                    .font(Font.iosevkaBody())
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.input(scheme: colorScheme))
                    )
                    .focused($isTextFieldFocused)
                
                // Buttons row
                HStack(spacing: 16) {
                    // Cancel button
                    Button {
                        dismissDialog()
                    } label: {
                        Text("cancel")
                            .font(Font.iosevkaBody())
                            .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.border(scheme: colorScheme), lineWidth: 1)
                            )
                    }
                    
                    // OK button
                    Button {
                        // Don't save empty name
                        if !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            saveAndDismiss()
                        }
                    } label: {
                        Text("OK")
                            .font(Font.iosevkaBody())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Theme.primary(scheme: colorScheme))
                                    .opacity(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                            )
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .background(Theme.card(scheme: colorScheme))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
            .padding(.horizontal, 40)
            .frame(maxWidth: 420)
            // Adjust position when keyboard appears
            .offset(y: isKeyboardVisible ? -keyboardHeight/3 : 0)
            .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
        }
        .opacity(isPresented ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: isPresented)
        .onAppear {
            // Start observing keyboard
            setupKeyboardObservers()
            
            // Focus the text field after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
        .onDisappear {
            // Remove keyboard observers
            removeKeyboardObservers()
        }
    }
    
    private func dismissDialog() {
        // Dismiss keyboard first
        isTextFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Wait a moment for keyboard to start dismissing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                isPresented = false
            }
        }
    }
    
    private func saveAndDismiss() {
        // Provide haptic feedback
        HapticManager.shared.mediumImpact()
        
        // Dismiss keyboard first
        isTextFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Wait for keyboard to start dismissing before animating dialog out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                isPresented = false
            }
            
            // Call save callback after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onSave(newName)
            }
        }
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                // Get the height of the keyboard
                self.keyboardHeight = keyboardFrame.height
                
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.isKeyboardVisible = true
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                self.isKeyboardVisible = false
                self.keyboardHeight = 0
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
} 
