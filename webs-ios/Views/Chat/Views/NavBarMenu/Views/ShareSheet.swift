import SwiftUI
import PhosphorSwift

struct ShareSheet: View {
    let chatId: String
    let chatTitle: String
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    // State for sharing options
    @State private var shareType: ShareType = .link
    @State private var isGeneratingImage = false
    @State private var sharedImage: UIImage? = nil
    
    enum ShareType {
        case link, image
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Content
                VStack(spacing: 20) {
                    // Share type selector
                    Picker("Share Type", selection: $shareType) {
                        Text("link").tag(ShareType.link)
                        Text("image").tag(ShareType.image)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Content based on selected share type
                    if shareType == .link {
                        linkShareView
                    } else {
                        imageShareView
                    }
                    
                    Spacer()
                }
                
                // Share button
                Button {
                    if shareType == .link {
                        shareLinkAction()
                    } else {
                        shareImageAction()
                    }
                } label: {
                    HStack {
                        Ph.share.duotone
                            .color(.white)
                            .frame(width: 20, height: 20)
                        
                        Text("share \(shareType == .link ? "link" : "image")")
                            .font(Font.iosevkaBody())
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 100)
                            .fill(Theme.primary(scheme: colorScheme))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("share link to chat")
                        .font(Font.iosevkaHeadline())
                        .foregroundColor(Theme.foreground(scheme: colorScheme))
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("cancel")
                            .font(Font.iosevkaBody())
                            .foregroundColor(Theme.primary(scheme: colorScheme))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if shareType == .link {
                            UIPasteboard.general.string = generateShareLink()
                            showCopiedToast()
                        }
                    } label: {
                        Text("copy")
                            .font(Font.iosevkaBody())
                            .foregroundColor(Theme.primary(scheme: colorScheme))
                    }
                }
            }
            .background(Theme.background(scheme: colorScheme))
        }
        .overlay {
            if isGeneratingImage {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("generating image...")
                                .font(Font.iosevkaBody())
                                .foregroundColor(.white)
                                .padding(.top, 16)
                        }
                    )
            }
        }
    }
    
    // Link sharing view
    private var linkShareView: some View {
        VStack(spacing: 16) {
            // Link preview card
            VStack(spacing: 12) {
                // App logo and name
                HStack {
                    Circle()
                        .fill(Theme.primary(scheme: colorScheme))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("W")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Text("Webs")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("Anonymous • Apr 9, 2025")
                        .font(Font.iosevkaCaption())
                        .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                }
                
                // Divider
                Rectangle()
                    .fill(Theme.border(scheme: colorScheme))
                    .frame(height: 0.5)
                
                // Chat title
                Text(chatTitle)
                    .font(Font.iosevkaSubheadline())
                    .foregroundColor(Theme.foreground(scheme: colorScheme))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Some preview text
                Text("Messages sent or received after sharing your link won't be shared. Anyone with the URL will be able to view your shared chat.")
                    .font(Font.iosevkaCaption())
                    .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.card(scheme: colorScheme))
            )
            .padding(.horizontal, 16)
            
            // Warning text
            HStack {
                Ph.info.duotone
                    .color(Theme.mutedForeground(scheme: colorScheme))
                    .frame(width: 16, height: 16)
                
                Text("Your custom instructions won't be shared with viewers.")
                    .font(Font.iosevkaCaption())
                    .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
            }
            .padding(.horizontal, 16)
        }
    }
    
    // Image sharing view
    private var imageShareView: some View {
        VStack(spacing: 16) {
            // Image preview card
            ZStack {
                if let sharedImage = sharedImage {
                    Image(uiImage: sharedImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                } else {
                    // Placeholder
                    VStack(spacing: 16) {
                        Ph.image.duotone
                            .color(Theme.mutedForeground(scheme: colorScheme))
                            .frame(width: 40, height: 40)
                        
                        Text("generated image will appear here")
                            .font(Font.iosevkaCaption())
                            .foregroundColor(Theme.mutedForeground(scheme: colorScheme))
                        
                        // Generate button
                        Button {
                            generateImage()
                        } label: {
                            Text("generate image")
                                .font(Font.iosevkaBody())
                                .foregroundColor(Theme.primary(scheme: colorScheme))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.primary(scheme: colorScheme), lineWidth: 1)
                                )
                        }
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.card(scheme: colorScheme))
                    )
                }
            }
            .padding(.horizontal, 16)
            
            // Image options - only show if we have an image
            if sharedImage != nil {
                HStack(spacing: 12) {
                    Button {
                        regenerateImage()
                    } label: {
                        Text("regenerate")
                            .font(Font.iosevkaBody())
                            .foregroundColor(Theme.primary(scheme: colorScheme))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.primary(scheme: colorScheme), lineWidth: 1)
                            )
                    }
                    
                    Button {
                        if let image = sharedImage {
                            UIPasteboard.general.image = image
                            showCopiedToast()
                        }
                    } label: {
                        Text("copy")
                            .font(Font.iosevkaBody())
                            .foregroundColor(Theme.primary(scheme: colorScheme))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.primary(scheme: colorScheme), lineWidth: 1)
                            )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    // MARK: - Actions
    
    private func dismiss() {
        isPresented = false
    }
    
    private func generateShareLink() -> String {
        // In a real app, this would generate a proper sharing link
        return "https://app.webs.xyz/share/\(chatId)"
    }
    
    private func shareLinkAction() {
        let shareLink = generateShareLink()
        let activityVC = UIActivityViewController(
            activityItems: [shareLink],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func generateImage() {
        // In a real app, this would generate an actual image of the chat
        isGeneratingImage = true
        
        // Simulate image generation with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Create a placeholder image (you'd replace this with actual chat image generation)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 750, height: 1000))
            let image = renderer.image { ctx in
                // Background
                UIColor(Theme.card(scheme: colorScheme)).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 750, height: 1000))
                
                // Header
                UIColor(Theme.primary(scheme: colorScheme)).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 750, height: 80))
                
                let titleText = "Webs: \(chatTitle)" as NSString
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                titleText.draw(in: CGRect(x: 30, y: 25, width: 690, height: 40), withAttributes: titleAttributes)
                
                // Simulate chat content
                let contentText = "This is a shared chat from Webs. The content would contain the actual conversation text here." as NSString
                let contentAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18),
                    .foregroundColor: UIColor(Theme.foreground(scheme: colorScheme))
                ]
                contentText.draw(in: CGRect(x: 30, y: 100, width: 690, height: 800), withAttributes: contentAttributes)
            }
            
            self.sharedImage = image
            self.isGeneratingImage = false
        }
    }
    
    private func regenerateImage() {
        // Clear the current image and generate a new one
        sharedImage = nil
        generateImage()
    }
    
    private func shareImageAction() {
        guard let image = sharedImage else {
            // Generate image first if it doesn't exist
            generateImage()
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func showCopiedToast() {
        // In a real implementation, this would use the app's toast system
        HapticManager.shared.mediumImpact()
        // For now, just print to console
        print("Copied to clipboard")
    }
} 
