import AppKit
import SwiftUI
import Combine

/// AppDelegate handles the NSApplication lifecycle and coordinates the entire app through StateCoordinator
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var stateCoordinator: StateCoordinator?
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupApplication()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cleanupResources()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Prevent app from opening regular window when clicked in dock (if dock icon is enabled)
        return false
    }
    
    // MARK: - Private Methods
    
    private func setupApplication() {
        print("🚀 Starting ClaudeScheduler with StateCoordinator...")
        
        // Initialize StateCoordinator - this coordinates everything
        stateCoordinator = StateCoordinator()
        
        // Setup application appearance
        setupAppearance()
        
        // Setup notification permissions
        setupNotificationPermissions()
        
        // Hide from dock (LSUIElement should handle this, but ensure it's set)
        NSApp.setActivationPolicy(.accessory)
        
        // Start the coordinated application
        stateCoordinator?.startApplication()
        
        // Monitor application health
        setupHealthMonitoring()
        
        print("✅ ClaudeScheduler initialized successfully with StateCoordinator")
    }
    
    private func setupAppearance() {
        // Ensure proper dark/light mode handling
        if let appearance = NSApplication.shared.effectiveAppearance.name {
            print("🎨 Current appearance: \(appearance)")
        }
    }
    
    private func setupNotificationPermissions() {
        NotificationManager.shared.requestPermissions { granted in
            DispatchQueue.main.async {
                if granted {
                    print("🔔 Notification permissions granted")
                } else {
                    print("⚠️ Notification permissions denied")
                }
            }
        }
    }
    
    private func setupHealthMonitoring() {
        guard let coordinator = stateCoordinator else { return }
        
        // Monitor application health status
        coordinator.$isApplicationReady
            .combineLatest(coordinator.$currentState)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReady, state in
                self?.handleApplicationStateChange(isReady: isReady, state: state)
            }
            .store(in: &cancellables)
        
        // Monitor for critical errors
        coordinator.schedulerEngine.$lastError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleCriticalError(error)
            }
            .store(in: &cancellables)
        
        print("🔍 Health monitoring established")
    }
    
    private func handleApplicationStateChange(isReady: Bool, state: SchedulerState) {
        if isReady {
            print("✅ Application ready - State: \(state.displayName)")
        } else {
            print("⏳ Application not ready - State: \(state.displayName)")
        }
    }
    
    private func handleCriticalError(_ error: SchedulerError) {
        print("🚨 Critical error detected: \(error.localizedDescription ?? "Unknown error")")
        
        // Handle specific critical errors
        switch error {
        case .claudeCLINotFound:
            showCriticalErrorAlert(
                title: "Claude CLI Not Found",
                message: "ClaudeScheduler requires Claude CLI to function. Please install it using:\n\nnpm install -g @anthropic-ai/claude-cli",
                isRecoverable: false
            )
        case .recoveryFailed(let attempts):
            showCriticalErrorAlert(
                title: "Recovery Failed",
                message: "ClaudeScheduler has failed to recover after \(attempts) attempts. The application may need to be restarted.",
                isRecoverable: false
            )
        case .systemResourceUnavailable:
            showCriticalErrorAlert(
                title: "System Resources Unavailable",
                message: "Required system resources are not available. Please check system permissions and try again.",
                isRecoverable: true
            )
        default:
            // Handle other errors silently or with less intrusive notifications
            break
        }
    }
    
    private func showCriticalErrorAlert(title: String, message: String, isRecoverable: Bool) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .critical
            
            if isRecoverable {
                alert.addButton(withTitle: "Retry")
                alert.addButton(withTitle: "Quit")
                
                let response = alert.runModal()
                if response == .alertSecondButtonReturn {
                    NSApplication.shared.terminate(nil)
                } else {
                    // Attempt recovery through StateCoordinator
                    self.stateCoordinator?.forceSynchronizationCheck()
                }
            } else {
                alert.addButton(withTitle: "Quit")
                alert.runModal()
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    private func cleanupResources() {
        print("🧹 Starting application cleanup...")
        
        // Shutdown through StateCoordinator for proper coordination
        stateCoordinator?.shutdown()
        stateCoordinator = nil
        
        // Clean up subscriptions
        cancellables.removeAll()
        
        print("🧹 ClaudeScheduler cleanup completed")
    }
    
    // MARK: - Debug Support
    
    /// Prints comprehensive application status for debugging
    func printApplicationStatus() {
        guard let coordinator = stateCoordinator else {
            print("❌ StateCoordinator not available")
            return
        }
        
        print("📊 Application Status:")
        print(coordinator.debugStatus)
        print("📊 Health Status: \(coordinator.applicationHealthStatus.description)")
    }
}