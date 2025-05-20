import SwiftUI
import PhosphorSwift

/// A custom confirmation dialog that appears at the bottom of the screen
struct ConfirmationDialogView: View {
    let title: String
    let message: String?
    let confirmAction: () -> Void
    let cancelAction: () -> Void
    let confirmLabel: String
    let cancelLabel: String
    let confirmRole: ButtonRole?
    
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var dialogOffset: CGFloat = UIScreen.main.bounds.height
    
    init(
        title: String,
        message: String? = nil,
        confirmLabel: String = "confirm",
        cancelLabel: String = "cancel",
        confirmRole: ButtonRole? = .destructive,
        isPresented: Binding<Bool>,
        confirmAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void = {}
    ) {
        self.title = title
        self.message = message
        self.confirmLabel = confirmLabel
        self.cancelLabel = cancelLabel
        self.confirmRole = confirmRole
        self._isPresented = isPresented
        self.confirmAction = confirmAction
        self.cancelAction = cancelAction
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .opacity(dialogOffset < UIScreen.main.bounds.height ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: dialogOffset)
                .onTapGesture {
                    hideDialog {
                        cancelAction()
                    }
                }
            
            // Dialog content at the bottom
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Title
                    Text(title)
                        .font(Font.iosevkaBody())
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, message == nil ? 24 : 8)
                    
                    // Optional message
                    if let message = message {
                        Text(message)
                            .font(Font.iosevkaFootnote())
                            .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                    }
                    
                    Divider()
                        .background(Theme.border(scheme: colorScheme))
                    
                    // Confirm button - typically destructive action like delete or sign out
                    Button {
                        hideDialog {
                            confirmAction()
                        }
                    } label: {
                        Text(confirmLabel)
                            .font(Font.iosevkaBody())
                            .foregroundColor(confirmRole == .destructive ? .red : Theme.primary(scheme: colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    
                    Divider()
                        .background(Theme.border(scheme: colorScheme))
                    
                    // Cancel button
                    Button {
                        hideDialog {
                            cancelAction()
                        }
                    } label: {
                        Text(cancelLabel)
                            .font(Font.iosevkaBody())
                            .foregroundColor(Theme.accentColor(scheme: colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .background(Theme.card(scheme: colorScheme))
                .cornerRadius(14)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .offset(y: dialogOffset)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dialogOffset)
            }
        }
        .onAppear {
            // Animate dialog up from bottom when appearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dialogOffset = 0
            }
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                // Show the dialog with animation
                dialogOffset = 0
            }
        }
    }
    
    // Helper function to hide dialog with animation
    private func hideDialog(completion: @escaping () -> Void) {
        // Animate dialog down
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            dialogOffset = UIScreen.main.bounds.height
        }
        
        // Dismiss after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
            completion()
        }
    }
}

// Manager class to handle confirmation dialogs across the app
class ConfirmationDialogManager: ObservableObject {
    @Published var isShowingDialog = false
    @Published var dialogTitle = ""
    @Published var dialogMessage: String? = nil
    @Published var confirmLabel = "confirm"
    @Published var cancelLabel = "cancel"
    @Published var confirmRole: ButtonRole? = .destructive
    
    var confirmAction: () -> Void = {}
    var cancelAction: () -> Void = {}
    
    func showDialog(
        title: String,
        message: String? = nil,
        confirmLabel: String = "confirm",
        cancelLabel: String = "cancel",
        confirmRole: ButtonRole? = .destructive,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.dialogTitle = title
        self.dialogMessage = message
        self.confirmLabel = confirmLabel
        self.cancelLabel = cancelLabel
        self.confirmRole = confirmRole
        self.confirmAction = onConfirm
        self.cancelAction = onCancel
        
        withAnimation(.easeIn(duration: 0.2)) {
            self.isShowingDialog = true
        }
    }
    
    func showLogoutConfirmation(
        email: String,
        onConfirm: @escaping () -> Void
    ) {
        showDialog(
            title: "log out of webs as '\(email)'?",
            confirmLabel: "yes",
            cancelLabel: "cancel",
            confirmRole: .destructive,
            onConfirm: onConfirm
        )
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .edgesIgnoringSafeArea(.all)
        
        ConfirmationDialogView(
            title: "log out of webs as 'user@example.com'?",
            confirmLabel: "yes",
            cancelLabel: "cancel",
            isPresented: .constant(true),
            confirmAction: {},
            cancelAction: {}
        )
    }
} 
