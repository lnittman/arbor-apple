import SwiftUI
import PhosphorSwift
import Clerk

// User settings sheet
struct UserSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(Clerk.self) private var clerk
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var dialogManager: ConfirmationDialogManager
    @AppStorage("colorScheme") private var userColorScheme: String = "system"
    @AppStorage("hapticFeedback") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("autocorrectSpelling") private var autocorrectSpellingEnabled: Bool = true
    @State private var currentAppearance: ColorScheme = .dark
    @State private var isLoggingOut = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background to match main app
                Theme.background(scheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with title and close button in the same row
                    ZStack {
                        // Title - centered
                        Text("settings")
                            .font(Font.iosevkaHeadline())
                            .foregroundColor(Theme.foreground(scheme: colorScheme))
                            .frame(maxWidth: .infinity)
                        
                        // Close button - right aligned
                        HStack {
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Ph.x.duotone
                                    .color(Theme.mutedForeground(scheme: colorScheme))
                                    .frame(width: 24, height: 24)
                            }
                            .padding(.trailing)
                        }
                    }
                    .padding(.top)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Account Section
                            SettingsSectionView(title: "account") {
                                VStack(spacing: 0) {
                                    // Container for continuous list look
                                    VStack(spacing: 1) {
                                        SettingsItemButton(icon: Ph.userGear.duotone, title: "personalization") {
                                            // Action for personalization
                                        }
                                        .cornerRadius(0)
                                        
                                        Divider()
                                            .background(Theme.border(scheme: colorScheme))
                                            .padding(.horizontal, 16)
                                        
                                        SettingsItemButton(icon: Ph.bell.duotone, title: "notifications") {
                                            // Action for notifications
                                        }
                                        .cornerRadius(0)
                                        
                                        Divider()
                                            .background(Theme.border(scheme: colorScheme))
                                            .padding(.horizontal, 16)
                                        
                                        SettingsItemButton(icon: Ph.shieldStar.duotone, title: "data controls") {
                                            // Action for data controls
                                        }
                                        .cornerRadius(0)
                                        
                                        Divider()
                                            .background(Theme.border(scheme: colorScheme))
                                            .padding(.horizontal, 16)
                                        
                                        SettingsItemButton(icon: Ph.archive.duotone, title: "archived chats") {
                                            // Action for archived chats
                                        }
                                        .cornerRadius(0)
                                    }
                                    .background(Theme.card(scheme: colorScheme))
                                    .cornerRadius(12)
                                }
                            }
                            
                            // App Section
                            SettingsSectionView(title: "app") {
                                VStack(spacing: 1) {
                                    // Color scheme buttons filling entire row
                                    HStack(spacing: 4) {
                                        // Light button
                                        ColorSchemeButton(
                                            scheme: "light",
                                            icon: Ph.sun.duotone,
                                            isSelected: userColorScheme == "light",
                                            position: .left,
                                            onThemeChange: { newScheme in
                                                currentAppearance = newScheme
                                            }
                                        )
                                        
                                        // Dark button
                                        ColorSchemeButton(
                                            scheme: "dark", 
                                            icon: Ph.moon.duotone,
                                            isSelected: userColorScheme == "dark",
                                            position: .center,
                                            onThemeChange: { newScheme in
                                                currentAppearance = newScheme
                                            }
                                        )
                                        
                                        // System button
                                        ColorSchemeButton(
                                            scheme: "system",
                                            icon: Ph.deviceMobile.duotone,
                                            isSelected: userColorScheme == "system",
                                            position: .right,
                                            onThemeChange: { newScheme in
                                                currentAppearance = newScheme
                                            }
                                        )
                                    }
                                    .padding(.top, 12) // Add top padding
                                    .padding(.horizontal, 16) // Add horizontal padding
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.card(scheme: colorScheme))
                                    .cornerRadius(0)
                                    
                                    // Toggle settings
                                    PhosphorToggle(
                                        icon: Ph.vibrate.duotone,
                                        title: "haptic feedback",
                                        isOn: $hapticFeedbackEnabled
                                    )
                                    
                                    Divider()
                                        .background(Theme.border(scheme: colorScheme))
                                        .padding(.horizontal, 16)
                                    
                                    PhosphorToggle(
                                        icon: Ph.textAa.duotone,
                                        title: "autocorrect spelling",
                                        isOn: $autocorrectSpellingEnabled
                                    )
                                }
                                .background(Theme.card(scheme: colorScheme))
                                .cornerRadius(12)
                            }
                            
                            // About Section
                            SettingsSectionView(title: "about") {
                                VStack(spacing: 1) {
                                    // External link buttons without chevrons
                                    Button {
                                        // Action for terms
                                    } label: {
                                        HStack {
                                            Ph.fileText.duotone
                                                .color(Theme.mutedForeground(scheme: colorScheme))
                                                .frame(width: 20, height: 20)
                                                .padding(.trailing, 8)
                                            
                                            Text("terms of use")
                                                .font(Font.iosevkaBody())
                                                .foregroundColor(Theme.foreground(scheme: colorScheme))
                                            
                                            Spacer()
                                            
                                            Ph.arrowSquareOut.duotone
                                                .color(Theme.mutedForeground(scheme: colorScheme))
                                                .frame(width: 16, height: 16)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    
                                    Divider()
                                        .background(Theme.border(scheme: colorScheme))
                                        .padding(.horizontal, 16)
                                    
                                    Button {
                                        // Action for privacy policy
                                    } label: {
                                        HStack {
                                            Ph.shield.duotone
                                                .color(Theme.mutedForeground(scheme: colorScheme))
                                                .frame(width: 20, height: 20)
                                                .padding(.trailing, 8)
                                            
                                            Text("privacy policy")
                                                .font(Font.iosevkaBody())
                                                .foregroundColor(Theme.foreground(scheme: colorScheme))
                                            
                                            Spacer()
                                            
                                            Ph.arrowSquareOut.duotone
                                                .color(Theme.mutedForeground(scheme: colorScheme))
                                                .frame(width: 16, height: 16)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    
                                    Divider()
                                        .background(Theme.border(scheme: colorScheme))
                                        .padding(.horizontal, 16)
                                    
                                    // Version info
                                    HStack {
                                        Ph.info.duotone
                                            .color(Theme.mutedForeground(scheme: colorScheme))
                                            .frame(width: 20, height: 20)
                                            .padding(.trailing, 8)
                                        
                                        Text("version")
                                            .font(Font.iosevkaBody())
                                            .foregroundColor(Theme.foreground(scheme: colorScheme))
                                        
                                        Spacer()
                                        
                                        Text("1.0.0")
                                            .font(Font.iosevkaBody())
                                            .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                .background(Theme.card(scheme: colorScheme))
                                .cornerRadius(12)
                            }
                            
                            // Log out button
                            Button {
                                // Simply dismiss the sheet first
                                dismiss()
                                
                                // After sheet is dismissed, trigger logout with fade animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    // Signal to the app view model that we want to log out with animation
                                    appViewModel.logoutWithAnimation()
                                }
                            } label: {
                                HStack {
                                    Ph.signOut.duotone
                                        .color(Color.red)
                                        .frame(width: 20, height: 20)
                                        .padding(.trailing, 8)
                                    
                                    Text("log out")
                                        .font(Font.iosevkaBody())
                                        .foregroundColor(Color.red)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Theme.card(scheme: colorScheme))
                                .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                        .padding(16)
                    }
                }
                .opacity(isLoggingOut ? 0 : 1) // Fade out when logging out
                .animation(.easeOut(duration: 0.3), value: isLoggingOut)
            }
            // Force refresh the view when colorScheme changes
            .id(colorScheme)
            .onChange(of: colorScheme) { oldValue, newValue in
                currentAppearance = newValue
            }
            .onAppear {
                currentAppearance = colorScheme
            }
        }
        .preferredColorScheme(currentAppearance)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
    
    private func performLogout() {
        // Perform the actual logout without dismissing the sheet
        Task {
            do {
                try await appViewModel.signOut()
                
                // Optional: Additional actions after successful logout
                print("User logged out successfully")
            } catch {
                print("Error logging out: \(error)")
                
                // If there's an error, show the view again
                await MainActor.run {
                    withAnimation {
                        isLoggingOut = false
                    }
                }
            }
        }
    }
}

// Settings section with title and content
struct SettingsSectionView<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Font.iosevkaCaption())
                .fontWeight(.semibold)
                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                .padding(.leading, 4)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Button for individual settings items
struct SettingsItemButton: View {
    let icon: Image
    let title: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                icon
                    .color(Theme.mutedForeground(scheme: colorScheme))
                    .frame(width: 20, height: 20)
                    .padding(.trailing, 8)
                
                Text(title)
                    .font(Font.iosevkaBody())
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
                
                Spacer()
                
                Ph.caretRight.duotone
                    .color(Theme.mutedForeground(scheme: colorScheme))
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(height: 44)
            .background(Theme.card(scheme: colorScheme))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Color scheme selection button
struct ColorSchemeButton: View {
    let scheme: String
    let icon: Image
    let isSelected: Bool
    let position: ButtonPosition // Left, center, or right position
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("colorScheme") private var userColorScheme: String = "system"
    
    // Add callback for theme changes
    var onThemeChange: ((ColorScheme) -> Void)? = nil
    
    // Fixed slate color for borders that won't change with color scheme
    private let borderColor = Color(hex: "6E6E76")
    
    enum ButtonPosition {
        case left, center, right
    }
    
    var body: some View {
        Button {
            userColorScheme = scheme
            
            // Apply the theme change immediately
            applyThemeChange(to: scheme)
            
            // Notify parent about the theme change
            let newScheme: ColorScheme = scheme == "dark" ? .dark : scheme == "light" ? .light : colorScheme
            onThemeChange?(newScheme)
        } label: {
            icon
                .color(isSelected ? borderColor : Theme.mutedForeground(scheme: colorScheme))
                .frame(width: 20, height: 20)
                .frame(maxWidth: .infinity) // Take up available width
                .frame(height: 40) // Slightly shorter height
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.card(scheme: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? borderColor : borderColor.opacity(0.5), 
                                        lineWidth: isSelected ? 2 : 1)
                        )
                )
                .padding(2) // Small padding between buttons
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // Apply theme change immediately
    private func applyThemeChange(to scheme: String) {
        // Get the first window from the connected scenes
        let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        let window = windowScene?.windows.first
        
        // Apply the theme change
        switch scheme {
        case "light":
            window?.overrideUserInterfaceStyle = .light
        case "dark":
            window?.overrideUserInterfaceStyle = .dark
        default:
            window?.overrideUserInterfaceStyle = .unspecified
        }
    }
}

// Custom toggle using Phosphor icons
struct PhosphorToggle: View {
    let icon: Image
    let title: String
    @Binding var isOn: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    // Fixed slate color for borders that won't change with color scheme
    private let borderColor = Color(hex: "6E6E76")
    
    var body: some View {
        HStack {
            icon
                .color(Theme.mutedForeground(scheme: colorScheme))
                .frame(width: 20, height: 20)
                .padding(.trailing, 8)
            
            Text(title)
                .font(Font.iosevkaBody())
                .foregroundColor(Theme.foreground(scheme: colorScheme))
            
            Spacer()
            
            // Custom toggle button
            Button {
                isOn.toggle()
            } label: {
                ZStack {
                    // Background capsule
                    Capsule()
                        .fill(Theme.card(scheme: colorScheme))
                        .frame(width: 44, height: 24)
                        .overlay(
                            Capsule()
                                .stroke(isOn ? borderColor : borderColor.opacity(0.5), 
                                        lineWidth: isOn ? 2 : 1)
                        )
                    
                    // Sliding thumb with icon
                    Circle()
                        .fill(Theme.background(scheme: colorScheme))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Group {
                                if isOn {
                                    Ph.check.duotone
                                        .color(borderColor)
                                        .frame(width: 10, height: 10)
                                } else {
                                    Ph.x.duotone
                                        .color(Theme.mutedForeground(scheme: colorScheme))
                                        .frame(width: 10, height: 10)
                                }
                            }
                        )
                        .offset(x: isOn ? 9 : -9)
                        .animation(.spring(response: 0.2), value: isOn)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(height: 44)
    }
}

#Preview {
    UserSettingsSheet()
        .environmentObject(AppViewModel())
        .environmentObject(ConfirmationDialogManager())
} 
