import SwiftUI

// Main entry point of the app
// This is where the app starts running
@main
struct BubblePopGameApp: App {
    
    // Create a shared ViewModel for managing game data
    @StateObject private var gameViewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Pass the ViewModel to all child views
                .environmentObject(gameViewModel)
        }
    }
}