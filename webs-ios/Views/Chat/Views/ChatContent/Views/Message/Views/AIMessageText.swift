//
//  AIMessageText.swift
//  webs-ios
//
//  Created by Luke Nittmann on 4/6/25.
//

import SwiftUI
import Markdown

struct AIMessageTextView: View {
    let content: String
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        HStack {
            Text(attributedContent)
                .font(Font.iosevkaBody())
                .foregroundColor(Theme.foreground(scheme: colorScheme))
                .lineSpacing(5)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.9, alignment: .leading)
                .environment(\.openURL, OpenURLAction { url in
                    openURL(url)
                    return .handled
                })
                .tint(Theme.primary(scheme: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, 8)
    }
    
    // Convert markdown content to AttributedString
    private var attributedContent: AttributedString {
        do {
            // Handle raw newlines first to ensure they're preserved
            let processedContent = content.replacingOccurrences(of: "\\n", with: "\n")
            
            // Parse the markdown and convert to AttributedString
            var attributedString = try AttributedString(markdown: processedContent, options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            ))
            
            // Apply custom styling
            attributedString.foregroundColor = Theme.foreground(scheme: colorScheme)
            
            // Style links correctly
            for run in attributedString.runs {
                if run.link != nil {
                    // Get the range directly from the runs collection
                    let range = run.range
                    attributedString[range].foregroundColor = Theme.primary(scheme: colorScheme)
                    attributedString[range].underlineStyle = .single
                }
            }
            
            return attributedString
        } catch {
            // If markdown parsing fails, return plain text with newlines preserved
            let processedContent = content.replacingOccurrences(of: "\\n", with: "\n")
            return AttributedString(processedContent)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AIMessageTextView(content: "Hello!\nThis is a multi-line response.\n\nNewlines should render correctly.")
        
        AIMessageTextView(content: "Here's a [link example](https://apple.com) that should be clickable.")
        
        AIMessageTextView(content: "More complex example with newlines and links:\n\n[Google](https://google.com)\n[Apple](https://apple.com)")
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
