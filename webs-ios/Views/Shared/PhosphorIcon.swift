import SwiftUI
import PhosphorSwift

struct PhosphorIcon: View {
    let icon: Image
    var size: CGFloat = 20
    var color: Color?
    @Environment(\.colorScheme) private var colorScheme
    
    init(icon: Image, size: CGFloat = 20, color: Color? = nil) {
        self.icon = icon
        self.size = size
        self.color = color
    }
    
    var body: some View {
        icon
            .color(color ?? Theme.foreground(scheme: colorScheme))
            .frame(width: size, height: size)
    }
}

extension PhosphorIcon {
    // Convenience initializers for different sizes
    static func small(_ icon: Image, color: Color? = nil) -> PhosphorIcon {
        PhosphorIcon(icon: icon, size: 14, color: color)
    }
    
    static func medium(_ icon: Image, color: Color? = nil) -> PhosphorIcon {
        PhosphorIcon(icon: icon, size: 20, color: color)
    }
    
    static func large(_ icon: Image, color: Color? = nil) -> PhosphorIcon {
        PhosphorIcon(icon: icon, size: 28, color: color)
    }
}

#Preview {
    VStack(spacing: 20) {
        PhosphorIcon.small(Ph.plus.duotone)
        PhosphorIcon.medium(Ph.camera.duotone)
        PhosphorIcon.large(Ph.fileArrowUp.duotone, color: .blue)
    }
    .padding()
} 
