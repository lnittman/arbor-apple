import SwiftUI
import UIKit

enum Typeface {
    // The actual font name - verified from UIFont.familyNames output
    static let fontName = "Iosevka-Term"
    
    // Helper to create a properly scaled font that supports Dynamic Type
    static func iosevka(size: CGFloat, style: UIFont.TextStyle) -> Font {
        guard let customFont = UIFont(name: fontName, size: size) else {
            print("Failed to load the \(fontName) font. Falling back to system font.")
            return Font.system(size: size)
        }
        
        // Use UIFontMetrics to properly scale the font based on user's text size preferences
        let scaledFont = UIFontMetrics(forTextStyle: style).scaledFont(for: customFont)
        return Font(scaledFont)
    }
    
    // Common size presets with proper text styles
    static func title() -> Font {
        iosevka(size: 24, style: .title1)
    }
    
    static func headline() -> Font {
        iosevka(size: 18, style: .headline)
    }
    
    static func body() -> Font {
        iosevka(size: 16, style: .body)
    }
    
    static func caption() -> Font {
        iosevka(size: 14, style: .caption1)
    }
    
    static func small() -> Font {
        iosevka(size: 12, style: .caption2)
    }
}

extension View {
    // Apply Iosevka font with Dynamic Type support
    func iosevkaFont(_ style: UIFont.TextStyle, size: CGFloat) -> some View {
        return self.font(Typeface.iosevka(size: size, style: style))
    }
}

// MARK: - Specialized font styles for consistent access
// These functions properly use UIFontMetrics for Dynamic Type support
extension Font {
    static func iosevkaLargeTitle() -> Font {
        Typeface.iosevka(size: 34, style: .largeTitle)
    }
    
    static func iosevkaTitle() -> Font {
        Typeface.iosevka(size: 28, style: .title1)
    }
    
    static func iosevkaTitle2() -> Font {
        Typeface.iosevka(size: 24, style: .title2)
    }
    
    static func iosevkaTitle3() -> Font {
        Typeface.iosevka(size: 20, style: .title3)
    }
    
    static func iosevkaHeadline() -> Font {
        Typeface.iosevka(size: 18, style: .headline)
    }
    
    static func iosevkaBody() -> Font {
        Typeface.iosevka(size: 16, style: .body)
    }
    
    static func iosevkaCallout() -> Font {
        Typeface.iosevka(size: 16, style: .callout)
    }
    
    static func iosevkaSubheadline() -> Font {
        Typeface.iosevka(size: 14, style: .subheadline)
    }
    
    static func iosevkaFootnote() -> Font {
        Typeface.iosevka(size: 12, style: .footnote)
    }
    
    static func iosevkaCaption() -> Font {
        Typeface.iosevka(size: 12, style: .caption1)
    }
    
    static func iosevkaCaption2() -> Font {
        Typeface.iosevka(size: 11, style: .caption2)
    }
}

// Helper function to print all available font names for debugging
func printAllFontNames() {
    for family in UIFont.familyNames.sorted() {
        let names = UIFont.fontNames(forFamilyName: family)
        print("Family: \(family) Font names: \(names)")
    }
} 
