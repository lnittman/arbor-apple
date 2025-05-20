import SwiftUI

struct ThinkingView: View {
    let elapsedSeconds: Int
    
    var body: some View {
        HStack {
            // Blue thinking bubble similar to Grok
            HStack {
                // Circular progress spinner
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#37A1FF")))
                    .scaleEffect(0.8)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Thinking for \(elapsedSeconds) seconds")
                        .font(.headline)
                        .foregroundColor(Color.black.opacity(0.8))
                    
                    Text("Tap to read my mind")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // Right chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.gray)
                    .padding(.trailing, 8)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#E0F3FF"))
            )
            .frame(maxWidth: .infinity)
        }
    }
}
