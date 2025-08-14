import Foundation
import Combine
import AppKit
import OSLog
import Security
import Network

// MARK: - Protocol Definition

/// Protocol defining the Process Manager interface for Claude CLI execution
protocol ProcessManagerProtocol {
    var isExecuting: Bool { get }
    var lastExecutionResult: ProcessResult? { get }
    var claudeInstallationStatus: ValidationResult { get }
    
    func executeClaudeCommand() async -> ProcessResult
    func validateClaudeInstallation() async -> ValidationResult
    func cancelCurrentExecution()
    func getExecutionStats() -> ExecutionStats
}

// MARK: - Result Types

/// Result of a process execution
enum ProcessResult: Equatable {
    case success(output: String, duration: TimeInterval)
    case failure(error: ProcessError, retryAttempt: Int)
    case timeout(duration: TimeInterval)
    case cancelled
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

/// Result of Claude CLI validation
enum ValidationResult: Equatable {
    case valid(path: String, version: String)
    case notFound
    case invalidVersion(found: String, required: String)
    case permissionDenied(path: String)
    case unknown(error: String)
    
    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
}

/// Comprehensive error types for process execution
enum ProcessError: LocalizedError, Equatable {
    case claudeNotFound
    case permissionDenied(path: String)
    case networkError(description: String)
    case invalidOutput(received: String)
    case executionTimeout(duration: TimeInterval)
    case commandValidationFailed(reason: String)
    case systemResourceUnavailable
    case maxRetriesExceeded(attempts: Int)
    case circuitBreakerOpen
    case unknownError(description: String)
    
    var errorDescription: String? {
        switch self {
        case .claudeNotFound:
            return "Claude CLI not found. Please install Claude CLI and ensure it's in your PATH."
        case .permissionDenied(let path):
            return "Permission denied when executing Claude CLI at: \(path)"
        case .networkError(let description):
            return "Network error during Claude execution: \(description)"
        case .invalidOutput(let received):
            return "Invalid output received from Claude CLI: \(received)"
        case .executionTimeout(let duration):
            return "Claude CLI execution timed out after \(Int(duration)) seconds"
        case .commandValidationFailed(let reason):
            return "Command validation failed: \(reason)"
        case .systemResourceUnavailable:
            return "System resources unavailable for process execution"
        case .maxRetriesExceeded(let attempts):
            return "Maximum retry attempts exceeded (\(attempts))"
        case .circuitBreakerOpen:
            return "Circuit breaker is open due to repeated failures"
        case .unknownError(let description):
            return "Unknown error: \(description)"
        }
    }
    
    /// Indicates if the error is retryable
    var isRetryable: Bool {
        switch self {
        case .networkError, .executionTimeout, .systemResourceUnavailable, .unknownError:
            return true
        case .claudeNotFound, .permissionDenied, .invalidOutput, .commandValidationFailed, .maxRetriesExceeded, .circuitBreakerOpen:
            return false
        }
    }
}

/// Execution statistics tracking
struct ExecutionStats: Codable {
    var totalExecutions: Int = 0
    var successfulExecutions: Int = 0
    var failedExecutions: Int = 0
    var totalExecutionTime: TimeInterval = 0
    var averageExecutionTime: TimeInterval = 0
    var lastExecutionTime: Date?
    var lastSuccessTime: Date?
    var consecutiveFailures: Int = 0
    var circuitBreakerTrips: Int = 0
    
    var successRate: Double {
        return totalExecutions > 0 ? Double(successfulExecutions) / Double(totalExecutions) : 0.0
    }
    
    mutating func recordExecution(result: ProcessResult, duration: TimeInterval) {
        totalExecutions += 1
        totalExecutionTime += duration
        averageExecutionTime = totalExecutionTime / Double(totalExecutions)
        lastExecutionTime = Date()
        
        if result.isSuccess {
            successfulExecutions += 1
            consecutiveFailures = 0
            lastSuccessTime = Date()
        } else {
            failedExecutions += 1
            consecutiveFailures += 1
        }
    }
}

/// Circuit breaker state for handling repeated failures
enum CircuitBreakerState {
    case closed    // Normal operation
    case open      // Failing fast, not executing
    case halfOpen  // Testing if service has recovered
}

/// Circuit breaker configuration
struct CircuitBreakerConfig {
    let failureThreshold: Int = 3
    let recoveryTimeInterval: TimeInterval = 300 // 5 minutes
    let halfOpenMaxAttempts: Int = 1
}

/// Manages execution of external processes, specifically the Claude CLI
/// Provides robust execution with retry logic, circuit breaker, and comprehensive error handling
class ProcessManager: ObservableObject, ProcessManagerProtocol {
    
    static let shared = ProcessManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var isExecuting: Bool = false
    @Published private(set) var lastExecutionResult: ProcessResult?
    @Published private(set) var claudeInstallationStatus: ValidationResult = .unknown(error: "Not validated")
    @Published private(set) var executionStats: ExecutionStats = ExecutionStats()
    @Published private(set) var circuitBreakerState: CircuitBreakerState = .closed
    
    // MARK: - Configuration
    
    private let claudeCommand = ["claude", "salut", "ça", "va", "-p"]
    private let executionTimeout: TimeInterval = 30.0
    private let maxRetryAttempts: Int = 5
    private let retryDelays: [TimeInterval] = [1.0, 2.0, 4.0, 8.0, 16.0]
    private let circuitBreakerConfig = CircuitBreakerConfig()
    
    // MARK: - Private Properties
    
    private let processQueue = DispatchQueue(label: "com.claudescheduler.process", qos: .userInitiated)
    private var currentProcess: Process?
    private var cancellationTokenSource: DispatchSourceTimer?
    private let logger = Logger(subsystem: "com.claudescheduler", category: "ProcessManager")
    
    // Claude CLI discovery paths
    private let claudeSearchPaths = [
        "/usr/local/bin/claude",
        "/opt/homebrew/bin/claude",
        "/usr/bin/claude",
        "~/bin/claude",
        "~/.local/bin/claude"
    ]
    
    // Circuit breaker state tracking
    private var lastFailureTime: Date?
    private var halfOpenAttempts: Int = 0
    
    // Performance monitoring
    private let performanceMonitor = PerformanceMonitor()
    
    // MARK: - Initialization
    
    private init() {
        setupProcessMonitoring()
        
        // Validate Claude installation on startup
        Task {
            let validation = await validateClaudeInstallation()
            await MainActor.run {
                self.claudeInstallationStatus = validation
            }
        }
        
        logger.info("🔧 ProcessManager initialized with robust execution pipeline")
        
        // Initialize performance monitoring
        performanceMonitor.startMonitoring()
        
        // Restore persisted statistics
        restorePersistedStats()
    }
    
    // MARK: - Public API
    
    /// Executes a custom Claude CLI command with comprehensive error handling and retry logic
    /// - Parameter command: The Claude command to execute
    /// - Returns: ProcessResult containing execution outcome
    func executeClaude(command: String) async throws -> ProcessResult {
        let result = await executeClaudeCommand()
        
        // Convert ProcessResult to throwing version
        switch result {
        case .success(let output, let duration):
            return .success(output: output, duration: duration)
        case .failure(let error, let attempt):
            throw error
        case .timeout(let duration):
            throw ProcessError.executionTimeout(duration: duration)
        case .cancelled:
            throw ProcessError.unknownError(description: "Execution was cancelled")
        }
    }
    
    /// Executes the Claude CLI command with comprehensive error handling and retry logic
    /// - Returns: ProcessResult containing execution outcome
    func executeClaudeCommand() async -> ProcessResult {
        logger.info("🚀 Starting Claude CLI execution with retry logic")
        
        // Check circuit breaker state
        guard await checkCircuitBreaker() else {
            logger.warning("⚡ Circuit breaker is open, failing fast")
            return .failure(error: .circuitBreakerOpen, retryAttempt: 0)
        }
        
        // Validate Claude installation first
        let validation = await validateClaudeInstallation()
        guard validation.isValid else {
            let error = convertValidationToError(validation)
            await recordFailure()
            return .failure(error: error, retryAttempt: 0)
        }
        
        // Update state
        await MainActor.run {
            self.isExecuting = true
        }
        
        defer {
            Task { @MainActor in
                self.isExecuting = false
            }
        }
        
        // Execute with retry logic
        let startTime = Date()
        let result = await executeWithRetryLogic()
        let duration = Date().timeIntervalSince(startTime)
        
        // Record statistics
        await MainActor.run {
            self.executionStats.recordExecution(result: result, duration: duration)
            self.lastExecutionResult = result
        }
        
        // Update circuit breaker state
        if result.isSuccess {
            await recordSuccess()
        } else {
            await recordFailure()
        }
        
        logger.info("✅ Claude CLI execution completed: \(result)")
        return result
    }
    
    /// Validates Claude CLI installation and availability
    /// - Returns: ValidationResult with detailed installation status
    func validateClaudeInstallation() async -> ValidationResult {
        logger.info("🔍 Validating Claude CLI installation")
        
        // Check for Claude in standard locations
        for path in claudeSearchPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            let fileManager = FileManager.default
            
            if fileManager.fileExists(atPath: expandedPath) {
                // Check if executable
                if fileManager.isExecutableFile(atPath: expandedPath) {
                    // Try to get version
                    if let version = await getClaudeVersion(at: expandedPath) {
                        logger.info("✅ Found valid Claude CLI at \(expandedPath), version: \(version)")
                        return .valid(path: expandedPath, version: version)
                    } else {
                        logger.warning("⚠️ Found Claude at \(expandedPath) but couldn't determine version")
                        return .invalidVersion(found: "unknown", required: "latest")
                    }
                } else {
                    logger.warning("⚠️ Found Claude at \(expandedPath) but not executable")
                    return .permissionDenied(path: expandedPath)
                }
            }
        }
        
        // Try PATH search
        if let pathResult = await findClaudeInPath() {
            return pathResult
        }
        
        logger.error("❌ Claude CLI not found in any standard location")
        return .notFound
    }
    
    /// Cancels the currently executing process
    func cancelCurrentExecution() {
        logger.info("🛑 Cancelling current Claude CLI execution")
        
        processQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Terminate current process
            if let process = self.currentProcess, process.isRunning {
                process.terminate()
                
                // Wait briefly for graceful termination
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    if process.isRunning {
                        process.kill()
                    }
                }
            }
            
            // Cancel any pending timers
            self.cancellationTokenSource?.cancel()
            self.cancellationTokenSource = nil
            self.currentProcess = nil
        }
        
        Task { @MainActor in
            self.isExecuting = false
            self.lastExecutionResult = .cancelled
        }
    }
    
    /// Returns comprehensive execution statistics
    /// - Returns: Current execution statistics
    func getExecutionStats() -> ExecutionStats {
        return executionStats
    }
    
    // MARK: - Private Implementation
    
    /// Executes Claude command with exponential backoff retry logic
    private func executeWithRetryLogic() async -> ProcessResult {
        var lastError: ProcessError?
        
        for attempt in 0..<maxRetryAttempts {
            logger.info("🔄 Claude CLI execution attempt \(attempt + 1)/\(maxRetryAttempts)")
            
            let result = await executeSingleAttempt()
            
            switch result {
            case .success:
                logger.info("✅ Claude CLI executed successfully on attempt \(attempt + 1)")
                return result
                
            case .failure(let error, _):
                lastError = error
                
                // Check if error is retryable
                guard error.isRetryable && attempt < maxRetryAttempts - 1 else {
                    logger.error("❌ Non-retryable error or max attempts reached: \(error)")
                    return .failure(error: error, retryAttempt: attempt + 1)
                }
                
                // Wait with exponential backoff
                let delay = retryDelays[min(attempt, retryDelays.count - 1)]
                logger.info("⏳ Waiting \(delay)s before retry attempt \(attempt + 2)")
                
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            case .timeout, .cancelled:
                return result
            }
        }
        
        // All attempts failed
        let finalError = lastError ?? .maxRetriesExceeded(attempts: maxRetryAttempts)
        return .failure(error: finalError, retryAttempt: maxRetryAttempts)
    }
    
    /// Executes a single attempt of the Claude CLI command
    private func executeSingleAttempt() async -> ProcessResult {
        let startTime = Date()
        
        return await withCheckedContinuation { continuation in
            processQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: .failure(error: .systemResourceUnavailable, retryAttempt: 0))
                    return
                }
                
                self.performSingleExecution { result in
                    let duration = Date().timeIntervalSince(startTime)
                    
                    switch result {
                    case .success(let output):
                        continuation.resume(returning: .success(output: output, duration: duration))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error: error, retryAttempt: 0))
                    case .timeout:
                        continuation.resume(returning: .timeout(duration: duration))
                    case .cancelled:
                        continuation.resume(returning: .cancelled)
                    }
                }
            }
        }
    }
    
    /// Performs the actual process execution
    private func performSingleExecution(completion: @escaping (ProcessResult) -> Void) {
        let process = Process()
        currentProcess = process
        
        // Configure process for Claude CLI execution
        guard let claudePath = getClaudePath() else {
            completion(.failure(error: .claudeNotFound, retryAttempt: 0))
            return
        }
        
        process.executableURL = URL(fileURLWithPath: claudePath)
        process.arguments = Array(claudeCommand.dropFirst()) // Remove 'claude' as it's the executable
        
        // Security: Set up clean environment
        process.environment = createSandboxedEnvironment()
        
        // Setup pipes for output capture
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        process.standardInput = nil // Prevent interactive prompts
        
        // Setup timeout using dispatch source
        let timeoutSource = DispatchSource.makeTimerSource(queue: processQueue)
        timeoutSource.schedule(deadline: .now() + executionTimeout)
        timeoutSource.setEventHandler {
            if process.isRunning {
                self.logger.warning("⏰ Claude CLI execution timed out after \(self.executionTimeout)s")
                process.terminate()
                
                // Force kill if still running after 2 seconds
                DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                    if process.isRunning {
                        process.kill()
                    }
                }
            }
        }
        
        self.cancellationTokenSource = timeoutSource
        
        // Setup completion handler
        process.terminationHandler = { [weak self] process in
            timeoutSource.cancel()
            self?.cancellationTokenSource = nil
            
            // Read output
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            self?.logger.info("📤 Process terminated with status: \(process.terminationStatus)")
            
            // Handle result based on termination status
            switch process.terminationStatus {
            case 0:
                // Success - validate output
                if self?.validateClaudeOutput(output) == true {
                    completion(.success(output: output, duration: 0))
                } else {
                    completion(.failure(error: .invalidOutput(received: output), retryAttempt: 0))
                }
                
            case 15: // SIGTERM (timeout)
                completion(.timeout(duration: self?.executionTimeout ?? 30.0))
                
            case -2: // Interrupted (cancelled)
                completion(.cancelled)
                
            default:
                // Determine specific error type
                let error = self?.parseExecutionError(status: process.terminationStatus, errorOutput: errorOutput) ?? .unknownError(description: "Exit code: \(process.terminationStatus)")
                completion(.failure(error: error, retryAttempt: 0))
            }
            
            self?.currentProcess = nil
        }
        
        // Execute process
        do {
            try process.run()
            timeoutSource.resume()
            logger.info("🚀 Claude CLI execution started with PID: \(process.processIdentifier)")
        } catch {
            timeoutSource.cancel()
            self.cancellationTokenSource = nil
            currentProcess = nil
            
            let processError = convertSystemError(error)
            logger.error("❌ Failed to start Claude CLI: \(processError)")
            completion(.failure(error: processError, retryAttempt: 0))
        }
    }
    
    // MARK: - Claude CLI Discovery
    
    /// Finds Claude CLI in system PATH
    private func findClaudeInPath() async -> ValidationResult? {
        let pathResult = await executeSystemCommand(["/usr/bin/which", "claude"])
        
        if let claudePath = pathResult?.output?.trimmingCharacters(in: .whitespacesAndNewlines),
           !claudePath.isEmpty {
            
            // Verify it's executable and get version
            if FileManager.default.isExecutableFile(atPath: claudePath) {
                if let version = await getClaudeVersion(at: claudePath) {
                    return .valid(path: claudePath, version: version)
                } else {
                    return .invalidVersion(found: "unknown", required: "latest")
                }
            } else {
                return .permissionDenied(path: claudePath)
            }
        }
        
        return nil
    }
    
    /// Gets Claude CLI version from specified path
    private func getClaudeVersion(at path: String) async -> String? {
        let versionResult = await executeSystemCommand([path, "--version"], timeout: 5.0)
        return versionResult?.output?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Gets the current Claude CLI path from validation status
    private func getClaudePath() -> String? {
        if case .valid(let path, _) = claudeInstallationStatus {
            return path
        }
        return nil
    }
    
    // MARK: - System Command Execution
    
    /// Executes a system command for utility purposes (discovery, validation)
    private func executeSystemCommand(_ arguments: [String], timeout: TimeInterval = 10.0) async -> (output: String?, error: String?)? {
        return await withCheckedContinuation { continuation in
            let process = Process()
            
            guard !arguments.isEmpty else {
                continuation.resume(returning: nil)
                return
            }
            
            process.executableURL = URL(fileURLWithPath: arguments[0])
            process.arguments = Array(arguments.dropFirst())
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            process.standardInput = nil
            
            // Setup timeout
            let timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
                if process.isRunning {
                    process.terminate()
                }
            }
            
            process.terminationHandler = { process in
                timeoutTimer.invalidate()
                
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                let output = String(data: outputData, encoding: .utf8)
                let error = String(data: errorData, encoding: .utf8)
                
                continuation.resume(returning: (output: output, error: error))
            }
            
            do {
                try process.run()
            } catch {
                timeoutTimer.invalidate()
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - Circuit Breaker Implementation
    
    /// Checks if circuit breaker allows execution
    private func checkCircuitBreaker() async -> Bool {
        let state = await MainActor.run { circuitBreakerState }
        
        switch state {
        case .closed:
            return true
            
        case .open:
            // Check if recovery time has passed
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > circuitBreakerConfig.recoveryTimeInterval {
                
                await MainActor.run {
                    self.circuitBreakerState = .halfOpen
                    self.halfOpenAttempts = 0
                }
                
                logger.info("🔄 Circuit breaker transitioning to half-open state")
                return true
            }
            return false
            
        case .halfOpen:
            return await MainActor.run {
                halfOpenAttempts < circuitBreakerConfig.halfOpenMaxAttempts
            }
        }
    }
    
    /// Records a successful execution for circuit breaker
    private func recordSuccess() async {
        await MainActor.run {
            self.circuitBreakerState = .closed
            self.halfOpenAttempts = 0
            self.lastFailureTime = nil
        }
        
        logger.info("✅ Circuit breaker reset to closed state after success")
    }
    
    /// Records a failed execution for circuit breaker
    private func recordFailure() async {
        await MainActor.run {
            self.lastFailureTime = Date()
            
            switch self.circuitBreakerState {
            case .closed:
                if self.executionStats.consecutiveFailures >= self.circuitBreakerConfig.failureThreshold {
                    self.circuitBreakerState = .open
                    self.executionStats.circuitBreakerTrips += 1
                    self.logger.warning("⚡ Circuit breaker opened due to consecutive failures")
                }
                
            case .halfOpen:
                self.circuitBreakerState = .open
                self.executionStats.circuitBreakerTrips += 1
                self.logger.warning("⚡ Circuit breaker reopened after half-open failure")
                
            case .open:
                break // Already open
            }
        }
    }
    
    // MARK: - Validation and Error Handling
    
    /// Validates Claude CLI output to ensure it's legitimate
    private func validateClaudeOutput(_ output: String) -> Bool {
        // Basic validation - Claude should produce some output for "salut ça va"
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for minimum output length
        guard trimmedOutput.count > 0 else {
            logger.warning("🚨 Claude output validation failed: empty output")
            return false
        }
        
        // Check for common error patterns
        let errorPatterns = [
            "command not found",
            "permission denied",
            "authentication failed",
            "network error",
            "timeout"
        ]
        
        let outputLower = trimmedOutput.lowercased()
        for pattern in errorPatterns {
            if outputLower.contains(pattern) {
                logger.warning("🚨 Claude output validation failed: contains error pattern '\(pattern)'")
                return false
            }
        }
        
        // Output appears valid
        logger.info("✅ Claude output validation passed")
        return true
    }
    
    /// Converts validation result to process error
    private func convertValidationToError(_ validation: ValidationResult) -> ProcessError {
        switch validation {
        case .notFound:
            return .claudeNotFound
        case .permissionDenied(let path):
            return .permissionDenied(path: path)
        case .invalidVersion(let found, let required):
            return .commandValidationFailed(reason: "Invalid Claude version: found \(found), required \(required)")
        case .unknown(let error):
            return .unknownError(description: error)
        case .valid:
            return .unknownError(description: "Validation passed but treated as error")
        }
    }
    
    /// Parses execution error from process termination
    private func parseExecutionError(status: Int32, errorOutput: String) -> ProcessError {
        switch status {
        case 1:
            if errorOutput.lowercased().contains("permission") {
                return .permissionDenied(path: "claude")
            } else if errorOutput.lowercased().contains("network") {
                return .networkError(description: errorOutput)
            } else {
                return .unknownError(description: "Exit code 1: \(errorOutput)")
            }
            
        case 2:
            return .claudeNotFound
            
        case 126:
            return .permissionDenied(path: "claude")
            
        case 127:
            return .claudeNotFound
            
        default:
            return .unknownError(description: "Exit code \(status): \(errorOutput)")
        }
    }
    
    /// Converts system error to process error
    private func convertSystemError(_ error: Error) -> ProcessError {
        let nsError = error as NSError
        
        switch nsError.code {
        case 2: // ENOENT
            return .claudeNotFound
        case 13: // EACCES
            return .permissionDenied(path: "claude")
        case 8: // ENOEXEC
            return .commandValidationFailed(reason: "Not a valid executable")
        default:
            return .unknownError(description: nsError.localizedDescription)
        }
    }
    
    // MARK: - System Integration
    
    private func setupProcessMonitoring() {
        // Monitor system events that might affect Claude CLI
        setupSystemEventMonitoring()
        
        // Setup cleanup on app termination
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cleanup()
        }
        
        // Monitor for system sleep/wake events
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logger.info("💤 System going to sleep, cancelling any running processes")
            self?.cancelCurrentExecution()
        }
        
        logger.info("📡 Process monitoring and system integration configured")
    }
    
    private func setupSystemEventMonitoring() {
        // Monitor for network changes that might affect Claude CLI
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.logger.info("🌐 Network connection available")
            } else {
                self?.logger.warning("🚫 Network connection lost - may affect Claude CLI")
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    private func cleanup() {
        logger.info("🧹 Starting ProcessManager cleanup")
        
        // Cancel any running processes
        cancelCurrentExecution()
        
        // Save execution statistics
        if let data = try? JSONEncoder().encode(executionStats) {
            UserDefaults.standard.set(data, forKey: "ProcessManagerStats")
        }
        
        logger.info("🧹 ProcessManager cleanup completed")
    }
}

// MARK: - Performance Monitoring

/// Performance monitoring for process execution
class PerformanceMonitor {
    private let logger = Logger(subsystem: "com.claudescheduler", category: "PerformanceMonitor")
    
    func startMonitoring() {
        // Monitor memory usage
        Task {
            while true {
                let memoryUsage = getCurrentMemoryUsage()
                if memoryUsage > 50.0 { // MB
                    logger.warning("⚠️ High memory usage detected: \(memoryUsage)MB")
                }
                
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            }
        }
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Double(info.resident_size) / 1024.0 / 1024.0 : 0
    }
}

// MARK: - Extensions

extension ProcessManager {
    
    /// Returns formatted last execution time
    var lastExecutionTimeFormatted: String {
        guard let lastExecution = executionStats.lastExecutionTime else {
            return "Never"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        let calendar = Calendar.current
        if calendar.isDateInToday(lastExecution) {
            return "Today at \(formatter.string(from: lastExecution))"
        } else if calendar.isDateInYesterday(lastExecution) {
            return "Yesterday at \(formatter.string(from: lastExecution))"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: lastExecution)
        }
    }
    
    /// Returns human-readable success rate
    var successRateFormatted: String {
        let rate = executionStats.successRate * 100
        return String(format: "%.1f%%", rate)
    }
    
    /// Returns human-readable average execution time
    var averageExecutionTimeFormatted: String {
        let avgTime = executionStats.averageExecutionTime
        return String(format: "%.2fs", avgTime)
    }
    
    /// Returns current circuit breaker status description
    var circuitBreakerStatusDescription: String {
        switch circuitBreakerState {
        case .closed:
            return "Operational"
        case .open:
            return "Failed (recovering)"
        case .halfOpen:
            return "Testing recovery"
        }
    }
}

// MARK: - Security Extensions

extension ProcessManager {
    
    /// Validates that the Claude CLI execution is secure
    private func validateClaudeExecution() -> Bool {
        // Verify Claude installation status
        guard claudeInstallationStatus.isValid else {
            logger.error("🚨 Security validation failed: Claude CLI not properly validated")
            return false
        }
        
        // Verify command arguments are safe
        let allowedArguments = ["salut", "ça", "va", "-p", "--print"]
        for arg in claudeCommand {
            if !allowedArguments.contains(arg) {
                logger.error("🚨 Security validation failed: unauthorized argument '\(arg)'")
                return false
            }
        }
        
        logger.info("✅ Security validation passed for Claude CLI execution")
        return true
    }
    
    /// Creates a sandboxed environment for process execution
    private func createSandboxedEnvironment() -> [String: String] {
        var environment: [String: String] = [:]
        
        // Copy only essential environment variables
        let essentialVars = ["PATH", "HOME", "USER", "LANG", "LC_ALL"]
        let currentEnv = ProcessInfo.processInfo.environment
        
        for variable in essentialVars {
            if let value = currentEnv[variable] {
                environment[variable] = value
            }
        }
        
        // Remove potentially dangerous variables
        environment.removeValue(forKey: "LD_PRELOAD")
        environment.removeValue(forKey: "DYLD_INSERT_LIBRARIES")
        environment.removeValue(forKey: "DYLD_LIBRARY_PATH")
        
        return environment
    }
}

// MARK: - Network Monitoring

extension ProcessManager {
    
    /// Checks network connectivity before Claude CLI execution
    private func checkNetworkConnectivity() async -> Bool {
        return await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "NetworkCheck")
            
            monitor.pathUpdateHandler = { path in
                let isConnected = path.status == .satisfied
                monitor.cancel()
                continuation.resume(returning: isConnected)
            }
            
            monitor.start(queue: queue)
            
            // Timeout after 5 seconds
            DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
                monitor.cancel()
                continuation.resume(returning: false)
            }
        }
    }
}

// MARK: - Integration with SchedulerEngine

extension ProcessManager {
    
    /// Provides callbacks for SchedulerEngine integration
    enum SchedulerCallback {
        case executionStarted
        case executionCompleted(ProcessResult)
        case executionProgress(Double)
        case validationFailed(ValidationResult)
    }
    
    /// Executes Claude command with scheduler integration
    func executeForScheduler(callback: @escaping (SchedulerCallback) -> Void) async -> ProcessResult {
        // Notify execution started
        callback(.executionStarted)
        
        // Validate first
        let validation = await validateClaudeInstallation()
        guard validation.isValid else {
            callback(.validationFailed(validation))
            return .failure(error: convertValidationToError(validation), retryAttempt: 0)
        }
        
        // Execute with progress reporting
        let result = await executeClaudeCommand()
        
        // Notify completion
        callback(.executionCompleted(result))
        
        return result
    }
    
    /// Restores execution statistics from persistent storage
    private func restorePersistedStats() {
        if let data = UserDefaults.standard.data(forKey: "ProcessManagerStats"),
           let stats = try? JSONDecoder().decode(ExecutionStats.self, from: data) {
            
            Task { @MainActor in
                self.executionStats = stats
            }
            
            logger.info("📊 Restored execution statistics: \(stats.totalExecutions) total executions")
        }
    }
}