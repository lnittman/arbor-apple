//
//  SharedToolUtilityViews.swift
//  webs-ios
//

import SwiftUI
import PhosphorSwift
import Markdown

// A view for formatting JSON string as readable content
struct FormatJsonView: View {
    let jsonString: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var formattedItems: [(key: String, value: String)] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(formattedItems, id: \.key) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.key)
                        .font(Font.iosevkaCaption())
                        .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                    
                    Text(item.value)
                        .font(Font.iosevkaBody())
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.background(scheme: colorScheme))
                        )
                }
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            parseJsonString()
        }
    }
    
    private func parseJsonString() {
        guard let jsonData = jsonString.data(using: .utf8) else {
            formattedItems = [("Error", "Could not parse JSON")]
            return
        }
        
        do {
            // Try parsing as a dictionary
            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                formattedItems = jsonDict.map { key, value in
                    (key, String(describing: value))
                }.sorted { $0.key < $1.key }
            }
            // Try parsing as an array
            else if let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [Any] {
                formattedItems = jsonArray.enumerated().map { index, value in
                    ("Item \(index + 1)", String(describing: value))
                }
            }
            // Fallback
            else {
                formattedItems = [("Value", jsonString)]
            }
        } catch {
            formattedItems = [("Raw value", jsonString.replacingOccurrences(of: "\\n", with: "\n"))]
        }
    }
}

// A view for displaying URL content
struct URLContentView: View {
    let url: String
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(url)
                .font(Font.iosevkaBody())
                .foregroundColor(Theme.primary(scheme: colorScheme))
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            Button(action: {
                if let url = URL(string: url) {
                    openURL(url)
                }
            }) {
                HStack {
                    Ph.arrowSquareOut.duotone
                        .color(Theme.foreground(scheme: colorScheme))
                        .frame(width: 16, height: 16)
                    
                    Text("Open in browser")
                        .font(Font.iosevkaSubheadline())
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.card(scheme: colorScheme))
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}

// A view for displaying formatted text content
struct FormattedTextView: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    
    private var formattedText: String {
        return text.replacingOccurrences(of: "\\n", with: "\n")
    }
    
    private var attributedContent: AttributedString {
        do {
            // Try parsing markdown, which will handle links and formatting
            var attributedString = try AttributedString(markdown: formattedText, options: AttributedString.MarkdownParsingOptions(
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
            // If markdown parsing fails, return plain text
            return AttributedString(formattedText)
        }
    }
    
    var body: some View {
        Text(attributedContent)
            .font(Font.iosevkaBody())
            .foregroundColor(Theme.foreground(scheme: colorScheme))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.card(scheme: colorScheme).opacity(0.5))
            )
            .environment(\.openURL, OpenURLAction { url in
                openURL(url)
                return .handled
            })
            .tint(Theme.primary(scheme: colorScheme))
    }
}

// Helper formatting function for both views
func formatKey(_ key: String) -> String {
    let formattedKey = key
        .replacingOccurrences(of: "_", with: " ")
        .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
        .lowercased()
        
    // Capitalize first letter
    return formattedKey.prefix(1).uppercased() + formattedKey.dropFirst()
} 
