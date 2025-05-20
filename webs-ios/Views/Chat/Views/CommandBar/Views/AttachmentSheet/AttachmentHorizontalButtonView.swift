//
//  AttachmentHorizontalButtonView.swift
//  webs-ios
//
//  Created by Luke Nittmann on 4/2/25.
//

import SwiftUI

struct AttachmentHorizontalButton: View {
    let icon: Image
    let label: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                PhosphorIcon.medium(icon)
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
                
                Text(label)
                    .font(Font.iosevkaCaption())
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.border(scheme: colorScheme), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.background(scheme: colorScheme))
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
