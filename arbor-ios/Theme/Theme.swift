//
//  Theme.swift
//  webs-ios
//
//  Created by Luke Nittmann on 4/6/25.
//

import SwiftUI

// Define ColorTheme to match web app's globals.css
struct Theme {
    // Light theme colors - using eggshell for UI elements against white background
    static let lightBackground = Color(light: Color(.white), dark: Color(hex: "000000")) // Pure black for dark mode
    static let lightForeground = Color(light: Color(hex: "32302C"), dark: Color(.white)) // Keeping warm text color
    static let lightCard = Color(light: Color(hex: "F8F7F2"), dark: Color(hex: "1A1A1A")) // Dark slate for cards
    static let lightBorder = Color(light: Color(hex: "E5E2D9"), dark: Color(hex: "2C2C2C")) // Darker border
    static let lightInput = Color(light: Color(hex: "F8F7F2"), dark: Color(hex: "2C2C2C")) // Dark slate for input areas
    static let lightMuted = Color(light: Color(hex: "F8F7F2"), dark: Color(hex: "2C2C2C")) // Dark slate for muted areas
    static let lightMutedForeground = Color(light: Color(hex: "9A948A"), dark: Color(hex: "8A8A8A")) // Warmer muted text
    static let lightPrimary = Color(light: Color(hex: "7686F8"), dark: Color(hex: "7686F8")) // Keep the same primary color
    static let lightAccent = Color(light: Color(hex: "7686F8"), dark: Color(hex: "7686F8")) // Accent color (same as primary)
    static let lightMutedBackground = Color(light: Color(hex: "F0EEE9"), dark: Color(hex: "141414")) // Darker muted background
    
    // Access the appropriate color based on the current color scheme
    static func background(scheme: ColorScheme) -> Color {
        scheme == .light ? lightBackground.resolve(in: scheme) : lightBackground.resolve(in: scheme)
    }
    
    static func foreground(scheme: ColorScheme) -> Color {
        scheme == .light ? lightForeground.resolve(in: scheme) : lightForeground.resolve(in: scheme)
    }
    
    static func primaryForeground(scheme: ColorScheme) -> Color {
        foreground(scheme: scheme) // Alias for foreground
    }
    
    static func card(scheme: ColorScheme) -> Color {
        scheme == .light ? lightCard.resolve(in: scheme) : lightCard.resolve(in: scheme)
    }
    
    static func border(scheme: ColorScheme) -> Color {
        scheme == .light ? lightBorder.resolve(in: scheme) : lightBorder.resolve(in: scheme)
    }
    
    static func input(scheme: ColorScheme) -> Color {
        scheme == .light ? lightInput.resolve(in: scheme) : lightInput.resolve(in: scheme)
    }
    
    static func muted(scheme: ColorScheme) -> Color {
        scheme == .light ? lightMuted.resolve(in: scheme) : lightMuted.resolve(in: scheme)
    }
    
    static func mutedBackground(scheme: ColorScheme) -> Color {
        scheme == .light ? lightMutedBackground.resolve(in: scheme) : lightMutedBackground.resolve(in: scheme)
    }
    
    static func mutedForeground(scheme: ColorScheme) -> Color {
        scheme == .light ? lightMutedForeground.resolve(in: scheme) : lightMutedForeground.resolve(in: scheme)
    }
    
    static func primary(scheme: ColorScheme) -> Color {
        scheme == .light ? lightPrimary.resolve(in: scheme) : lightPrimary.resolve(in: scheme)
    }
    
    static func accentColor(scheme: ColorScheme) -> Color {
        scheme == .light ? lightAccent.resolve(in: scheme) : lightAccent.resolve(in: scheme)
    }
}

// Helper extension for color from hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (32-bit)
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    init(light: Color, dark: Color) {
        self = Color(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }

    func resolve(in environment: ColorScheme) -> Color {
        environment == .dark ? self : self
    }
}
