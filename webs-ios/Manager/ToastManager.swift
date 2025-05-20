import SwiftUI
import PhosphorSwift

// Toast types for easy reference
public enum ToastType {
    case success, info, warning, error, loggedOut, copy
    
    var icon: Image {
        switch self {
        case .success:
            return Ph.checkCircle.fill
        case .info:
            return Ph.info.fill
        case .warning:
            return Ph.warning.fill
        case .error:
            return Ph.x.fill
        case .loggedOut:
            return Ph.signOut.fill
        case .copy:
            return Ph.copySimple.fill
        }
    }
    
    var iconColor: Color {
        switch self {
        case .success:
            return .green
        case .info, .loggedOut, .copy:
            return Color(.systemBlue)
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
    
    var defaultMessage: String {
        switch self {
        case .success:
            return "success"
        case .info:
            return "info"
        case .warning:
            return "warning"
        case .error:
            return "error"
        case .loggedOut:
            return "logged out"
        case .copy:
            return "copied to clipboard"
        }
    }
}

// Define possible toast display locations
public enum ToastLocation {
    case top, bottom, middle
}

// Central toast manager to handle toast notifications throughout the app
public final class ToastManager: ObservableObject {
    @Published public var showToast = false
    @Published public var toastMessage = ""
    @Published public var toastIcon: Image = Ph.checkCircle.fill
    @Published public var toastIconColor: Color = .green
    @Published public var toastType: ToastType = .success
    @Published public var displayLocation: ToastLocation = .bottom
    
    public init() {}
    
    // Show a toast with the specified type and message
    public func showToast(type: ToastType, message: String = "", duration: Double = 2.5, location: ToastLocation = .bottom) {
        // Configure the toast based on type
        self.toastType = type
        self.displayLocation = location
        
        // Set icon and color based on type
        self.toastIcon = type.icon
        self.toastIconColor = type.iconColor
        
        // Set message (use default if not provided)
        self.toastMessage = message.isEmpty ? type.defaultMessage : message
        
        // Show toast without animation - ContentView controls the animation
        self.showToast = true
        
        // Hide after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            // Simply set to false - ContentView controls the animation
            self.showToast = false
        }
    }
    
    // Convenience methods for common toast types
    public func showSuccess(message: String = "", duration: Double = 2.0) {
        showToast(type: .success, message: message, duration: duration)
    }
    
    public func showInfo(message: String = "", duration: Double = 2.0) {
        showToast(type: .info, message: message, duration: duration)
    }
    
    public func showWarning(message: String = "", duration: Double = 2.0) {
        showToast(type: .warning, message: message, duration: duration)
    }
    
    public func showError(message: String = "", duration: Double = 2.0) {
        showToast(type: .error, message: message, duration: duration)
    }
    
    public func showLoggedOut(duration: Double = 3.0) {
        showToast(type: .loggedOut, duration: duration, location: .top)
    }
    
    public func showCopied(duration: Double = 1.5) {
        showToast(type: .copy, duration: duration)
    }
    
    // Legacy method for backward compatibility with old implementation
    public func showMessage(_ message: String) {
        showInfo(message: message)
    }
    
    // Helper method to get the appropriate toast view
    public func toastView() -> some View {
        ToastView(
            message: toastMessage,
            icon: toastIcon,
            iconColor: toastIconColor,
            isShowing: Binding(
                get: { self.showToast },
                set: { self.showToast = $0 }
            )
        )
    }
} 