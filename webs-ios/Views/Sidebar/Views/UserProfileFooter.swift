import SwiftUI
import PhosphorSwift
import Clerk

struct UserProfileFooter: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(Clerk.self) private var clerk
    @State private var showSettingsSheet = false
    @State private var isSigningOut = false
    @State private var showSignOutAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Theme.border(scheme: colorScheme))
            
            Button {
                showSettingsSheet = true
            } label: {
                HStack(spacing: 10) {
                    // User avatar or initials circle - always show initials
                    Circle()
                        .fill(Theme.mutedBackground(scheme: colorScheme))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(getInitials())
                                .font(Font.iosevkaCaption())
                                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                        )
                    
                    // User display name and email
                    VStack(alignment: .leading, spacing: 2) {
                        Text(clerk.user?.firstName ?? "User")
                            .font(Font.iosevkaFootnote())
                            .foregroundColor(Theme.foreground(scheme: colorScheme))
                            .lineLimit(1)
                        
                        if let email = clerk.user?.emailAddresses.first?.emailAddress {
                            Text(email)
                                .font(Font.iosevkaCaption())
                                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Replaced gear with ellipsis
                    Ph.dotsThree.duotone
                        .color(Theme.mutedForeground(scheme: colorScheme))
                        .frame(width: 20, height: 20)
                }
                .padding(16)
                .background(Theme.background(scheme: colorScheme))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .sheet(isPresented: $showSettingsSheet) {
            UserSettingsSheet()
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .overlay {
            if isSigningOut {
                ZStack {
                    Color.black.opacity(0.4)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    private func getInitials() -> String {
        if let firstName = clerk.user?.firstName?.prefix(1), 
           let lastName = clerk.user?.lastName?.prefix(1),
           !firstName.isEmpty,
           !lastName.isEmpty {
            return "\(firstName)\(lastName)"
        } else if let firstName = clerk.user?.firstName?.prefix(1), !firstName.isEmpty {
            return String(firstName)
        } else if let email = clerk.user?.emailAddresses.first?.emailAddress {
            return String(email.prefix(1).uppercased())
        } else {
            return "U"
        }
    }
    
    private func signOut() {
        isSigningOut = true
        
        Task {
            do {
                try await appViewModel.signOut()
                isSigningOut = false
            } catch {
                print("Error signing out: \(error)")
                isSigningOut = false
            }
        }
    }
}

#Preview {
    UserProfileFooter()
        .environmentObject(AppViewModel())
} 
