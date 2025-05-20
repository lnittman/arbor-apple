//
//  ToolCallBubbleView.swift
//  webs-ios
//

import SwiftUI
import PhosphorSwift

struct ToolCallBubbleView: View {
    let toolName: String
    let args: [String: String]
    @Binding var showDetails: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            showDetails = true
        }) {
            HStack(spacing: 12) {
                // Tool icon
                Ph.wrench.duotone
                    .color(Theme.primary(scheme: colorScheme))
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Tool name
                    Text(toolName)
                        .font(Font.iosevkaSubheadline())
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                    
                    // Tool arguments preview
                    let argsPreview = args.first?.key ?? "No arguments"
                    Text(argsPreview)
                        .font(Font.iosevkaCaption())
                        .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Chevron icon to indicate tappable
                Ph.caretRight.duotone
                    .color(Theme.mutedForeground(scheme: colorScheme))
                    .frame(width: 16, height: 16)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.card(scheme: colorScheme))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8)
    }
}

#Preview {
    ToolCallBubbleView(
        toolName: "web_search",
        args: ["query": "quantum physics", "limit": "5"],
        showDetails: .constant(false)
    )
    .padding()
    .background(Color(.systemBackground))
} 
