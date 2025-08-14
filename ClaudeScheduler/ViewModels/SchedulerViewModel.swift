import SwiftUI
import Combine
import Foundation

/// Protocol defining the interface for SchedulerViewModel
/// This allows for easy testing and dependency injection
protocol SchedulerViewModel: ObservableObject {
    var state: SchedulerState { get }
    var progress: Double { get }
    var timeRemainingFormatted: String { get }
    var nextExecutionFormatted: String { get }
    var sessionsToday: Int { get }
    var batteryImpact: String { get }
    
    func startSession()
    func pauseSession()
    func resumeSession()
    func stopSession()
    func retryExecution()
    func showLogs()
    func showPreferences()
    func showHistory()
    func showHelp()
    func quitApplication()
}

/// Main ViewModel for the scheduler interface
/// Bridges between the UI layer and the SchedulerEngine service
class SchedulerViewModelImpl: ObservableObject, SchedulerViewModel {
    
    // MARK: - Published Properties
    
    @Published private(set) var state: SchedulerState = .idle
    @Published private(set) var progress: Double = 0.0
    @Published private(set) var timeRemaining: TimeInterval = 0
    @Published private(set) var sessionsToday: Int = 0
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastError: SchedulerError?
    
    // MARK: - Dependencies
    
    private let schedulerEngine: SchedulerEngine
    private let notificationManager = NotificationManager.shared
    private let processManager = ProcessManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var timeRemainingFormatted: String {
        return timeRemaining.formatted()
    }
    
    var nextExecutionFormatted: String {
        guard let nextExecution = schedulerEngine.nextCommandExecutionTime else {
            return "Not scheduled"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        return "Today at \(formatter.string(from: nextExecution))"
    }
    
    var batteryImpact: String {
        return schedulerEngine.batteryImpactDescription
    }
    
    // MARK: - Initialization
    
    init(schedulerEngine: SchedulerEngine) {
        self.schedulerEngine = schedulerEngine
        setupBindings()
        setupNotificationObservers()
        
        print("📱 SchedulerViewModel initialized")
    }
    
    deinit {
        cancellables.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public API
    
    func startSession() {
        guard !isLoading else { return }
        
        withAnimation(ClaudeAnimation.stateTransition) {
            isLoading = true
        }
        
        Task {
            // Check if Claude CLI is available
            let validation = await processManager.validateClaudeInstallation()
            
            await MainActor.run {
                if validation.isValid {
                    schedulerEngine.startSession()
                } else {
                    lastError = .claudeCLINotFound
                }
                
                withAnimation(ClaudeAnimation.stateTransition) {
                    isLoading = false
                }
            }
        }
    }
    
    func pauseSession() {
        guard state.canPause else { return }
        
        withAnimation(ClaudeAnimation.stateTransition) {
            schedulerEngine.pauseSession()
        }
    }
    
    func resumeSession() {
        guard state.canResume else { return }
        
        withAnimation(ClaudeAnimation.stateTransition) {
            schedulerEngine.resumeSession()
        }
    }
    
    func stopSession() {
        guard state.canStop else { return }
        
        // Show confirmation dialog for running sessions
        if state == .running {
            showStopConfirmation()
        } else {
            confirmStop()
        }
    }
    
    func retryExecution() {
        guard state == .error else { return }
        
        withAnimation(ClaudeAnimation.stateTransition) {
            schedulerEngine.retryLastOperation()
            lastError = nil
        }
    }
    
    func showLogs() {
        // TODO: Implement logs window
        print("📋 Show logs requested")
    }
    
    func showPreferences() {
        // TODO: Implement preferences window
        print("⚙️ Show preferences requested")
        
        // For now, open a simple settings window
        openSettingsWindow()
    }
    
    func showHistory() {
        // TODO: Implement history window
        print("📊 Show history requested")
    }
    
    func showHelp() {
        // Open help documentation
        if let url = URL(string: "https://github.com/anthropic-ai/claude-cli") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func quitApplication() {
        // Show confirmation dialog
        showQuitConfirmation()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind to scheduler engine state changes
        schedulerEngine.$currentState
            .receive(on: DispatchQueue.main)
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
        
        schedulerEngine.$progress
            .receive(on: DispatchQueue.main)
            .assign(to: \.progress, on: self)
            .store(in: &cancellables)
        
        schedulerEngine.$timeRemaining
            .receive(on: DispatchQueue.main)
            .assign(to: \.timeRemaining, on: self)
            .store(in: &cancellables)
        
        schedulerEngine.$lastError
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastError, on: self)
            .store(in: &cancellables)
        
        // Update sessions today count (simplified for now)
        Publishers.CombineLatest(
            schedulerEngine.$currentState,
            schedulerEngine.$currentSession
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] state, session in
            // TODO: Implement proper session counting
            if state == .completed {
                self?.sessionsToday += 1
            }
        }
        .store(in: &cancellables)
    }
    
    private func setupNotificationObservers() {
        // Listen for notification actions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStartNewSession),
            name: .startNewSession,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRetryOperation),
            name: .retryFailedOperation,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResumeSession),
            name: .resumeSession,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowSettings),
            name: .showSettings,
            object: nil
        )
    }
    
    @objc private func handleStartNewSession() {
        DispatchQueue.main.async { [weak self] in
            self?.startSession()
        }
    }
    
    @objc private func handleRetryOperation() {
        DispatchQueue.main.async { [weak self] in
            self?.retryExecution()
        }
    }
    
    @objc private func handleResumeSession() {
        DispatchQueue.main.async { [weak self] in
            self?.resumeSession()
        }
    }
    
    @objc private func handleShowSettings() {
        DispatchQueue.main.async { [weak self] in
            self?.showPreferences()
        }
    }
    
    private func showStopConfirmation() {
        let alert = NSAlert()
        alert.messageText = "Stop Current Session?"
        alert.informativeText = "This will stop the current session and lose any progress. Are you sure?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Stop Session")
        alert.addButton(withTitle: "Cancel")
        
        alert.beginSheetModal(for: NSApp.keyWindow) { [weak self] response in
            if response == .alertFirstButtonReturn {
                self?.confirmStop()
            }
        }
    }
    
    private func confirmStop() {
        withAnimation(ClaudeAnimation.stateTransition) {
            schedulerEngine.stopSession()
        }
    }
    
    private func showQuitConfirmation() {
        let alert = NSAlert()
        alert.messageText = "Quit ClaudeScheduler?"
        alert.informativeText = state == .running ? 
            "A session is currently running. Quitting will stop the session." :
            "Are you sure you want to quit ClaudeScheduler?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        
        alert.beginSheetModal(for: NSApp.keyWindow) { response in
            if response == .alertFirstButtonReturn {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    private func openSettingsWindow() {
        // Create and show settings window
        let settingsViewModel = SettingsViewModelImpl(schedulerEngine: schedulerEngine)
        let settingsView = SettingsWindow(settings: settingsViewModel)
        
        let hostingController = NSHostingController(rootView: settingsView)
        hostingController.window?.title = "ClaudeScheduler Settings"
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "ClaudeScheduler Settings"
        window.setContentSize(NSSize(width: 480, height: 400))
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // Store window reference to prevent deallocation
        // In a real implementation, you'd manage this properly
        objc_setAssociatedObject(self, "settingsWindow", window, .OBJC_ASSOCIATION_RETAIN)
    }
}

// MARK: - Extensions

extension SchedulerViewModelImpl {
    
    /// Returns localized error description for UI display
    var currentErrorDescription: String? {
        return lastError?.localizedDescription
    }
    
    /// Returns recovery suggestion for current error
    var errorRecoverySuggestion: String? {
        return lastError?.recoverySuggestion
    }
    
    /// Whether the current error can be automatically recovered from
    var canAutoRecover: Bool {
        return lastError?.canAutoRecover ?? false
    }
    
    /// Whether there are any active timers running
    var hasActiveTimers: Bool {
        return state == .running
    }
    
    /// Progress as a percentage string for display
    var progressPercentage: String {
        return "\(Int(progress * 100))%"
    }
    
    /// Whether the session can be started (not loading and in appropriate state)
    var canStartSession: Bool {
        return !isLoading && state.canStartSession
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockSchedulerViewModel: ObservableObject, SchedulerViewModel {
    @Published var state: SchedulerState = .idle
    @Published var progress: Double = 0.45
    
    let timeRemainingFormatted = "2h 34m 12s"
    let nextExecutionFormatted = "Today at 3:45 PM"
    let sessionsToday = 3
    let batteryImpact = "Low"
    
    func startSession() { state = .running }
    func pauseSession() { state = .paused }
    func resumeSession() { state = .running }
    func stopSession() { state = .idle }
    func retryExecution() { state = .running }
    func showLogs() { print("Show logs") }
    func showPreferences() { print("Show preferences") }
    func showHistory() { print("Show history") }
    func showHelp() { print("Show help") }
    func quitApplication() { print("Quit app") }
}
#endif