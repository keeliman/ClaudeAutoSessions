import SwiftUI
import AppKit

/// Main SwiftUI App for ClaudeScheduler
/// LSUIElement = true means this is a menu bar app without dock icon
@main
struct ClaudeSchedulerApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // WindowGroup is required but won't show since LSUIElement = true
        WindowGroup {
            ContentView()
        }
    }
}

/// Empty content view since we're a menu bar app
struct ContentView: View {
    var body: some View {
        VStack {
            Text("ClaudeScheduler is running in the menu bar")
                .font(.headline)
            Text("Click the icon in your menu bar to interact with the app")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

#if DEBUG
#Preview {
    ContentView()
}
#endif