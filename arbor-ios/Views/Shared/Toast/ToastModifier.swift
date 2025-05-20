import SwiftUI

struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager: ToastManager
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if toastManager.displayLocation == .top {
                    Spacer()
                        .frame(height: 8)
                    toastContent
                    Spacer()
                } else if toastManager.displayLocation == .middle {
                    Spacer()
                    toastContent
                    Spacer()
                } else {
                    Spacer()
                    toastContent
                    Spacer()
                        .frame(height: 8)
                }
            }
            .padding(.horizontal)
            .animation(.easeInOut(duration: 0.3), value: toastManager.showToast)
        }
    }
    
    @ViewBuilder
    var toastContent: some View {
        if toastManager.showToast {
            ToastView(
                message: toastManager.toastMessage,
                icon: toastManager.toastIcon,
                iconColor: toastManager.toastIconColor,
                isShowing: $toastManager.showToast
            )
            .transition(
                .move(edge: toastManager.displayLocation == .top ? .top : .bottom)
                .combined(with: .opacity)
            )
        }
    }
}

extension View {
    func toast(manager: ToastManager) -> some View {
        self.modifier(ToastModifier(toastManager: manager))
    }
}

#Preview {
    struct ToastPreview: View {
        @StateObject var toastManager = ToastManager()
        
        var body: some View {
            VStack {
                Button("Show Toast") {
                    toastManager.showInfo(message: "This is a toast message")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toast(manager: toastManager)
        }
    }
    
    return ToastPreview()
} 