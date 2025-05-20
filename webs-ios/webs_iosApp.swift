//
//  webs_iosApp.swift
//  webs-ios
//
//  Created by Luke Nittmann on 3/31/25.
//

import SwiftUI
import Clerk
import Network

@main
struct webs_iosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var clerk = Clerk.shared
    @State private var isOnline = true // Assume online initially
    @State private var isCheckingConnectivity = true // Track initial check
    @AppStorage("colorScheme") private var userColorScheme: String = "system"
    
    // Network monitor
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "AppNetworkMonitor")
    
    init() {
        startNetworkMonitoring()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Theme-aware background applied immediately
                getBackgroundColor()
                    .ignoresSafeArea()
                
                // Main view conditionals with simplified logic
                if isCheckingConnectivity {
                    // Initial loading state
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: getProgressViewColor()))
                } else if !isOnline {
                    // Offline state
                    OfflineView { checkConnectivity() }
                } else if !clerk.isLoaded {
                    // Loading Clerk state
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: getProgressViewColor()))
                        .onAppear {
                            loadClerk()
                        }
                } else {
                    // Fully loaded state
                    ContentView()
                }
            }
            .environment(clerk)
            .preferredColorScheme(getPreferredColorScheme())
            .task {
                // Failsafe: Force complete the check after 1 second
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if isCheckingConnectivity {
                    print("⚠️ Network check timeout - forcing completion")
                    isCheckingConnectivity = false
                }
            }
        }
    }
    
    // Start network monitoring immediately
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            let newStatus = path.status == .satisfied
            DispatchQueue.main.async {
                // Update online status first
                self.isOnline = newStatus
                
                // Then mark check as complete if it's still ongoing
                if self.isCheckingConnectivity {
                    print("🌐 Initial network check complete: isOnline = \(newStatus)")
                    self.isCheckingConnectivity = false
                } else {
                    print("🌐 Network status changed: isOnline = \(newStatus)")
                }
            }
        }
        // Start the monitor; the handler will be called with the initial status
        monitor.start(queue: monitorQueue)
        print("🌐 Network monitoring started")
    }
    
    // Load Clerk separately from the view hierarchy
    private func loadClerk() {
        Task {
            print("🔐 Configuring Clerk...")
            clerk.configure(publishableKey: "pk_test_Y2hlZXJmdWwtZ29vc2UtNDAuY2xlcmsuYWNjb3VudHMuZGV2JA")
            do {
                try await clerk.load()
                print("✅ Clerk loaded successfully.")
            } catch {
                print("❌ Error loading Clerk: \(error)")
            }
        }
    }
    
    // Check network connectivity manually (for retry button)
    private func checkConnectivity() {
        print("🔄 Manual connectivity check initiated")
        Task {
            let path = monitor.currentPath
            let newStatus = path.status == .satisfied
            await MainActor.run {
                self.isOnline = newStatus
                print("🌐 Manual check result: isOnline = \(self.isOnline)")
            }
        }
    }
    
    // Get background color based on theme
    private func getBackgroundColor() -> Color {
        switch getPreferredColorScheme() {
        case .dark:
            return Theme.lightBackground.resolve(in: .dark)
        case .light:
            return Theme.lightBackground.resolve(in: .light)
        default: // System
            // Use a neutral color during initial check before system scheme is known
            return Color(.systemBackground)
        }
    }
    
    // Get progress view color based on theme
    private func getProgressViewColor() -> Color {
        getPreferredColorScheme() == .dark ? .white : .black
    }
    
    // Get color scheme from UserDefaults
    private func getPreferredColorScheme() -> ColorScheme? {
        switch userColorScheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // System default
        }
    }
}

// AppDelegate to handle font registration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Log for debugging
        print("App launched, checking font registration...")
        
        // Initialize AgentsService with ngrok URL
        let ngrokUrl = "https://f130bbe682f0.ngrok.app"
        UserDefaults.standard.set(ngrokUrl, forKey: "AgentsServiceBaseURL")
        
        return true
    }
    
    // Handle OAuth URL callbacks through AppDelegate
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Let Clerk handle the URL
        return true
    }
} 
