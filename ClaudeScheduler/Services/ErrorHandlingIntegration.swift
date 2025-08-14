import Foundation
import Combine
import AppKit
import OSLog

// MARK: - Enhanced Error Handling Integration

/// Integrates enterprise-level error handling with existing ClaudeScheduler components
/// Provides seamless error detection, recovery, and user communication
class ErrorHandlingIntegration: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isErrorHandlingActive: Bool = false
    @Published private(set) var currentErrorHandlingState: ErrorHandlingState = .monitoring
    @Published private(set) var recentErrors: [SystemError] = []
    @Published private(set) var systemReliabilityScore: Double = 1.0
    @Published private(set) var lastHealthCheck: Date = Date()
    
    // MARK: - Core Components
    
    private let errorRecoveryEngine: ErrorRecoveryEngine
    private let systemHealthMonitor: SystemHealthMonitor
    private let edgeTestingSuite: EdgeCaseTestingSuite
    private let schedulerEngine: SchedulerEngine
    private let processManager: ProcessManager
    private let stateCoordinator: StateCoordinator
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.claudescheduler", category: "ErrorHandlingIntegration")
    private var cancellables = Set<AnyCancellable>()
    private let integrationQueue = DispatchQueue(label: "com.claudescheduler.errorintegration", qos: .userInitiated)
    
    // Configuration
    private let healthCheckInterval: TimeInterval = 60.0 // 1 minute
    private let errorAggregationWindow: TimeInterval = 300.0 // 5 minutes
    private let maxRecentErrors = 50
    
    // State tracking
    private var errorHistory: [SystemError] = []
    private var recoveryMetrics = RecoveryMetrics()
    private var reliabilityTrends: [ReliabilitySnapshot] = []
    
    // MARK: - Initialization
    
    init(
        schedulerEngine: SchedulerEngine,
        processManager: ProcessManager,
        stateCoordinator: StateCoordinator
    ) {
        self.schedulerEngine = schedulerEngine
        self.processManager = processManager
        self.stateCoordinator = stateCoordinator
        
        // Initialize error handling components
        self.errorRecoveryEngine = ErrorRecoveryEngine.shared
        self.systemHealthMonitor = SystemHealthMonitor()
        self.edgeTestingSuite = EdgeCaseTestingSuite(
            systemHealthMonitor: systemHealthMonitor,
            errorRecoveryEngine: errorRecoveryEngine,
            schedulerEngine: schedulerEngine,
            processManager: processManager
        )
        
        setupErrorHandlingIntegration()
        startErrorMonitoring()
        
        logger.info("🔗 Error Handling Integration initialized")
    }
    
    // MARK: - Public API
    
    /// Starts comprehensive error handling monitoring
    func startErrorHandling() {
        guard !isErrorHandlingActive else { return }
        
        logger.info("🛡️ Starting error handling integration")
        
        isErrorHandlingActive = true
        currentErrorHandlingState = .monitoring
        
        systemHealthMonitor.startMonitoring()
        setupComprehensiveErrorBindings()
        startProactiveHealthChecks()
    }
    
    /// Stops error handling monitoring
    func stopErrorHandling() {
        guard isErrorHandlingActive else { return }
        
        logger.info("🛑 Stopping error handling integration")
        
        isErrorHandlingActive = false
        currentErrorHandlingState = .disabled
        
        systemHealthMonitor.stopMonitoring()
        cancellables.removeAll()
    }
    
    /// Manually triggers system health validation
    func performSystemHealthCheck() async -> SystemHealthStatus {
        logger.info("🔍 Performing manual system health check")
        
        let healthStatus = await systemHealthMonitor.validateSystemHealth()
        let edgeCases = await systemHealthMonitor.detectEdgeCases()
        
        await MainActor.run {
            lastHealthCheck = Date()
            
            // Update reliability score based on health status
            updateReliabilityScore(healthStatus: healthStatus, edgeCases: edgeCases)
        }
        
        return healthStatus
    }
    
    /// Runs comprehensive edge case testing
    func runEdgeCaseTests() async -> TestingReport {
        logger.info("🧪 Running comprehensive edge case tests")
        
        currentErrorHandlingState = .testing
        
        await edgeTestingSuite.startChaosTestingSuite()
        let report = edgeTestingSuite.generateTestReport()
        
        currentErrorHandlingState = .monitoring
        
        logger.info("📊 Edge case testing completed: \(report.overallSuccessRate * 100)% success rate")
        
        return report
    }
    
    /// Forces error recovery for specific error type
    func forceErrorRecovery(for errorType: SystemError.ErrorType) async -> RecoveryResult {
        logger.info("🔧 Forcing error recovery for: \(errorType.rawValue)")
        
        currentErrorHandlingState = .recovering
        
        let result = await errorRecoveryEngine.initiateRecovery(for: errorType)
        
        currentErrorHandlingState = .monitoring
        
        // Update recovery metrics
        recoveryMetrics.recordRecoveryAttempt(result: result)
        
        return result
    }
    
    /// Gets comprehensive error handling status
    func getErrorHandlingStatus() -> ErrorHandlingStatus {
        return ErrorHandlingStatus(
            isActive: isErrorHandlingActive,
            currentState: currentErrorHandlingState,
            systemHealth: systemHealthMonitor.systemHealth,
            recoveryState: errorRecoveryEngine.currentRecoveryState,
            reliabilityScore: systemReliabilityScore,
            recentErrorCount: recentErrors.count,
            lastHealthCheck: lastHealthCheck,
            recoverySuccessRate: recoveryMetrics.successRate
        )
    }
    
    // MARK: - Private Setup Methods
    
    private func setupErrorHandlingIntegration() {
        // Setup error propagation from existing components to error handling system
        setupSchedulerEngineErrorHandling()
        setupProcessManagerErrorHandling()
        setupStateCoordinatorErrorHandling()
        setupCrossComponentErrorCorrelation()
    }
    
    private func setupSchedulerEngineErrorHandling() {
        // Monitor SchedulerEngine for timing and state errors
        schedulerEngine.$lastError
            .compactMap { $0 }
            .sink { [weak self] schedulerError in
                Task {
                    await self?.handleSchedulerEngineError(schedulerError)
                }
            }
            .store(in: &cancellables)
        
        // Monitor session state changes for potential issues
        schedulerEngine.$currentState
            .sink { [weak self] state in
                Task {
                    await self?.analyzeStateChange(state)
                }
            }
            .store(in: &cancellables)
        
        // Monitor timer precision for drift detection
        Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkTimerPrecision()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupProcessManagerErrorHandling() {
        // Monitor ProcessManager for execution errors
        processManager.$lastExecutionResult
            .compactMap { result in
                if case .failure(let error, let attempt) = result {
                    return (error, attempt)
                }
                return nil
            }
            .sink { [weak self] error, attempt in
                Task {
                    await self?.handleProcessManagerError(error, attempt: attempt)
                }
            }
            .store(in: &cancellables)
        
        // Monitor process execution patterns
        processManager.$isExecuting
            .sink { [weak self] isExecuting in
                if isExecuting {
                    Task {
                        await self?.monitorProcessExecution()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupStateCoordinatorErrorHandling() {
        // Monitor StateCoordinator for coordination errors
        stateCoordinator.$currentState
            .combineLatest(stateCoordinator.$isApplicationReady)
            .sink { [weak self] state, isReady in
                Task {
                    await self?.analyzeCoordinationState(state: state, isReady: isReady)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupCrossComponentErrorCorrelation() {
        // Correlate errors across multiple components to detect systemic issues
        Publishers.CombineLatest3(
            schedulerEngine.$lastError.compactMap { $0 },
            processManager.$lastExecutionResult.compactMap { result in
                if case .failure(let error, _) = result { return error }
                return nil
            },
            systemHealthMonitor.$systemHealth
        )
        .debounce(for: .seconds(5), scheduler: DispatchQueue.main)
        .sink { [weak self] schedulerError, processError, healthStatus in
            Task {
                await self?.correlateCrossComponentErrors(
                    schedulerError: schedulerError,
                    processError: processError,
                    healthStatus: healthStatus
                )
            }
        }
        .store(in: &cancellables)
    }
    
    private func setupComprehensiveErrorBindings() {
        // Enhanced error monitoring with predictive capabilities
        
        // Memory pressure monitoring
        Timer.publish(every: 15.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkMemoryPressure()
                }
            }
            .store(in: &cancellables)
        
        // CPU usage monitoring
        Timer.publish(every: 10.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkCPUUsage()
                }
            }
            .store(in: &cancellables)
        
        // Network connectivity monitoring
        Timer.publish(every: 20.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkNetworkConnectivity()
                }
            }
            .store(in: &cancellables)
        
        // Power state monitoring
        NotificationCenter.default.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.handleSystemWake()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.handleSystemSleep()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startErrorMonitoring() {
        currentErrorHandlingState = .monitoring
        
        // Start predictive error detection
        Timer.publish(every: 120.0, on: .main, in: .common) // Every 2 minutes
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.runPredictiveErrorDetection()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startProactiveHealthChecks() {
        Timer.publish(every: healthCheckInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    _ = await self?.performSystemHealthCheck()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Error Handling Methods
    
    private func handleSchedulerEngineError(_ schedulerError: SchedulerError) async {
        logger.error("📅 SchedulerEngine error detected: \(schedulerError.localizedDescription ?? "Unknown")")
        
        // Convert SchedulerError to SystemError
        let systemError = convertSchedulerErrorToSystemError(schedulerError)
        await recordAndHandleError(systemError)
    }
    
    private func handleProcessManagerError(_ processError: ProcessManager.ProcessError, attempt: Int) async {
        logger.error("⚙️ ProcessManager error detected: \(processError.localizedDescription ?? "Unknown") (attempt \(attempt))")
        
        // Convert ProcessError to SystemError
        let systemError = convertProcessErrorToSystemError(processError, attempt: attempt)
        await recordAndHandleError(systemError)
    }
    
    private func recordAndHandleError(_ systemError: SystemError) async {
        // Add to error history
        await MainActor.run {
            recentErrors.append(systemError)
            if recentErrors.count > maxRecentErrors {
                recentErrors.removeFirst()
            }
        }
        
        // Create error context
        let context = ErrorContext()
        
        // Handle error through recovery engine
        let recoveryResult = await errorRecoveryEngine.handleError(systemError, context: context)
        
        // Update reliability score based on error and recovery
        await updateReliabilityScoreForError(systemError, recoveryResult: recoveryResult)
        
        // Log recovery result
        logger.info("🔧 Error recovery result: \(recoveryResult.rawValue)")
    }
    
    private func analyzeStateChange(_ state: SchedulerState) async {
        // Look for problematic state transitions
        if state == .error {
            let systemError = SystemError.stateDesynchronized(
                component: "SchedulerEngine",
                expectedState: "running",
                actualState: "error"
            )
            await recordAndHandleError(systemError)
        }
    }
    
    private func checkTimerPrecision() async {
        // Monitor timer drift and precision
        let expectedInterval: TimeInterval = 30.0
        let actualInterval = Date().timeIntervalSince(lastHealthCheck)
        let drift = abs(actualInterval - expectedInterval)
        
        if drift > 5.0 { // 5 second drift threshold
            let systemError = SystemError.timerPrecisionCritical(
                actualDrift: drift,
                maxAcceptable: 2.0
            )
            await recordAndHandleError(systemError)
        }
    }
    
    private func monitorProcessExecution() async {
        // Monitor for hanging processes
        try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
        
        if processManager.isExecuting {
            // Process might be hanging
            let systemError = SystemError.processZombie(
                pid: pid_t(ProcessInfo.processInfo.processIdentifier),
                duration: 30.0
            )
            await recordAndHandleError(systemError)
        }
    }
    
    private func analyzeCoordinationState(state: SchedulerState, isReady: Bool) async {
        // Check for coordination inconsistencies
        if !isReady && state.isActive {
            let systemError = SystemError.stateDesynchronized(
                component: "StateCoordinator",
                expectedState: "ready",
                actualState: "not ready"
            )
            await recordAndHandleError(systemError)
        }
    }
    
    private func correlateCrossComponentErrors(
        schedulerError: SchedulerError,
        processError: ProcessManager.ProcessError,
        healthStatus: SystemHealthStatus
    ) async {
        logger.warning("🔗 Cross-component error correlation detected")
        
        // Analyze if multiple component errors indicate systemic issue
        if healthStatus == .critical {
            let systemError = SystemError.systemIntegrityProtectionViolation(
                operation: "multi-component failure"
            )
            await recordAndHandleError(systemError)
        }
    }
    
    private func checkMemoryPressure() async {
        let memoryUsage = await getCurrentMemoryUsage()
        
        if memoryUsage > 0.9 { // 90% memory usage
            let systemError = SystemError.memoryPressureCritical(
                availableMB: (1.0 - memoryUsage) * 1000, // Simplified
                requiredMB: 100.0
            )
            await recordAndHandleError(systemError)
        }
    }
    
    private func checkCPUUsage() async {
        let cpuUsage = await getCurrentCPUUsage()
        
        if cpuUsage > 80.0 { // 80% CPU usage threshold
            // Monitor for thermal throttling
            let systemError = SystemError.thermalThrottlingActive(level: .moderate)
            await recordAndHandleError(systemError)
        }
    }
    
    private func checkNetworkConnectivity() async {
        // Simplified network check
        let isConnected = await checkNetworkStatus()
        
        if !isConnected {
            let systemError = SystemError.networkPartiallyReachable(
                reachableHosts: [],
                unreachableHosts: ["api.anthropic.com"]
            )
            await recordAndHandleError(systemError)
        }
    }
    
    private func handleSystemWake() async {
        logger.info("🌅 System wake detected")
        
        // Check for session recovery after wake
        if schedulerEngine.currentState == .running {
            // Validate timer accuracy after wake
            await checkTimerPrecision()
        }
    }
    
    private func handleSystemSleep() async {
        logger.info("😴 System sleep detected")
        
        // Prepare for sleep - save state
        if schedulerEngine.currentState == .running {
            // Session will be paused automatically by SchedulerEngine
            logger.info("Session paused for system sleep")
        }
    }
    
    private func runPredictiveErrorDetection() async {
        let potentialErrors = await errorRecoveryEngine.predictiveErrorDetection()
        
        for potentialError in potentialErrors where potentialError.probability > 0.8 {
            logger.warning("🔮 High probability error predicted: \(potentialError.errorType.rawValue)")
            
            // Take preventive action if possible
            await takePreventiveAction(for: potentialError)
        }
    }
    
    private func takePreventiveAction(for potentialError: PotentialError) async {
        switch potentialError.errorType {
        case .resource:
            // Free up memory proactively
            await performPreventiveMemoryCleanup()
        case .network:
            // Test network connectivity
            _ = await checkNetworkStatus()
        case .timing:
            // Recalibrate timers
            await recalibrateTimers()
        default:
            break
        }
    }
    
    // MARK: - Utility Methods
    
    private func convertSchedulerErrorToSystemError(_ schedulerError: SchedulerError) -> SystemError {
        switch schedulerError {
        case .claudeCLINotFound:
            return .claudeVersionMismatch(expected: "latest", actual: "not found")
        case .claudeExecutionFailed(let details):
            return .claudeAPIRateLimited(retryAfter: 60.0, requestsUsed: 10)
        case .permissionsDenied:
            return .sandboxViolation(path: "/usr/local/bin/claude", operation: "execute")
        case .networkUnavailable:
            return .networkPartiallyReachable(reachableHosts: [], unreachableHosts: ["api.anthropic.com"])
        case .systemSleepInterruption:
            return .systemForcedSleep(reason: .userInitiated)
        case .timingPrecisionLost(let drift):
            return .timerPrecisionCritical(actualDrift: drift, maxAcceptable: 2.0)
        case .memoryPressure:
            return .memoryPressureCritical(availableMB: 50.0, requiredMB: 100.0)
        case .batteryLevelCritical:
            return .batteryLevelCritical(percentage: 0.05, estimatedTime: 300.0)
        default:
            return .environmentCorrupted(variables: ["SCHEDULER_ERROR"])
        }
    }
    
    private func convertProcessErrorToSystemError(_ processError: ProcessManager.ProcessError, attempt: Int) -> SystemError {
        switch processError {
        case .claudeNotFound:
            return .claudeVersionMismatch(expected: "latest", actual: "not found")
        case .networkError(let description):
            return .dnsResolutionFailed(hostname: "api.anthropic.com", attempts: attempt)
        case .permissionDenied:
            return .sandboxViolation(path: "/usr/local/bin/claude", operation: "execute")
        case .timeout(let duration):
            return .processZombie(pid: pid_t(ProcessInfo.processInfo.processIdentifier), duration: duration)
        default:
            return .environmentCorrupted(variables: ["PROCESS_ERROR"])
        }
    }
    
    private func updateReliabilityScore(healthStatus: SystemHealthStatus, edgeCases: [EdgeCaseDetection]) {
        let healthScore = healthStatusToScore(healthStatus)
        let edgeCaseScore = 1.0 - min(1.0, Double(edgeCases.count) / 10.0)
        
        systemReliabilityScore = (healthScore + edgeCaseScore) / 2.0
        
        // Store reliability snapshot
        reliabilityTrends.append(ReliabilitySnapshot(
            timestamp: Date(),
            score: systemReliabilityScore,
            healthStatus: healthStatus,
            edgeCaseCount: edgeCases.count
        ))
        
        // Keep only recent snapshots
        if reliabilityTrends.count > 100 {
            reliabilityTrends.removeFirst()
        }
    }
    
    private func updateReliabilityScoreForError(_ error: SystemError, recoveryResult: RecoveryResult) async {
        let errorImpact = errorSeverityToImpact(error.severity)
        let recoveryBonus = recoveryResult.isSuccessful ? 0.1 : 0.0
        
        await MainActor.run {
            systemReliabilityScore = max(0.0, systemReliabilityScore - errorImpact + recoveryBonus)
        }
    }
    
    private func healthStatusToScore(_ status: SystemHealthStatus) -> Double {
        switch status {
        case .excellent: return 1.0
        case .good: return 0.8
        case .fair: return 0.6
        case .poor: return 0.4
        case .critical: return 0.2
        }
    }
    
    private func errorSeverityToImpact(_ severity: ErrorSeverity) -> Double {
        switch severity {
        case .low: return 0.01
        case .medium: return 0.05
        case .high: return 0.1
        case .critical: return 0.2
        }
    }
    
    // MARK: - Stub implementations for system calls
    
    private func getCurrentMemoryUsage() async -> Double { return 0.5 }
    private func getCurrentCPUUsage() async -> Double { return 15.0 }
    private func checkNetworkStatus() async -> Bool { return true }
    private func performPreventiveMemoryCleanup() async { /* Implementation */ }
    private func recalibrateTimers() async { /* Implementation */ }
}

// MARK: - Supporting Types

enum ErrorHandlingState: String, CaseIterable {
    case disabled
    case monitoring
    case analyzing
    case recovering
    case testing
    case degraded
    
    var description: String {
        switch self {
        case .disabled: return "Error handling disabled"
        case .monitoring: return "Monitoring for errors"
        case .analyzing: return "Analyzing detected issues"
        case .recovering: return "Recovering from errors"
        case .testing: return "Running edge case tests"
        case .degraded: return "Operating in degraded mode"
        }
    }
}

struct ErrorHandlingStatus {
    let isActive: Bool
    let currentState: ErrorHandlingState
    let systemHealth: SystemHealthStatus
    let recoveryState: RecoveryState
    let reliabilityScore: Double
    let recentErrorCount: Int
    let lastHealthCheck: Date
    let recoverySuccessRate: Double
    
    var overallStatus: String {
        if reliabilityScore > 0.9 {
            return "Excellent"
        } else if reliabilityScore > 0.7 {
            return "Good"
        } else if reliabilityScore > 0.5 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
}

struct RecoveryMetrics {
    private var totalAttempts: Int = 0
    private var successfulAttempts: Int = 0
    
    var successRate: Double {
        return totalAttempts > 0 ? Double(successfulAttempts) / Double(totalAttempts) : 1.0
    }
    
    mutating func recordRecoveryAttempt(result: RecoveryResult) {
        totalAttempts += 1
        if result.isSuccessful {
            successfulAttempts += 1
        }
    }
}

struct ReliabilitySnapshot {
    let timestamp: Date
    let score: Double
    let healthStatus: SystemHealthStatus
    let edgeCaseCount: Int
}