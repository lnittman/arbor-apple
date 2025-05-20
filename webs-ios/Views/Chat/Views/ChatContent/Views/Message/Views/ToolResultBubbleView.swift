//
//  ToolResultBubbleView.swift
//  webs-ios
//

import SwiftUI
import PhosphorSwift

struct ToolResultBubbleView: View {
    let content: String
    let result: [String: String]
    @Binding var showDetails: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private var processedContent: String {
        return content.replacingOccurrences(of: "\\n", with: "\n")
    }
    
    var body: some View {
        Button(action: {
            showDetails = true
        }) {
            HStack(spacing: 12) {
                // Result icon
                Ph.check.duotone
                    .color(Theme.primary(scheme: colorScheme))
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Result content
                    Text(processedContent)
                        .font(Font.iosevkaSubheadline())
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                        .multilineTextAlignment(.leading)
                    
                    // Tap for details text
                    Text("Tap to view details")
                        .font(Font.iosevkaCaption())
                        .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
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
    VStack(spacing: 16) {
        ToolResultBubbleView(
            content: "Found information from 3 sources",
            result: ["content": "Quantum physics information retrieved"],
            showDetails: .constant(false)
        )
        
        ToolResultBubbleView(
            content: "Found information with\nnewlines in the content",
            result: ["content": "Multiline\nresult\ncontent"],
            showDetails: .constant(false)
        )
    }
    .padding()
    .background(Color(.systemBackground))
} 
