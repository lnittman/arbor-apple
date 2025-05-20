//
//  UserMessageBubbleView.swift
//  webs-ios
//
//  Created by Luke Nittmann on 4/6/25.
//

import SwiftUI

struct UserMessageBubbleView: View {
    let content: String
    @Environment(\.colorScheme) private var colorScheme
    
    private var processedContent: String {
        return content.replacingOccurrences(of: "\\n", with: "\n")
    }
    
    var body: some View {
        HStack {
            Spacer()
            
            Text(processedContent)
                .font(Font.iosevkaBody())
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.primary(scheme: colorScheme))
                )
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .trailing)
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    VStack(spacing: 16) {
        UserMessageBubbleView(content: "Hello, this is a simple message")
        
        UserMessageBubbleView(content: "This message has\na newline character")
        
        UserMessageBubbleView(content: "This message has\\na raw newline escape sequence")
    }
    .padding()
}
