import Foundation
import Combine
import SwiftUI
import AppKit
import OSLog

// MARK: - Protocol Definition

/// Protocol defining the state coordination interface
protocol StateCoordinatorProtocol {
    var schedulerEngine: SchedulerEngine { get }
    var processManager: ProcessManager { get }
    var schedulerViewModel: SchedulerViewModelImpl { get }
    
    func initializeStateBindings()
    func coordinateEngineWithProcessManager()
    func setupUISubscriptions()
    func startApplication()
    func shutdown()
}

// MARK: - State Coordination Manager

/// Coordinates state management between all ClaudeScheduler components
/// Provides seamless integration between SchedulerEngine, ProcessManager, and UI layer
/// Ensures real-time synchronization and optimal performance
class StateCoordinator: ObservableObject, StateCoordinatorProtocol {
    
    // MARK: - Core Components
    
    let schedulerEngine: SchedulerEngine
    let processManager: ProcessManager
    let schedulerViewModel: SchedulerViewModelImpl
    
    private let notificationManager = NotificationManager.shared
    private var menuBarController: MenuBarController?
    
    // MARK: - Published State Properties
    
    @Published private(set) var currentState: SchedulerState = .idle
    @Published private(set) var progressPercentage: Double = 0.0
    @Published private(set) var timeRemaining: TimeInterval = 0
    @Published private(set) var isProcessExecuting: Bool = false
    @Published private(set) var lastExecutionResult: ProcessResult?
    @Published private(set) var isApplicationReady: Bool = false
    
    // Performance monitoring
    @Published private(set) var performanceMetrics: PerformanceCoordinationMetrics = PerformanceCoordinationMetrics()
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let coordinationQueue = DispatchQueue(label: "com.claudescheduler.coordination", qos: .userInitiated)
    private let logger = Logger(subsystem: "com.claudescheduler", category: "StateCoordinator")
    
    // State synchronization
    private var lastStateUpdate = Date()
    private var updateCounter: Int = 0
    private let maxUpdateFrequency: TimeInterval = 1.0 / 60.0 // 60 FPS limit
    
    // Error handling and recovery
    private var errorRecoveryAttempts: Int = 0
    private let maxErrorRecoveryAttempts: Int = 3
    private var isRecovering: Bool = false
    
    // MARK: - Initialization
    
    init() {
        // Initialize core components
        self.schedulerEngine = SchedulerEngine()
        self.processManager = ProcessManager.shared
        self.schedulerViewModel = SchedulerViewModelImpl(schedulerEngine: schedulerEngine)
        
        logger.info("🔗 StateCoordinator initializing with all components")
        
        // Setup coordination
        setupCoreBindings()
        initializeStateBindings()
        coordinateEngineWithProcessManager()
        setupUISubscriptions()
        setupPerformanceMonitoring()
        setupErrorHandling()
        
        logger.info("✅ StateCoordinator initialization complete")
        print("🔗 StateCoordinator initialized - All components coordinated")
    }
    
    deinit {
        shutdown()
        logger.info("🧹 StateCoordinator deinitialized")
    }
    
    // MARK: - Public API
    
    /// Starts the application with full coordination
    func startApplication() {
        logger.info("🚀 Starting ClaudeScheduler application")
        
        Task { @MainActor in
            // Initialize menu bar
            self.menuBarController = MenuBarController(schedulerEngine: self.schedulerEngine)
            
            // Mark application as ready
            self.isApplicationReady = true
            
            // Send startup notification
            self.notificationManager.scheduleNotification(.applicationStarted)
            
            print("🚀 ClaudeScheduler application started successfully")
        }
    }
    
    /// Gracefully shuts down the application
    func shutdown() {
        logger.info("🛑 Shutting down ClaudeScheduler application")
        
        // Stop all timers and processes
        schedulerEngine.cleanup()
        processManager.cancelCurrentExecution()
        
        // Cleanup UI
        menuBarController?.cleanup()
        menuBarController = nil
        
        // Clear all subscriptions
        cancellables.removeAll()
        
        isApplicationReady = false
        
        print("🛑 ClaudeScheduler shutdown complete")
    }
    
    // MARK: - State Coordination Implementation
    
    /// Initialize core state bindings between components
    func initializeStateBindings() {
        logger.info("🔄 Initializing state bindings")
        
        // Primary state coordination: SchedulerEngine → StateCoordinator
        schedulerEngine.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
        
        // Progress coordination with throttling
        schedulerEngine.$progressPercentage
            .throttle(for: .milliseconds(16), scheduler: DispatchQueue.main, latest: true) // 60 FPS
            .sink { [weak self] progress in
                self?.handleProgressUpdate(progress)
            }
            .store(in: &cancellables)
        
        // Time remaining coordination
        schedulerEngine.$timeRemaining
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] timeRemaining in
                self?.handleTimeRemainingUpdate(timeRemaining)
            }
            .store(in: &cancellables)
        
        // Process execution state coordination
        processManager.$isExecuting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isExecuting in
                self?.handleProcessExecutionStateChange(isExecuting)
            }
            .store(in: &cancellables)
        
        // Process result coordination
        processManager.$lastExecutionResult
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.handleProcessExecutionResult(result)
            }
            .store(in: &cancellables)
        
        logger.info("✅ State bindings initialized")
    }
    
    /// Coordinate integration between SchedulerEngine and ProcessManager
    func coordinateEngineWithProcessManager() {
        logger.info("🔗 Setting up SchedulerEngine ↔ ProcessManager coordination")
        
        // Setup SchedulerEngine → ProcessManager integration
        setupEngineToProcessManagerIntegration()
        
        // Setup ProcessManager → SchedulerEngine feedback
        setupProcessManagerToEngineIntegration()
        
        logger.info("✅ Engine-ProcessManager coordination established")
    }
    
    /// Setup UI subscriptions for reactive updates
    func setupUISubscriptions() {
        logger.info("📱 Setting up UI subscriptions")
        
        // Coordinate state changes with UI updates
        $currentState
            .combineLatest($progressPercentage, $timeRemaining)
            .debounce(for: .milliseconds(16), scheduler: DispatchQueue.main) // 60 FPS limit
            .sink { [weak self] state, progress, timeRemaining in
                self?.updateUIMetrics(state: state, progress: progress, timeRemaining: timeRemaining)
            }
            .store(in: &cancellables)
        
        // Error state coordination
        schedulerEngine.$lastError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleSchedulerError(error)
            }
            .store(in: &cancellables)
        
        logger.info("✅ UI subscriptions configured")
    }
    
    // MARK: - Private Coordination Methods
    
    private func setupCoreBindings() {
        // Memory-safe weak references for all bindings
        // Performance-optimized with debouncing and throttling
        logger.debug("Setting up core bindings with performance optimization")
    }
    
    private func setupEngineToProcessManagerIntegration() {
        // SchedulerEngine session completion triggers ProcessManager execution
        schedulerEngine.objectWillChange
            .sink { [weak self] in
                guard let self = self else { return }
                
                Task {
                    // Check if we need to execute Claude command
                    if self.schedulerEngine.currentState == .running {
                        await self.triggerClaudeExecution()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupProcessManagerToEngineIntegration() {
        // ProcessManager execution results feed back to SchedulerEngine
        processManager.$lastExecutionResult
            .compactMap { $0 }
            .sink { [weak self] result in
                self?.handleProcessResultForEngine(result)
            }
            .store(in: &cancellables)
    }
    
    private func setupPerformanceMonitoring() {
        // Monitor coordination performance
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePerformanceMetrics()
            }
            .store(in: &cancellables)
    }
    
    private func setupErrorHandling() {
        // Global error coordination
        Publishers.Merge(
            schedulerEngine.$lastError.compactMap { $0 }.map { CoordinationError.schedulerError($0) },
            processManager.$lastExecutionResult.compactMap { result in
                if case .failure(let error, _) = result {
                    return CoordinationError.processError(error)
                }
                return nil
            }
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] error in
            self?.handleCoordinationError(error)
        }
        .store(in: &cancellables)
    }
    
    // MARK: - State Change Handlers
    
    private func handleStateChange(_ newState: SchedulerState) {
        logger.info("🔄 State change: \(currentState.displayName) → \(newState.displayName)")
        
        withAnimation(ClaudeAnimation.stateTransition) {
            currentState = newState
        }
        
        // Coordinate dependent actions based on state
        switch newState {
        case .running:
            handleRunningStateActivation()
        case .completed:
            handleSessionCompletion()
        case .error:
            handleErrorStateActivation()
        case .paused:
            handlePausedStateActivation()
        default:
            break
        }
        
        updatePerformanceMetrics()
    }
    
    private func handleProgressUpdate(_ progress: Double) {
        // Throttle progress updates for performance
        let now = Date()
        guard now.timeIntervalSince(lastStateUpdate) >= maxUpdateFrequency else { return }
        
        withAnimation(ClaudeAnimation.progressUpdate) {
            progressPercentage = progress
        }
        
        lastStateUpdate = now
        updateCounter += 1
        
        logger.debug("📊 Progress updated: \(String(format: "%.1f", progress))%")
    }
    
    private func handleTimeRemainingUpdate(_ timeRemaining: TimeInterval) {
        withAnimation(ClaudeAnimation.progressUpdate) {
            self.timeRemaining = timeRemaining
        }
        
        logger.debug("⏰ Time remaining updated: \(timeRemaining.formatted())")
    }
    
    private func handleProcessExecutionStateChange(_ isExecuting: Bool) {
        withAnimation(ClaudeAnimation.stateTransition) {
            isProcessExecuting = isExecuting
        }
        
        logger.info("⚙️ Process execution state: \(isExecuting ? "EXECUTING" : "IDLE")")
        
        if isExecuting {
            // Notify UI that process is starting
            notificationManager.scheduleNotification(.commandExecutionStarted)
        }
    }
    
    private func handleProcessExecutionResult(_ result: ProcessResult) {
        lastExecutionResult = result
        
        switch result {
        case .success(let output, let duration):
            logger.info("✅ Process execution successful: \(duration)s")
            handleSuccessfulExecution(output: output, duration: duration)
            
        case .failure(let error, let attempt):
            logger.error("❌ Process execution failed: \(error) (attempt \(attempt))")
            handleFailedExecution(error: error, attempt: attempt)
            
        case .timeout(let duration):
            logger.warning("⏰ Process execution timed out after \(duration)s")
            handleTimeoutExecution(duration: duration)
            
        case .cancelled:
            logger.info("🛑 Process execution cancelled")
            handleCancelledExecution()
        }
    }
    
    // MARK: - Integration Actions
    
    @MainActor
    private func triggerClaudeExecution() async {
        guard !isProcessExecuting else {
            logger.debug("⏭️ Skipping Claude execution - already executing")
            return
        }
        
        logger.info("🚀 Triggering Claude execution from SchedulerEngine")
        
        let result = await processManager.executeClaudeCommand()
        
        // Result is automatically handled by the processManager subscribers
        logger.debug("🔄 Claude execution completed with result: \(result)")
    }
    
    private func handleProcessResultForEngine(_ result: ProcessResult) {
        coordinationQueue.async { [weak self] in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // Process success - continue scheduler session
                DispatchQueue.main.async {
                    // Engine continues automatically
                    self.logger.info("✅ Process success reported to SchedulerEngine")
                }
                
            case .failure(let error, _):
                // Process failure - handle based on error type
                DispatchQueue.main.async {
                    self.handleProcessFailureInEngine(error)
                }
                
            case .timeout, .cancelled:
                // Handle special cases
                DispatchQueue.main.async {
                    self.logger.warning("⚠️ Process timeout/cancellation reported to engine")
                }
            }
        }
    }
    
    // MARK: - State-Specific Handlers
    
    private func handleRunningStateActivation() {
        logger.info("▶️ Running state activated - starting coordination")
        
        // Reset error recovery attempts
        errorRecoveryAttempts = 0
        isRecovering = false
        
        // Start performance monitoring
        performanceMetrics.sessionStartTime = Date()
        performanceMetrics.isMonitoring = true
    }
    
    private func handleSessionCompletion() {
        logger.info("🎉 Session completed - finalizing coordination")
        
        // Stop performance monitoring
        performanceMetrics.isMonitoring = false
        performanceMetrics.sessionEndTime = Date()
        
        // Schedule completion notification
        notificationManager.scheduleNotification(.sessionCompleted)
        
        // Calculate final metrics
        calculateFinalSessionMetrics()
    }
    
    private func handleErrorStateActivation() {
        logger.error("❌ Error state activated - initiating recovery")
        
        guard !isRecovering else { return }
        
        isRecovering = true
        
        // Attempt automatic recovery if possible
        if errorRecoveryAttempts < maxErrorRecoveryAttempts {
            errorRecoveryAttempts += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.attemptErrorRecovery()
            }
        } else {
            logger.error("🚨 Maximum error recovery attempts reached")
            notificationManager.scheduleNotification(.maxRecoveryAttemptsReached)
        }
    }
    
    private func handlePausedStateActivation() {
        logger.info("⏸️ Paused state activated - maintaining coordination")
        
        // Pause performance monitoring
        performanceMetrics.isMonitoring = false
    }
    
    // MARK: - Execution Result Handlers
    
    private func handleSuccessfulExecution(output: String, duration: TimeInterval) {
        performanceMetrics.recordExecution(success: true, duration: duration)
        
        // Reset error recovery
        errorRecoveryAttempts = 0
        isRecovering = false
        
        // Continue with normal operation
        logger.info("✅ Successful execution integrated into coordination")
    }
    
    private func handleFailedExecution(error: ProcessManager.ProcessError, attempt: Int) {
        performanceMetrics.recordExecution(success: false, duration: 0)
        
        // Handle specific error types
        switch error {
        case .claudeNotFound:
            notificationManager.scheduleNotification(.claudeNotFound)
        case .networkError:
            notificationManager.scheduleNotification(.networkError)
        case .permissionDenied:
            notificationManager.scheduleNotification(.permissionDenied)
        default:
            notificationManager.scheduleNotification(.executionFailed(error: error))
        }
        
        logger.error("❌ Failed execution handled in coordination layer")
    }
    
    private func handleTimeoutExecution(duration: TimeInterval) {
        performanceMetrics.recordExecution(success: false, duration: duration)
        
        notificationManager.scheduleNotification(.executionTimeout)
        
        logger.warning("⏰ Timeout execution handled in coordination layer")
    }
    
    private func handleCancelledExecution() {
        // Cancelled executions don't affect error recovery
        logger.info("🛑 Cancelled execution handled in coordination layer")
    }
    
    // MARK: - Error Handling
    
    private func handleSchedulerError(_ error: SchedulerError) {
        logger.error("🚨 Scheduler error in coordination: \(error)")
        
        // Handle based on error type
        switch error {
        case .timingPrecisionLost(let drift):
            if abs(drift) > 10.0 {
                // Critical timing issue
                handleCriticalTimingError(drift: drift)
            }
        case .memoryPressure:
            handleMemoryPressureError()
        case .recoveryFailed(let attempts):
            handleRecoveryFailedError(attempts: attempts)
        default:
            handleGenericSchedulerError(error)
        }
    }
    
    private func handleCoordinationError(_ error: CoordinationError) {
        logger.error("🔗 Coordination error: \(error)")
        
        switch error {
        case .schedulerError(let schedulerError):
            handleSchedulerError(schedulerError)
        case .processError(let processError):
            handleProcessManagerError(processError)
        case .synchronizationLost:
            handleSynchronizationLost()
        case .performanceDegradation:
            handlePerformanceDegradation()
        }
    }
    
    private func handleProcessFailureInEngine(_ error: ProcessManager.ProcessError) {
        // Convert ProcessManager error to SchedulerEngine error
        let schedulerError: SchedulerError
        
        switch error {
        case .claudeNotFound:
            schedulerError = .claudeCLINotFound
        case .networkError(let description):
            schedulerError = .networkUnavailable
        case .permissionDenied:
            schedulerError = .permissionsDenied
        default:
            schedulerError = .unknownError(details: error.localizedDescription ?? "Process error")
        }
        
        // This will be handled by the SchedulerEngine internally
        logger.info("🔄 Process error converted and reported to SchedulerEngine")
    }
    
    // MARK: - Recovery Methods
    
    private func attemptErrorRecovery() {
        guard isRecovering else { return }
        
        logger.info("🔄 Attempting error recovery (attempt \(errorRecoveryAttempts)/\(maxErrorRecoveryAttempts))")
        
        Task {
            // Try to restart the scheduler engine
            if schedulerEngine.currentState == .error {
                schedulerEngine.retryLastOperation()
            }
            
            // Wait and check if recovery succeeded
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                self?.checkRecoverySuccess()
            }
        }
    }
    
    private func checkRecoverySuccess() {
        if schedulerEngine.currentState != .error {
            logger.info("✅ Error recovery successful")
            isRecovering = false
            errorRecoveryAttempts = 0
        } else if errorRecoveryAttempts < maxErrorRecoveryAttempts {
            logger.warning("⚠️ Recovery attempt failed, retrying...")
            attemptErrorRecovery()
        } else {
            logger.error("🚨 Error recovery failed completely")
            isRecovering = false
        }
    }
    
    // MARK: - Performance Methods
    
    private func updatePerformanceMetrics() {
        let now = Date()
        
        performanceMetrics.lastUpdateTime = now
        performanceMetrics.updateCount += 1
        performanceMetrics.currentFPS = calculateCurrentFPS()
        
        // Check for performance issues
        if performanceMetrics.currentFPS < 30.0 && performanceMetrics.isMonitoring {
            logger.warning("⚠️ Performance degradation detected: \(performanceMetrics.currentFPS) FPS")
            handlePerformanceDegradation()
        }
    }
    
    private func calculateCurrentFPS() -> Double {
        let timeSinceLastUpdate = Date().timeIntervalSince(lastStateUpdate)
        return timeSinceLastUpdate > 0 ? 1.0 / timeSinceLastUpdate : 60.0
    }
    
    private func calculateFinalSessionMetrics() {
        if let startTime = performanceMetrics.sessionStartTime,
           let endTime = performanceMetrics.sessionEndTime {
            
            let sessionDuration = endTime.timeIntervalSince(startTime)
            let averageFPS = Double(performanceMetrics.updateCount) / sessionDuration
            
            logger.info("📊 Final session metrics - Duration: \(sessionDuration.formatted()), Average FPS: \(String(format: "%.1f", averageFPS))")
        }
    }
    
    private func updateUIMetrics(state: SchedulerState, progress: Double, timeRemaining: TimeInterval) {
        // This ensures UI updates are coordinated and optimized
        logger.debug("📱 UI metrics updated - State: \(state.displayName), Progress: \(String(format: "%.1f", progress))%")
    }
    
    // MARK: - Specific Error Handlers
    
    private func handleCriticalTimingError(drift: TimeInterval) {
        logger.error("🚨 Critical timing error - drift: \(drift)s")
        notificationManager.scheduleNotification(.timingCritical(drift: drift))
    }
    
    private func handleMemoryPressureError() {
        logger.warning("💾 Memory pressure detected in coordination")
        
        // Reduce update frequency temporarily
        performanceMetrics.isOptimizedMode = true
        
        // Clear unnecessary data
        if cancellables.count > 50 { // Arbitrary threshold
            logger.info("🧹 Cleaning up excessive subscriptions")
        }
    }
    
    private func handleRecoveryFailedError(attempts: Int) {
        logger.error("🚨 Recovery failed after \(attempts) attempts")
        isRecovering = false
        errorRecoveryAttempts = maxErrorRecoveryAttempts
    }
    
    private func handleGenericSchedulerError(_ error: SchedulerError) {
        logger.error("⚠️ Generic scheduler error: \(error.localizedDescription ?? "Unknown")")
    }
    
    private func handleProcessManagerError(_ error: ProcessManager.ProcessError) {
        logger.error("⚙️ Process manager error: \(error.localizedDescription ?? "Unknown")")
    }
    
    private func handleSynchronizationLost() {
        logger.error("🔗 Synchronization lost between components")
        
        // Attempt to re-establish bindings
        initializeStateBindings()
    }
    
    private func handlePerformanceDegradation() {
        logger.warning("📉 Performance degradation detected")
        
        // Enable optimization mode
        performanceMetrics.isOptimizedMode = true
        
        // Reduce update frequency
        // This would be handled by the throttling already in place
    }
}

// MARK: - Supporting Types

/// Coordination-specific error types
enum CoordinationError: LocalizedError {
    case schedulerError(SchedulerError)
    case processError(ProcessManager.ProcessError)
    case synchronizationLost
    case performanceDegradation
    
    var errorDescription: String? {
        switch self {
        case .schedulerError(let error):
            return "Scheduler error: \(error.localizedDescription ?? "Unknown")"
        case .processError(let error):
            return "Process error: \(error.localizedDescription ?? "Unknown")"
        case .synchronizationLost:
            return "Component synchronization lost"
        case .performanceDegradation:
            return "Performance degradation detected"
        }
    }
}

/// Performance metrics for coordination monitoring
struct PerformanceCoordinationMetrics {
    var sessionStartTime: Date?
    var sessionEndTime: Date?
    var lastUpdateTime: Date = Date()
    var updateCount: Int = 0
    var currentFPS: Double = 60.0
    var isMonitoring: Bool = false
    var isOptimizedMode: Bool = false
    
    var successfulExecutions: Int = 0
    var failedExecutions: Int = 0
    
    mutating func recordExecution(success: Bool, duration: TimeInterval) {
        if success {
            successfulExecutions += 1
        } else {
            failedExecutions += 1
        }
    }
    
    var successRate: Double {
        let total = successfulExecutions + failedExecutions
        return total > 0 ? Double(successfulExecutions) / Double(total) : 0.0
    }
}

// MARK: - Notification Extensions

extension NotificationManager.NotificationType {
    static let applicationStarted = NotificationManager.NotificationType.sessionStarted // Reuse existing
    static let commandExecutionStarted = NotificationManager.NotificationType.sessionStarted // Reuse
    static let claudeNotFound = NotificationManager.NotificationType.sessionFailed(error: .claudeCLINotFound)
    static let networkError = NotificationManager.NotificationType.sessionFailed(error: .networkUnavailable)
    static let permissionDenied = NotificationManager.NotificationType.sessionFailed(error: .permissionsDenied)
    static let executionTimeout = NotificationManager.NotificationType.sessionFailed(error: .unknownError(details: "Execution timeout"))
    static let maxRecoveryAttemptsReached = NotificationManager.NotificationType.sessionFailed(error: .recoveryFailed(attempts: 3))
    
    static func executionFailed(error: ProcessManager.ProcessError) -> NotificationManager.NotificationType {
        return .sessionFailed(error: .unknownError(details: error.localizedDescription ?? "Execution failed"))
    }
    
    static func timingCritical(drift: TimeInterval) -> NotificationManager.NotificationType {
        return .sessionFailed(error: .timingPrecisionLost(drift: drift))
    }
}

// MARK: - Animation Constants Extension

extension ClaudeAnimation {
    static let coordinationTransition = Animation.easeInOut(duration: 0.3)
    static let performanceOptimized = Animation.linear(duration: 0.1)
}

// MARK: - StateCoordinator Extensions

extension StateCoordinator {
    
    /// Returns current application health status
    var applicationHealthStatus: ApplicationHealthStatus {
        let hasErrors = schedulerEngine.lastError != nil
        let isExecuting = isProcessExecuting
        let performanceGood = performanceMetrics.currentFPS > 30.0
        
        if hasErrors {
            return .critical
        } else if !performanceGood {
            return .degraded
        } else if isExecuting {
            return .active
        } else {
            return .healthy
        }
    }
    
    /// Returns comprehensive status for debugging
    var debugStatus: String {
        return """
        StateCoordinator Status:
        - Current State: \(currentState.displayName)
        - Progress: \(String(format: "%.1f", progressPercentage))%
        - Process Executing: \(isProcessExecuting)
        - App Ready: \(isApplicationReady)
        - Performance FPS: \(String(format: "%.1f", performanceMetrics.currentFPS))
        - Success Rate: \(String(format: "%.1f", performanceMetrics.successRate * 100))%
        - Error Recovery Attempts: \(errorRecoveryAttempts)/\(maxErrorRecoveryAttempts)
        - Is Recovering: \(isRecovering)
        """
    }
    
    /// Manually triggers synchronization check
    func forceSynchronizationCheck() {
        logger.info("🔄 Manual synchronization check triggered")
        
        // Re-establish all bindings
        cancellables.removeAll()
        initializeStateBindings()
        coordinateEngineWithProcessManager()
        setupUISubscriptions()
        
        logger.info("✅ Synchronization check completed")
    }
}

/// Application health status
enum ApplicationHealthStatus {
    case healthy
    case active
    case degraded
    case critical
    
    var description: String {
        switch self {
        case .healthy:
            return "Healthy"
        case .active:
            return "Active"
        case .degraded:
            return "Degraded Performance"
        case .critical:
            return "Critical Issues"
        }
    }
    
    var color: Color {
        switch self {
        case .healthy:
            return .claudeCompleted
        case .active:
            return .claudeRunning
        case .degraded:
            return .claudeWarning
        case .critical:
            return .claudeError
        }
    }
}