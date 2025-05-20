import SwiftUI
import PhosphorSwift
import Clerk
import AuthenticationServices

struct SignInView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(Clerk.self) private var clerk
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    // State for email flow
    @State private var showEmailFlow = false
    @State private var email = ""
    @State private var isVerifying = false
    @State private var verificationCode = ""
    @FocusState private var isEmailFieldFocused: Bool
    @FocusState private var isCodeFieldFocused: Bool
    
    // Animation states
    @State private var logoOpacity = 1.0
    @State private var buttonsOffset: CGFloat = 0
    @State private var emailFormOpacity = 0.0
    
    // Keyboard state
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    
    // For Apple Sign In presentation
    @State private var appleSignInCoordinator: AppleSignInCoordinator?
    
    var body: some View {
        ZStack {
            // Main background - using primary background color
            Theme.background(scheme: colorScheme)
                .edgesIgnoringSafeArea(.all)
            
            // Center logo area
            VStack(spacing: 12) {
                Text("arbor")
                    .font(Font.iosevkaTitle())
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
                    .fontWeight(.bold)
            }
            .opacity(logoOpacity)
            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.35)
            
            // Email form - fades in when activated
            if showEmailFlow {
                ZStack {
                    // Email authentication flow
                    VStack(spacing: 20) {
                        // Email form content
                        if isVerifying {
                            // Verification code input view
                            HStack {
                                Ph.envelope.duotone
                                    .color(Theme.accentColor(scheme: colorScheme))
                                    .frame(width: 24, height: 24)
                            }
                            .frame(width: 48, height: 48)
                            .padding(.bottom, 8)
                            
                            Text("enter verification code")
                                .font(Font.iosevkaHeadline())
                                .foregroundColor(Theme.foreground(scheme: colorScheme))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.bottom, 16)
                            
                            // Replace single text field with 6 digit code boxes
                            HStack(spacing: 8) {
                                ForEach(0..<6, id: \.self) { index in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Theme.input(scheme: colorScheme))
                                            .frame(width: 44, height: 52)
                                        
                                        if index < verificationCode.count {
                                            let digitIndex = verificationCode.index(verificationCode.startIndex, offsetBy: index)
                                            Text(String(verificationCode[digitIndex]))
                                                .font(Font.iosevkaBody())
                                                .foregroundColor(Theme.foreground(scheme: colorScheme))
                                        }
                                    }
                                    .onTapGesture {
                                        isCodeFieldFocused = true
                                    }
                                }
                            }
                            .padding(.bottom, 16)
                            
                            // Hidden text field that actually captures input
                            TextField("", text: $verificationCode)
                                .keyboardType(.numberPad)
                                .focused($isCodeFieldFocused)
                                .opacity(0)
                                .frame(width: 1, height: 1)
                                .onChange(of: verificationCode) { _, newValue in
                                    // Limit to 6 digits and numeric only
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered.count > 6 {
                                        verificationCode = String(filtered.prefix(6))
                                    } else if filtered != newValue {
                                        verificationCode = filtered
                                    }
                                }
                            
                            Text("we sent a verification code to")
                                .font(Font.iosevkaFootnote())
                                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            Text(email)
                                .font(Font.iosevkaFootnote())
                                .foregroundColor(Theme.foreground(scheme: colorScheme))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.bottom, 16)
                            
                            // Always show verify button, but dim until code length is valid
                            Button {
                                Task { await verifyEmailCode(code: verificationCode) }
                            } label: {
                                Text("verify")
                                    .font(Font.iosevkaBody())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(verificationCode.count == 6 ? 
                                        Theme.primary(scheme: colorScheme) : 
                                        Theme.primary(scheme: colorScheme).opacity(0.5))
                                    .cornerRadius(8)
                                    .animation(.easeInOut(duration: 0.3), value: verificationCode.count == 6)
                            }
                            .disabled(verificationCode.count != 6)
                        } else {
                            // Email input view
                            Text("email authentication")
                                .font(Font.iosevkaHeadline())
                                .foregroundColor(Theme.foreground(scheme: colorScheme))
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            Text("we'll send a verification code to your email")
                                .font(Font.iosevkaFootnote())
                                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.bottom, 8)
                            
                            // Email input field with lowercase placeholder
                            TextField("email", text: $email)
                                .font(Font.iosevkaBody())
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Theme.input(scheme: colorScheme))
                                .cornerRadius(8)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled(true)
                                .focused($isEmailFieldFocused)
                            
                            // Continue button
                            Button {
                                Task { await signInWithEmail(email: email) }
                            } label: {
                                Text("continue with email")
                                    .font(Font.iosevkaBody())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Theme.primary(scheme: colorScheme))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Back button or Change email address
                        Button {
                            if isVerifying {
                                // If we're in verification mode, handle going back to email entry
                                if !verificationCode.isEmpty {
                                    // If code is entered, clear it first
                                    verificationCode = ""
                                } else {
                                    // Go back to email entry
                                    isVerifying = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        self.isEmailFieldFocused = true
                                    }
                                }
                            } else {
                                // Dismiss keyboard first
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                
                                // Reverse animation
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    logoOpacity = 1.0
                                    emailFormOpacity = 0.0
                                    buttonsOffset = 0
                                }
                                
                                // Delay to allow animation to complete
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    showEmailFlow = false
                                    isVerifying = false
                                    email = ""
                                    verificationCode = ""
                                }
                            }
                        } label: {
                            if isVerifying {
                                Text("change email address")
                                    .font(Font.iosevkaBody())
                                    .foregroundColor(Theme.accentColor(scheme: colorScheme))
                                    .underline()
                            } else {
                                Text("go back")
                                    .font(Font.iosevkaBody())
                                    .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 24)
                    .frame(width: UIScreen.main.bounds.width)
                    .opacity(emailFormOpacity)
                    // Adjust vertical position based on keyboard visibility
                    .position(
                        x: UIScreen.main.bounds.width / 2, 
                        y: isKeyboardVisible ? 
                            (UIScreen.main.bounds.height - keyboardHeight) * 0.38 : // Higher when keyboard is visible
                            UIScreen.main.bounds.height * 0.45 // Normal position
                    )
                    .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
                    .animation(.easeInOut(duration: 0.25), value: keyboardHeight)
                }
            }
            
            // Login buttons sheet
            VStack {
                Spacer()
                
                // Bottom sheet with authentication buttons
                VStack(spacing: 16) {
                    // Apple sign in button
                    Button {
                        signInWithApple()
                    } label: {
                        HStack {
                            Image(systemName: "apple.logo")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("continue with Apple")
                                .font(Font.iosevkaBody())
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(colorScheme == .dark ? .black : .white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Google sign in button
                    Button {
                        signInWithGoogle()
                    } label: {
                        HStack {
                            Ph.googleLogo.duotone
                                .color(colorScheme == .dark ? .white : .black)
                                .frame(width: 20, height: 20)
                            
                            Text("continue with Google")
                                .font(Font.iosevkaBody())
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(colorScheme == .dark ? Color(hex: "202123") : .white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Sign up button
                    Button {
                        showEmailView()
                    } label: {
                        Text("sign up")
                            .font(Font.iosevkaBody())
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(colorScheme == .dark ? Color(hex: "202123") : .white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Log in button
                    Button {
                        showEmailView()
                    } label: {
                        Text("log in")
                            .font(Font.iosevkaBody())
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(colorScheme == .dark ? Color(hex: "202123") : .white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 24 + getSafeAreaBottom())
                .background(Theme.card(scheme: colorScheme))
                .cornerRadius(28, corners: [.topLeft, .topRight])
                .offset(y: buttonsOffset)
            }
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                // Force layout update to ensure buttons are positioned correctly
                DispatchQueue.main.async {
                    // This triggers a layout pass and ensures safe areas are calculated
                }
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .alert(item: Binding<AlertItem?>(
            get: { errorMessage.map { AlertItem(message: $0) } },
            set: { errorMessage = $0?.message }
        )) { alertItem in
            Alert(
                title: Text("Error"),
                message: Text(alertItem.message),
                dismissButton: .default(Text("OK")) {
                    errorMessage = nil
                }
            )
        }
        .onChange(of: showEmailFlow) { _, isShowing in
            if isShowing {
                // When showing email flow, focus the email field after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.isEmailFieldFocused = true
                }
            }
        }
        .onAppear {
            // Start observing keyboard notifications
            setupKeyboardObservers()
        }
        .onDisappear {
            // Remove keyboard observers when view disappears
            removeKeyboardObservers()
        }
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            
            // Get the height of the keyboard
            self.keyboardHeight = keyboardFrame.height
            
            withAnimation(.easeInOut(duration: 0.25)) {
                self.isKeyboardVisible = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
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
    
    // Function to handle showing the email view
    private func showEmailView() {
        // Provide haptic feedback
        provideHapticFeedback()
        
        // Set flag first
        showEmailFlow = true
        
        // Start animation sequence
        withAnimation(.easeInOut(duration: 0.4)) {
            // Completely fade out logo
            logoOpacity = 0.0
            
            // Move buttons down off screen
            buttonsOffset = UIScreen.main.bounds.height
        }
        
        // After a slight delay, fade in the email form
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                emailFormOpacity = 1.0
            }
        }
    }
    
    // Helper function to get safe area bottom padding
    private func getSafeAreaBottom() -> CGFloat {
        // Use a more reliable method for getting safe area insets
        // Check both the new scene-based API and the old window-based API
        let safeArea: CGFloat
        
        if let keyWindow = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: { $0.isKeyWindow }) {
            safeArea = keyWindow.safeAreaInsets.bottom
        } else if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            safeArea = keyWindow.safeAreaInsets.bottom
        } else {
            safeArea = 0
        }
        
        return safeArea
    }
    
    // Haptic feedback
    private func provideHapticFeedback() {
        HapticManager.shared.mediumImpact()
    }
    
    // MARK: - Authentication Methods
    
    // Sign in with Apple
    private func signInWithApple() {
        isLoading = true
        provideHapticFeedback()
        
        Task {
            do {
                // Create a new coordinator to handle Apple Sign In
                let coordinator = AppleSignInCoordinator()
                self.appleSignInCoordinator = coordinator
                
                // Start the Apple Sign In flow
                let appleIDCredential = try await coordinator.performAppleSignIn()
                
                // Convert the identityToken data to String format
                guard let idToken = appleIDCredential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }) else { 
                    throw NSError(domain: "SignInError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid token data"])
                }
                
                // Authenticate with Clerk
                try await SignIn.authenticateWithIdToken(provider: .apple, idToken: idToken)
                
                // Refresh Clerk to update user state
                try await clerk.load()
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    print("Sign in with Apple error: \(error)")
                }
            }
        }
    }
    
    // Sign in with Google
    private func signInWithGoogle() {
        isLoading = true
        provideHapticFeedback()
        
        Task {
            do {
                try await SignIn.authenticateWithRedirect(strategy: .oauth(provider: .google))
                
                // Refresh Clerk to update user state
                try await clerk.load()
                
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("Sign in with Google error: \(error)")
            }
        }
    }
    
    // Sign in with Email (Verification Code)
    private func signInWithEmail(email: String) async {
        isLoading = true
        provideHapticFeedback()
        
        do {
            // Reset any existing sign-in to prevent duplicate codes
            // Creating a new SignIn instance should abandon any previous session
            // This prevents duplicate verification codes by starting a fresh flow
            
            // Create a new sign-in without referencing previous session
            var signIn = try await SignIn.create(
                strategy: .identifier(email, strategy: .emailCode())
            )
            
            // Request verification code
            signIn = try await signIn.prepareFirstFactor(strategy: .emailCode())
            
            // Show verification UI
            await MainActor.run {
                isVerifying = true
                isLoading = false
                
                // Set focus on code field after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isCodeFieldFocused = true
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                print("Email authentication error: \(error)")
            }
        }
    }
    
    // Verify email code
    private func verifyEmailCode(code: String) async {
        isLoading = true
        provideHapticFeedback()
        
        do {
            if let signIn = Clerk.shared.client?.signIn {
                try await signIn.attemptFirstFactor(strategy: .emailCode(code: code))
                
                // Reload Clerk and user data
                try await clerk.load()
                
                await MainActor.run {
                    isLoading = false
                }
            } else {
                throw NSError(domain: "SignInError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No active sign-in session"])
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                print("Code verification error: \(error)")
            }
        }
    }
}

// Helper for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Helper for alert
struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - Apple Sign In Coordinator
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    
    func performAppleSignIn() async throws -> ASAuthorizationAppleIDCredential {
        // Create a nonce for Sign in with Apple
        let nonce = UUID().uuidString
        
        // Set up Apple Sign In request
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce
        
        // Perform the request
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            authorizationController.performRequests()
        }
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation?.resume(returning: appleIDCredential)
        } else {
            let error = NSError(domain: "SignInError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not get Apple ID credential"])
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window using the newer UIScene-based API for iOS 15+
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: { $0.isKeyWindow })
        
        // Return the key window or fall back to the first available window
        return keyWindow ?? UIApplication.shared.windows.first!
    }
}

#Preview {
    SignInView()
} 
