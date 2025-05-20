import SwiftUI
import Combine

struct KeyboardManager: ViewModifier {
    @Binding var keyboardHeight: CGFloat
    @Binding var isKeyboardVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                setupKeyboardObservers()
            }
            .onDisappear {
                removeKeyboardObservers()
            }
    }
    
    // Set up keyboard observers
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            
            // Only respond if keyboard has actual height (not zero)
            let height = keyboardFrame.height
            if height > 0 {
                self.keyboardHeight = height
                
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.isKeyboardVisible = true
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                self.isKeyboardVisible = false
                // Reset height when keyboard hides
                self.keyboardHeight = 0
            }
        }
    }
    
    // Remove keyboard observers
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension View {
    func manageKeyboard(height: Binding<CGFloat>, isVisible: Binding<Bool>) -> some View {
        self.modifier(KeyboardManager(keyboardHeight: height, isKeyboardVisible: isVisible))
    }
}

// Add static utility for focusing input
extension KeyboardManager {
    /// Attempts to focus a SwiftUI input field by setting its focus state to true
    /// Uses a clean approach with SwiftUI state management
    static func requestFocus(focusPoint: FocusState<Bool>.Binding, delay: Double = 0.6) {
        print("📋 KeyboardManager: requestFocus called with delay \(delay)")
        
        // Use a delayed approach to ensure view hierarchy is fully formed
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            print("📋 KeyboardManager: Setting focus state to true")
            focusPoint.wrappedValue = true
        }
    }
} 