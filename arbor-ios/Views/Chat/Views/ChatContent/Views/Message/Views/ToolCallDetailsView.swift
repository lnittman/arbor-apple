//
//  ToolCallDetailsView.swift
//  webs-ios
//

import SwiftUI
import PhosphorSwift

struct ToolCallDetailsView: View {
    let toolName: String
    let args: [String: String]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Ph.wrench.duotone
                        .color(Theme.primary(scheme: colorScheme))
                        .frame(width: 24, height: 24)
                    
                    Text("Tool: \(toolName)")
                        .font(Font.iosevkaHeadline())
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                }
                
                Divider()
                    .background(Theme.border(scheme: colorScheme))
            }
            
            // Arguments section
            if !args.isEmpty {
                ForEach(args.keys.sorted(), id: \.self) { key in
                    if let value = args[key] {
                        ArgumentSectionView(key: key, value: value)
                    }
                }
            } else {
                EmptyArgumentsView()
            }
        }
    }
}

// A view for displaying an individual argument
struct ArgumentSectionView: View {
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

// A view for displaying when no arguments are available
struct EmptyArgumentsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Ph.info.duotone
                .color(Theme.mutedForeground(scheme: colorScheme))
                .frame(width: 20, height: 20)
                .padding(.trailing, 8)
            
            Text("No arguments provided")
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
        ToolCallDetailsView(
            toolName: "web_search",
            args: [
                "query": "quantum physics", 
                "limit": "5",
                "json_options": "{\"format\":\"markdown\",\"maxResults\":10}",
                "description": "This is a\nmultiline\ndescription",
                "url": "https://example.com/search"
            ]
        )
        
        ToolCallDetailsView(
            toolName: "empty_tool",
            args: [:]
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
