//
//  FeedbackToastView.swift
//  webs-ios
//

import SwiftUI
import PhosphorSwift

struct FeedbackToastView: View {
    let message: String
    @Binding var isShowing: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Ph.checkCircle.fill
                .color(Theme.primary(scheme: colorScheme))
                .frame(width: 16, height: 16)
            
            Text(message)
                .font(Font.iosevkaCaption())
                .foregroundColor(Theme.foreground(scheme: colorScheme))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Theme.card(scheme: colorScheme))
                .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    FeedbackToastView(message: "copied to clipboard", isShowing: .constant(true))
        .padding()
        .background(Color(.systemBackground))
} 
