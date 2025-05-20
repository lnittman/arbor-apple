//
//  ErrorMessageBubbleView.swift
//  webs-ios
//
//  Created by Luke Nittmann on 4/6/25.
//

import SwiftUI

struct ErrorMessageBubbleView: View {
    let content: String
    @Environment(\.colorScheme) private var colorScheme
    
    private var processedContent: String {
        return content.replacingOccurrences(of: "\\n", with: "\n")
    }
    
    var body: some View {
        Text(processedContent)
            .font(Font.iosevkaBody())
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.9))
            )
            .padding(.horizontal, 8)
    }
}

#Preview {
    VStack(spacing: 16) {
        ErrorMessageBubbleView(content: "An error occurred.")
        
        ErrorMessageBubbleView(content: "An error occurred.\nWith multiple lines\nof information.")
        
        ErrorMessageBubbleView(content: "An error occurred.\\nWith escaped newlines\\nin the text.")
    }
    .padding()
}
