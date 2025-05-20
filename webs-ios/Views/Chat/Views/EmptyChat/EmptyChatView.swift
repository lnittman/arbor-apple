import SwiftUI
import PhosphorSwift

struct EmptyChatView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var viewModel: ChatViewModel
    let geometry: GeometryProxy
    
    var body: some View {
        // Just a blank background
        Theme.background(scheme: colorScheme)
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                print("📋 EmptyChatView: onAppear triggered")
                // When EmptyChatView appears, tell the view model to focus the command bar
                // Try multiple times with increasing delays to ensure it works
                focusCommandBar()
            }
    }
    
    private func focusCommandBar() {
        print("📋 EmptyChatView: focusCommandBar called")
        
        // First immediate attempt
        print("📋 EmptyChatView: First focus attempt")
        viewModel.commandBarFocused = true
        print("📋 EmptyChatView: After first attempt, viewModel.commandBarFocused = \(viewModel.commandBarFocused)")
        
        // Try again after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("📋 EmptyChatView: Second focus attempt (0.1s delay)")
            viewModel.commandBarFocused = true
            print("📋 EmptyChatView: After second attempt, viewModel.commandBarFocused = \(viewModel.commandBarFocused)")
            
            // And again with a longer delay in case the view is still being set up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("📋 EmptyChatView: Third focus attempt (0.3s delay)")
                viewModel.commandBarFocused = true
                print("📋 EmptyChatView: After third attempt, viewModel.commandBarFocused = \(viewModel.commandBarFocused)")
                
                // One final attempt with even longer delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    print("📋 EmptyChatView: Fourth focus attempt (0.6s delay)")
                    viewModel.commandBarFocused = true
                    print("📋 EmptyChatView: After fourth attempt, viewModel.commandBarFocused = \(viewModel.commandBarFocused)")
                }
            }
        }
    }
}

#Preview {
    GeometryReader { geometry in
        EmptyChatView(geometry: geometry)
            .environmentObject(ChatViewModel())
    }
} 
