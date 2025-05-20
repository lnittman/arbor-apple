//
//  ToolDetailsSheet.swift
//  webs-ios
//

import SwiftUI
import PhosphorSwift

struct ToolDetailsSheet: View {
    let message: ChatMessage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        if message.type == .toolCall {
                            // Tool Call Details
                            ToolCallDetailsView(toolName: message.toolName ?? "Unknown Tool", args: message.toolArgs ?? [:])
                        } else if message.type == .toolResult {
                            // Tool Result Details
                            ToolResultDetailsView(content: message.content, result: message.toolResult ?? [:])
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        // Icon based on type
                        Group {
                            if message.type == .toolCall {
                                Ph.wrench.duotone
                            } else {
                                Ph.check.duotone
                            }
                        }
                        .color(Theme.primary(scheme: colorScheme))
                        .frame(width: 20, height: 20)
                        
                        Text(message.type == .toolCall ? "Tool Call" : "Tool Result")
                            .font(Font.iosevkaHeadline())
                            .foregroundColor(Theme.foreground(scheme: colorScheme))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(Font.iosevkaBody())
                            .foregroundColor(Theme.primary(scheme: colorScheme))
                    }
                }
            }
            .background(Theme.background(scheme: colorScheme))
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// Preview not provided since it depends on ChatMessage model 
