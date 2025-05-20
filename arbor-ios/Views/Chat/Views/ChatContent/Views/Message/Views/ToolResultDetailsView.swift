//
//  ToolResultDetailsView.swift
//  webs-ios
//

import SwiftUI
import PhosphorSwift

struct ToolResultDetailsView: View {
    let content: String
    let result: [String: String]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Ph.check.duotone
                        .color(Theme.primary(scheme: colorScheme))
                        .frame(width: 24, height: 24)
                    
                    Text(content.replacingOccurrences(of: "\\n", with: "\n"))
                        .font(Font.iosevkaHeadline())
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                        .multilineTextAlignment(.leading)
                }
                
                Divider()
                    .background(Theme.border(scheme: colorScheme))
            }
            
            // Result data
            if !result.isEmpty {
                ForEach(result.keys.sorted(), id: \.self) { key in
                    if let value = result[key] {
                        // Create a result section for each key
                        ResultSectionView(key: key, value: value)
                    }
                }
            } else {
                EmptyResultView()
            }
        }
    }
}

// A view for displaying an individual result section
struct ResultSectionView: View {
    let key: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = true
    
    private var isJsonObject: Bool {
        return value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") ||
               value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[")
    }
    
    private var isMultiline: Bool {
        return value.contains("\n")
    }
    
    private var isURL: Bool {
        return value.lowercased().starts(with: "http://") || 
               value.lowercased().starts(with: "https://")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    // Icon based on value type
                    Group {
                        if isJsonObject {
                            Ph.code.duotone
                        } else if isURL {
                            Ph.link.duotone
                        } else if isMultiline {
                            Ph.textT.duotone
                        } else {
                            Ph.textAa.duotone
                        }
                    }
                    .color(Theme.primary(scheme: colorScheme))
                    .frame(width: 20, height: 20)
                    .padding(.trailing, 8)
                    
                    // Section title
                    Text(formatKey(key))
                        .font(Font.iosevkaSubheadline())
                        .fontWeight(.medium)
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                    
                    Spacer()
                    
                    // Expand/collapse indicator
                    Ph.caretDown.duotone
                        .color(Theme.mutedForeground(scheme: colorScheme))
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.card(scheme: colorScheme))
                .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Section content
            if isExpanded {
                VStack(spacing: 0) {
                    if isJsonObject {
                        FormatJsonView(jsonString: value)
                    } else if isURL {
                        URLContentView(url: value)
                    } else {
                        FormattedTextView(text: value)
                    }
                }
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // Format the key for better readability
    private func formatKey(_ key: String) -> String {
        let formattedKey = key
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .lowercased()
            
        // Capitalize first letter
        return formattedKey.prefix(1).uppercased() + formattedKey.dropFirst()
    }
}

// A view for displaying when no results are available
struct EmptyResultView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Ph.info.duotone
                .color(Theme.mutedForeground(scheme: colorScheme))
                .frame(width: 20, height: 20)
                .padding(.trailing, 8)
            
            Text("No result data available")
                .font(Font.iosevkaBody())
                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
            
            Spacer()
        }
        .padding(16)
        .background(Theme.card(scheme: colorScheme))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        ToolResultDetailsView(
            content: "Found information from 3 sources",
            result: [
                "content": "This is a multiline text\nwith line breaks\nto demonstrate formatting",
                "url": "https://example.com/data",
                "json_data": "{\"name\":\"John\",\"age\":30,\"city\":\"New York\"}",
                "status": "Success",
                "count": "42"
            ]
        )
        
        ToolResultDetailsView(
            content: "Empty result example",
            result: [:]
        )
    }
    .padding()
    .background(Color(.systemBackground))
} 
