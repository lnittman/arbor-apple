import SwiftUI

struct SafeAreaUtils {
    static func getSafeAreaTop() -> CGFloat {
        if #available(iOS 15.0, *) {
            // For iOS 15 and newer
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            return windowScene?.windows.first?.safeAreaInsets.top ?? 0
        } else {
            // For older iOS versions
            return UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
        }
    }
    
    static func getSafeAreaBottom() -> CGFloat {
        if #available(iOS 15.0, *) {
            // For iOS 15 and newer
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            return windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
        } else {
            // For older iOS versions
            return UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        }
    }
} 