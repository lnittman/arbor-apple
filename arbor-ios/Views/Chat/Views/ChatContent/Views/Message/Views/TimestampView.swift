//
//  TimestampView.swift
//  webs-ios
//
//  Created by Luke Nittmann on 4/6/25.
//

import SwiftUI

struct TimeStampView: View {
    let messageType: ChatMessage.MessageType
    let timestamp: Date
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if messageType == .user {
                Spacer()
            }
            
            Text(formattedTime)
                .font(Font.iosevkaCaption())
                .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                .padding(.horizontal, 4)
            
            if messageType == .ai {
                Spacer()
            }
        }
        .padding(.horizontal, 12)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
