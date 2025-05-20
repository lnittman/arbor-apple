import SwiftUI
import UIKit

/// Centralized manager for haptic feedback throughout the app
class HapticManager {
    // Singleton instance
    static let shared = HapticManager()
    
    // Read from the same AppStorage key as used in UserSettingsSheet
    @AppStorage("hapticFeedback") private var hapticFeedbackEnabled: Bool = true
    
    // Private initializer for singleton
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// Trigger a light impact feedback
    func lightImpact() {
        guard hapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Trigger a medium impact feedback
    func mediumImpact() {
        guard hapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Trigger a heavy impact feedback
    func heavyImpact() {
        guard hapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Trigger a medium impact with custom intensity
    func impact(intensity: CGFloat = 1.0) {
        guard hapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }
    
    // MARK: - Notification Feedback
    
    /// Trigger success notification feedback
    func notificationSuccess() {
        guard hapticFeedbackEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Trigger warning notification feedback
    func notificationWarning() {
        guard hapticFeedbackEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Trigger error notification feedback
    func notificationError() {
        guard hapticFeedbackEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Trigger selection feedback
    func selection() {
        guard hapticFeedbackEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
} 