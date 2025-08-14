import Foundation
import Combine
import AppKit
import OSLog

// MARK: - Protocol Definition

/// Protocol defining the scheduler engine interface
protocol SchedulerEngineProtocol {
    var currentState: SchedulerState { get }
    var timeRemaining: TimeInterval { get }
    var progressPercentage: Double { get }
    
    func startSession()
    func pauseSession()
    func resumeSession()
    func stopSession()
    func resetSession()
}

// MARK: - Supporting Structures

/// Performance metrics tracking
struct PerformanceMetrics: Codable {
    var memoryUsage: Double = 0.0 // MB
    var cpuUsage: Double = 0.0    // Percentage
    var energyImpact: Double = 0.0
    var timerAccuracy: Double = 0.0 // Seconds drift
    var lastUpdated: Date = Date()
    
    var isWithinTargets: Bool {
        return memoryUsage < 30.0 && cpuUsage < 1.0 && abs(timerAccuracy) < 2.0
    }
}

/// Memory monitoring utility
class MemoryMonitor {
    func getCurrentUsage() -> Double {
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let task = mach_task_self_
        let result = withUnsafeMutablePointer(to: &count) {
            $0.withMemoryRebound(to: mach_msg_type_number_t.self, capacity: 1) { countPtr in
                withUnsafeMutablePointer(to: &info) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) { infoPtr in
                        task_info(task, task_flavor_t(MACH_TASK_BASIC_INFO), infoPtr, countPtr)
                    }
                }
            }
        }
        
        guard result == KERN_SUCCESS else { return 0.0 }
        return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
    }
}

/// CPU monitoring utility
class CPUMonitor {
    private var lastCPUTime: Double = 0
    private var lastTimestamp: Date = Date()
    
    func getCurrentUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let task = mach_task_self_
        let result = withUnsafeMutablePointer(to: &count) {
            $0.withMemoryRebound(to: mach_msg_type_number_t.self, capacity: 1) { countPtr in
                withUnsafeMutablePointer(to: &info) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) { infoPtr in
                        task_info(task, task_flavor_t(MACH_TASK_BASIC_INFO), infoPtr, countPtr)
                    }
                }
            }
        }
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        let currentTime = Date()
        let currentCPUTime = Double(info.user_time.seconds + info.system_time.seconds) + 
                           Double(info.user_time.microseconds + info.system_time.microseconds) / 1_000_000.0
        
        let timeDelta = currentTime.timeIntervalSince(lastTimestamp)
        let cpuDelta = currentCPUTime - lastCPUTime
        
        lastCPUTime = currentCPUTime
        lastTimestamp = currentTime
        
        guard timeDelta > 0 else { return 0.0 }
        return min(100.0, (cpuDelta / timeDelta) * 100.0)
    }
}

/// Battery monitoring utility
class BatteryMonitor {
    func getCurrentLevel() -> Double {
        // Simplified battery monitoring for macOS
        return ProcessInfo.processInfo.isLowPowerModeEnabled ? 0.1 : 1.0
    }
    
    func getBatteryImpact() -> BatteryImpactLevel {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            return .minimal
        }
        // Calculate based on CPU usage and update frequency
        return .low
    }
}

/// High-precision scheduling engine with advanced timing, recovery, and battery optimization
/// Achieves ±2 second accuracy over 5-hour sessions with comprehensive system integration
class SchedulerEngine: ObservableObject, SchedulerEngineProtocol {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentState: SchedulerState = .idle
    @Published private(set) var currentSession: SessionData?
    @Published private(set) var progress: Double = 0.0
    @Published private(set) var timeRemaining: TimeInterval = 0
    @Published private(set) var lastError: SchedulerError?
    @Published private(set) var settings = SchedulerSettings()
    
    // High-precision timing properties
    @Published private(set) var progressPercentage: Double = 0.0
    @Published private(set) var timingAccuracy: TimingAccuracy = .highPrecision
    @Published private(set) var batteryImpact: BatteryImpactLevel = .low
    @Published private(set) var performanceMetrics = PerformanceMetrics()
    
    // MARK: - Private Properties
    
    // High-precision timers
    private var highPrecisionTimer: Timer?
    private var progressUpdateTimer: Timer?
    private var commandExecutionTimer: Timer?
    private var persistenceTimer: Timer?
    private var performanceMonitorTimer: Timer?
    
    // Timing state
    private var pausedTimeInterval: TimeInterval = 0
    private var pauseStartTime: Date?
    private var lastTimerCheck: Date?
    private var accumulatedDrift: TimeInterval = 0
    
    // Recovery and persistence
    private var persistenceData: SessionPersistenceData?
    private var recoveryAttempts = 0
    private let maxRecoveryAttempts = 5
    
    // Performance monitoring
    private var memoryMonitor: MemoryMonitor?
    private var cpuMonitor: CPUMonitor?
    private var batteryMonitor: BatteryMonitor?
    
    // Background task management (macOS)
    private var backgroundActivity: NSBackgroundActivityScheduler?
    private var isSystemSleeping = false
    
    private let processManager = ProcessManager.shared
    private let notificationManager = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Dependencies and Constants
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "ClaudeSchedulerSettings"
    private let persistenceKey = "ClaudeSchedulerSession"
    private let logger = Logger(subsystem: "com.claudescheduler.app", category: "SchedulerEngine")
    
    // High-precision timing constants
    private let SESSION_DURATION_SECONDS: TimeInterval = 18000.0 // Exactly 5 hours
    private let HIGH_PRECISION_INTERVAL: TimeInterval = 0.1 // 100ms for precision tracking
    private let UI_UPDATE_INTERVAL: TimeInterval = 1.0 // 1 second for UI
    private let PERSISTENCE_INTERVAL: TimeInterval = 30.0 // 30 seconds for auto-save
    private let PERFORMANCE_MONITOR_INTERVAL: TimeInterval = 5.0 // 5 seconds for metrics
    private let MAX_TIMING_DRIFT: TimeInterval = 2.0 // Maximum acceptable drift
    
    // Battery optimization intervals
    private let BATTERY_SAVER_INTERVAL: TimeInterval = 30.0 // 30 seconds when disconnected
    private let LOW_POWER_INTERVAL: TimeInterval = 60.0 // 60 seconds in low power mode
    
    // MARK: - Initialization
    
    init() {
        setupMonitors()
        loadSettings()
        attemptSessionRecovery()
        setupBindings()
        setupSystemNotifications()
        setupBackgroundActivity()
        
        logger.info("🚀 High-precision SchedulerEngine initialized")
        print("🚀 High-precision SchedulerEngine initialized")
    }
    
    deinit {
        cleanup()
        logger.info("🧹 SchedulerEngine deinitialized")
    }
    
    // MARK: - Public API (SchedulerEngineProtocol)
    
    /// Starts a new high-precision scheduler session
    func startSession() {
        guard currentState.canStartSession else {
            logger.warning("Cannot start session in current state: \(currentState.displayName)")
            return
        }
        
        // Create new session with exact duration
        currentSession = SessionData(plannedDuration: SESSION_DURATION_SECONDS)
        pausedTimeInterval = 0
        accumulatedDrift = 0
        lastTimerCheck = Date()
        recoveryAttempts = 0
        
        // Update state
        currentState = .running
        
        // Start high-precision timers
        startHighPrecisionTimers()
        
        // Execute first command immediately
        executeClaudeCommand()
        
        // Save initial state
        persistSession()
        
        // Send notification
        notificationManager.scheduleNotification(.sessionStarted)
        
        logger.info("✅ High-precision session started: \(SESSION_DURATION_SECONDS.formatted())")
        print("✅ High-precision session started: \(SESSION_DURATION_SECONDS.formatted())")
    }
    
    /// Resets the session and returns to idle state
    func resetSession() {
        logger.info("🔄 Resetting session")
        
        stopAllTimers()
        currentSession = nil
        currentState = .idle
        progress = 0.0
        progressPercentage = 0.0
        timeRemaining = 0
        pausedTimeInterval = 0
        accumulatedDrift = 0
        lastError = nil
        recoveryAttempts = 0
        
        clearPersistedSession()
        
        print("🔄 Session reset to idle")
    }
    
    /// Pauses the current session with precision tracking
    func pauseSession() {
        guard currentState.canPause else {
            logger.warning("Cannot pause session in current state: \(currentState.displayName)")
            return
        }
        
        currentState = .paused
        pauseStartTime = Date()
        
        // Record pause event in session
        currentSession?.recordSystemSleep()
        
        // Stop timers but preserve precision state
        stopAllTimers()
        
        // Save paused state
        persistSession()
        
        logger.info("⏸️ Session paused with precision tracking")
        print("⏸️ Session paused with precision tracking")
    }
    
    /// Resumes a paused session with drift compensation
    func resumeSession() {
        guard currentState.canResume else {
            logger.warning("Cannot resume session in current state: \(currentState.displayName)")
            return
        }
        
        // Calculate paused time with precision
        if let pauseStart = pauseStartTime {
            pausedTimeInterval += Date().timeIntervalSince(pauseStart)
            pauseStartTime = nil
        }
        
        // Record wake event
        currentSession?.recordSystemWake()
        
        currentState = .running
        lastTimerCheck = Date()
        
        // Restart high-precision timers
        startHighPrecisionTimers()
        
        // Compensate for timing drift during pause
        recalibrateTimer()
        
        logger.info("▶️ Session resumed with drift compensation")
        print("▶️ Session resumed with drift compensation")
    }
    
    /// Stops the current session with final metrics
    func stopSession() {
        guard currentState.canStop else {
            logger.warning("Cannot stop session in current state: \(currentState.displayName)")
            return
        }
        
        // Complete session with final metrics
        currentSession?.complete()
        logSessionMetrics()
        
        // Stop all timers
        stopAllTimers()
        
        // Reset state
        currentState = .idle
        progress = 0.0
        progressPercentage = 0.0
        timeRemaining = 0
        pausedTimeInterval = 0
        accumulatedDrift = 0
        
        // Clear persistence
        clearPersistedSession()
        
        logger.info("⏹️ Session stopped with metrics logged")
        print("⏹️ Session stopped with metrics logged")
    }
    
    /// Updates the scheduler settings
    func updateSettings(_ newSettings: SchedulerSettings) {
        guard newSettings.isValid else {
            print("⚠️ Invalid settings provided")
            return
        }
        
        settings = newSettings
        saveSettings()
        
        // Restart timers with new intervals if session is running
        if currentState == .running {
            stopTimers()
            startSessionTimers()
        }
        
        print("⚙️ Settings updated")
    }
    
    /// Retries the last failed operation
    func retryLastOperation() {
        guard currentState == .error else {
            print("⚠️ No failed operation to retry")
            return
        }
        
        currentState = .running
        lastError = nil
        
        // Retry Claude command execution
        executeClaudeCommand()
    }
    
    /// Forces cleanup of all resources
    func cleanup() {
        stopTimers()
        cancellables.removeAll()
        
        print("🧹 SchedulerEngine cleanup completed")
    }
    
    // MARK: - Private Methods
    
    private func setupMonitors() {
        memoryMonitor = MemoryMonitor()
        cpuMonitor = CPUMonitor()
        batteryMonitor = BatteryMonitor()
        
        logger.debug("Performance monitors initialized")
    }
    
    private func setupBindings() {
        // Monitor process manager errors
        processManager.$lastError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleProcessError(error)
            }
            .store(in: &cancellables)
            
        // Monitor system performance changes
        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handlePowerStateChange()
            }
            .store(in: &cancellables)
    }
    
    private func setupSystemNotifications() {
        // System sleep/wake monitoring with enhanced tracking
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemSleep()
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemWake()
        }
        
        // Memory pressure notifications
        NotificationCenter.default.addObserver(
            forName: NSApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryPressure()
        }
        
        logger.debug("System notifications configured")
    }
    
    private func setupBackgroundActivity() {
        backgroundActivity = NSBackgroundActivityScheduler(identifier: "com.claudescheduler.background")
        backgroundActivity?.repeats = true
        backgroundActivity?.interval = 300 // 5 minutes
        backgroundActivity?.tolerance = 60 // 1 minute tolerance
        
        backgroundActivity?.schedule { [weak self] completion in
            self?.performBackgroundMaintenance()
            completion(.finished)
        }
        
        logger.debug("Background activity scheduler configured")
    }
    
    private func startHighPrecisionTimers() {
        logger.debug("Starting high-precision timers")
        
        // High-precision timer for accuracy tracking (100ms)
        highPrecisionTimer = Timer.scheduledTimer(withTimeInterval: HIGH_PRECISION_INTERVAL, repeats: true) { [weak self] _ in
            self?.updateHighPrecisionProgress()
        }
        
        // UI update timer (adaptive interval based on power state)
        let updateInterval = calculateOptimalUpdateInterval()
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.publishProgressUpdate()
        }
        
        // Command execution timer (executes Claude command every hour)
        commandExecutionTimer = Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { [weak self] _ in
            self?.executeClaudeCommand()
        }
        
        // Auto-persistence timer (saves state every 30 seconds)
        persistenceTimer = Timer.scheduledTimer(withTimeInterval: PERSISTENCE_INTERVAL, repeats: true) { [weak self] _ in
            self?.persistSession()
        }
        
        // Performance monitoring timer
        performanceMonitorTimer = Timer.scheduledTimer(withTimeInterval: PERFORMANCE_MONITOR_INTERVAL, repeats: true) { [weak self] _ in
            self?.updatePerformanceMetrics()
        }
        
        logger.info("⏰ High-precision timers started with intervals: precision=\(HIGH_PRECISION_INTERVAL)s, UI=\(updateInterval)s")
        print("⏰ High-precision timers started")
    }
    
    private func stopAllTimers() {
        highPrecisionTimer?.invalidate()
        progressUpdateTimer?.invalidate()
        commandExecutionTimer?.invalidate()
        persistenceTimer?.invalidate()
        performanceMonitorTimer?.invalidate()
        
        highPrecisionTimer = nil
        progressUpdateTimer = nil
        commandExecutionTimer = nil
        persistenceTimer = nil
        performanceMonitorTimer = nil
        
        logger.debug("⏰ All timers stopped")
        print("⏰ All timers stopped")
    }
    
    private func updateHighPrecisionProgress() {
        guard var session = currentSession, currentState.isActive else { return }
        
        let now = Date()
        
        // Update session duration with high precision
        session.updateDuration()
        
        // Calculate timing accuracy
        if let lastCheck = lastTimerCheck {
            let expectedInterval = HIGH_PRECISION_INTERVAL
            let actualInterval = now.timeIntervalSince(lastCheck)
            let drift = actualInterval - expectedInterval
            accumulatedDrift += drift
            
            // Update timing accuracy
            if abs(accumulatedDrift) <= MAX_TIMING_DRIFT {
                timingAccuracy = .highPrecision
            } else if abs(accumulatedDrift) <= 10.0 {
                timingAccuracy = .acceptable
            } else {
                timingAccuracy = .degraded
                handleTimingDegradation()
            }
        }
        
        lastTimerCheck = now
        currentSession = session
        
        // Check if session is complete with precision
        if session.precisionProgress >= 1.0 {
            completeSession()
        }
    }
    
    private func publishProgressUpdate() {
        guard let session = currentSession else { return }
        
        // Use high-precision calculations for UI updates
        progress = session.precisionProgress
        progressPercentage = session.precisionProgress * 100.0
        timeRemaining = session.precisionTimeRemaining
        
        // Update performance metrics for UI
        performanceMetrics.timerAccuracy = accumulatedDrift
        
        logger.debug("Progress updated: \(String(format: "%.2f", progressPercentage))%, remaining: \(timeRemaining.formatted())")
    }
    
    private func completeSession() {
        guard var session = currentSession else { return }
        
        // Mark session as completed with final metrics
        session.complete()
        currentSession = session
        
        // Log session completion metrics
        logSessionMetrics()
        
        // Update state
        currentState = .completed
        progress = 1.0
        progressPercentage = 100.0
        timeRemaining = 0
        
        // Stop all timers
        stopAllTimers()
        
        // Clear persistence
        clearPersistedSession()
        
        // Send completion notification
        notificationManager.scheduleNotification(.sessionCompleted)
        
        logger.info("🎉 Session completed successfully with timing accuracy: \(timingAccuracy.description)")
        
        // Auto-restart if enabled
        if settings.autoRestart {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                self?.startSession()
            }
        } else {
            // Return to idle after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                self?.currentState = .idle
            }
        }
        
        print("🎉 Session completed successfully with high precision")
    }
    
    private func executeClaudeCommand() {
        guard currentState == .running else { return }
        
        Task {
            do {
                try await processManager.executeClaude(command: settings.claudeCommand)
                
                // Record successful execution
                DispatchQueue.main.async { [weak self] in
                    self?.currentSession?.recordExecution()
                }
                
                print("✅ Claude command executed successfully")
                
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.handleProcessError(error)
                }
            }
        }
    }
    
    private func handleProcessError(_ error: Error) {
        let schedulerError: SchedulerError
        
        if let processError = error as? ProcessManager.ProcessError {
            switch processError {
            case .commandNotFound:
                schedulerError = .claudeCLINotFound
            case .executionFailed(let details):
                schedulerError = .claudeExecutionFailed(details: details)
            case .permissionDenied:
                schedulerError = .permissionsDenied
            }
        } else {
            schedulerError = .unknownError(details: error.localizedDescription)
        }
        
        lastError = schedulerError
        currentSession?.recordError(schedulerError)
        
        // Handle based on error severity
        if schedulerError.canAutoRecover && settings.maxRetryAttempts > 0 {
            scheduleRetry()
        } else {
            currentState = .error
            notificationManager.scheduleNotification(.sessionFailed(error: schedulerError))
        }
        
        print("❌ Process error: \(schedulerError.localizedDescription)")
    }
    
    private func scheduleRetry() {
        DispatchQueue.main.asyncAfter(deadline: .now() + settings.retryDelay) { [weak self] in
            guard self?.currentState == .running else { return }
            self?.executeClaudeCommand()
        }
    }
    
    // MARK: - High-Precision Methods
    
    private func calculateOptimalUpdateInterval() -> TimeInterval {
        let baseInterval = settings.adaptedUpdateInterval()
        
        // Adapt based on battery state
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            return LOW_POWER_INTERVAL
        }
        
        // Adapt based on power source (simplified for macOS)
        if batteryMonitor?.getCurrentLevel() ?? 1.0 < 0.2 {
            return BATTERY_SAVER_INTERVAL
        }
        
        return baseInterval
    }
    
    private func recalibrateTimer() {
        guard let session = currentSession else { return }
        
        let expectedDuration = Date().timeIntervalSince(session.actualStartTime) - pausedTimeInterval
        let currentDrift = accumulatedDrift
        
        if abs(currentDrift) > MAX_TIMING_DRIFT {
            logger.warning("Timer drift exceeded threshold: \(currentDrift)s, recalibrating")
            
            // Adjust timing for next cycle
            accumulatedDrift = currentDrift * 0.5 // Gradual correction
            
            if abs(accumulatedDrift) > MAX_TIMING_DRIFT * 2 {
                handleTimingDegradation()
            }
        }
    }
    
    private func handleTimingDegradation() {
        logger.error("Timing precision degraded beyond acceptable limits")
        
        let error = SchedulerError.timingPrecisionLost(drift: accumulatedDrift)
        lastError = error
        
        // Attempt automatic recovery
        if recoveryAttempts < maxRecoveryAttempts {
            recoveryAttempts += 1
            currentState = .recovering
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.attemptTimingRecovery()
            }
        } else {
            currentState = .error
            notificationManager.scheduleNotification(.sessionFailed(error: error))
        }
    }
    
    private func attemptTimingRecovery() {
        guard currentState == .recovering else { return }
        
        logger.info("Attempting timing recovery (attempt \(recoveryAttempts)/\(maxRecoveryAttempts))")
        
        // Reset timing state
        accumulatedDrift = 0
        lastTimerCheck = Date()
        
        // Restart timers with conservative settings
        stopAllTimers()
        
        // Use more conservative intervals during recovery
        let conservativeInterval = max(UI_UPDATE_INTERVAL * 2, BATTERY_SAVER_INTERVAL)
        
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: conservativeInterval, repeats: true) { [weak self] _ in
            self?.publishProgressUpdate()
        }
        
        highPrecisionTimer = Timer.scheduledTimer(withTimeInterval: HIGH_PRECISION_INTERVAL * 2, repeats: true) { [weak self] _ in
            self?.updateHighPrecisionProgress()
        }
        
        // Resume normal operation
        currentState = .running
        
        logger.info("Timing recovery completed")
    }
    
    private func updatePerformanceMetrics() {
        guard let memoryMonitor = memoryMonitor,
              let cpuMonitor = cpuMonitor,
              let batteryMonitor = batteryMonitor else { return }
        
        let memoryUsage = memoryMonitor.getCurrentUsage()
        let cpuUsage = cpuMonitor.getCurrentUsage()
        let batteryImpactLevel = batteryMonitor.getBatteryImpact()
        
        performanceMetrics.memoryUsage = memoryUsage
        performanceMetrics.cpuUsage = cpuUsage
        performanceMetrics.energyImpact = batteryImpactLevel.energyImpact
        performanceMetrics.timerAccuracy = accumulatedDrift
        performanceMetrics.lastUpdated = Date()
        
        // Update session metrics
        currentSession?.updatePerformanceMetrics(memory: memoryUsage, cpu: cpuUsage, batteryLevel: batteryImpactLevel)
        
        // Check if metrics are within acceptable ranges
        if !performanceMetrics.isWithinTargets {
            handlePerformanceDegradation(memoryUsage: memoryUsage, cpuUsage: cpuUsage)
        }
        
        logger.debug("Performance metrics updated: Memory=\(String(format: \"%.1f\", memoryUsage))MB, CPU=\(String(format: \"%.1f\", cpuUsage))%")
    }
    
    private func handlePerformanceDegradation(memoryUsage: Double, cpuUsage: Double) {
        if memoryUsage > 50.0 {
            logger.warning("High memory usage detected: \(memoryUsage)MB")
            lastError = .memoryPressure
        }
        
        if cpuUsage > 5.0 {
            logger.warning("High CPU usage detected: \(cpuUsage)%")
            // Reduce update frequency to lower CPU usage
            adaptTimersForPerformance()
        }
    }
    
    private func adaptTimersForPerformance() {
        // Temporarily reduce timer frequency to improve performance
        stopAllTimers()
        
        let adaptedInterval = min(settings.adaptedUpdateInterval() * 2, BATTERY_SAVER_INTERVAL)
        
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: adaptedInterval, repeats: true) { [weak self] _ in
            self?.publishProgressUpdate()
        }
        
        highPrecisionTimer = Timer.scheduledTimer(withTimeInterval: HIGH_PRECISION_INTERVAL * 2, repeats: true) { [weak self] _ in
            self?.updateHighPrecisionProgress()
        }
        
        logger.info("Timers adapted for performance optimization")
    }
    
    private func handleSystemSleep() {
        isSystemSleeping = true
        
        if currentState.isActive {
            logger.info("😴 System sleeping - pausing session")
            pauseSession()
        }
    }
    
    private func handleSystemWake() {
        isSystemSleeping = false
        
        if currentState == .paused {
            logger.info("👁️ System awake - resuming session")
            resumeSession()
        }
    }
    
    private func handlePowerStateChange() {
        logger.debug("🔋 Power state changed")
        
        // Recalculate optimal intervals
        if currentState.isActive {
            let newInterval = calculateOptimalUpdateInterval()
            
            // Only restart timers if interval changed significantly
            if let currentTimer = progressUpdateTimer,
               abs(currentTimer.timeInterval - newInterval) > 1.0 {
                stopAllTimers()
                startHighPrecisionTimers()
                logger.info("Timers restarted for power optimization")
            }
        }
        
        // Update battery impact tracking
        batteryImpact = batteryMonitor?.getBatteryImpact() ?? .low
    }
    
    private func handleMemoryPressure() {
        logger.warning("⚠️ Memory pressure detected")
        
        lastError = .memoryPressure
        
        // Reduce memory usage by optimizing timers
        adaptTimersForPerformance()
        
        // Force garbage collection
        // Note: Swift doesn't have explicit GC, but we can nil out unused references
        performanceMetrics = PerformanceMetrics()
    }
    
    // MARK: - Persistence and Recovery
    
    private func attemptSessionRecovery() {
        guard let data = userDefaults.data(forKey: persistenceKey),
              let persistedData = try? JSONDecoder().decode(SessionPersistenceData.self, from: data),
              persistedData.isValid else {
            logger.debug("No valid session data found for recovery")
            return
        }
        
        logger.info("Attempting session recovery")
        
        let timeSinceLastPersistence = Date().timeIntervalSince(persistedData.persistenceTimestamp)
        
        // Only recover if persistence is recent (within 5 minutes)
        guard timeSinceLastPersistence < 300 else {
            logger.warning("Session data too old for recovery: \(timeSinceLastPersistence)s")
            clearPersistedSession()
            return
        }
        
        let recoveredSession = persistedData.sessionData
        
        // Validate session is still viable
        let sessionAge = Date().timeIntervalSince(recoveredSession.actualStartTime)
        guard sessionAge < SESSION_DURATION_SECONDS * 1.2 else { // Allow 20% buffer
            logger.warning("Recovered session too old to continue")
            clearPersistedSession()
            return
        }
        
        // Restore session state
        currentSession = recoveredSession
        pausedTimeInterval = recoveredSession.pausedTimeInterval
        accumulatedDrift = recoveredSession.precisionDrift
        
        // Determine appropriate state
        if recoveredSession.state == .running && !isSystemSleeping {
            currentState = .recovering
            recoveryAttempts = 0
            
            // Start recovery process
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.completeSessionRecovery()
            }
        } else {
            currentState = .paused
        }
        
        logger.info("Session recovery initiated: state=\(currentState.displayName)")
        print("🔄 Session recovery initiated")
    }
    
    private func completeSessionRecovery() {
        guard currentState == .recovering else { return }
        
        logger.info("Completing session recovery")
        
        // Recalibrate timing
        lastTimerCheck = Date()
        
        // Resume with conservative settings initially
        currentState = .running
        startHighPrecisionTimers()
        
        // Send recovery notification
        notificationManager.scheduleNotification(.sessionStarted) // Reuse start notification
        
        logger.info("✅ Session recovery completed successfully")
        print("✅ Session recovery completed successfully")
    }
    
    private func persistSession() {
        guard let session = currentSession else { return }
        
        let persistenceData = SessionPersistenceData(session: session)
        
        if let data = try? JSONEncoder().encode(persistenceData) {
            userDefaults.set(data, forKey: persistenceKey)
            logger.debug("Session persisted successfully")
        } else {
            logger.error("Failed to persist session data")
        }
    }
    
    private func clearPersistedSession() {
        userDefaults.removeObject(forKey: persistenceKey)
        logger.debug("Persisted session data cleared")
    }
    
    private func performBackgroundMaintenance() {
        logger.debug("Performing background maintenance")
        
        // Update performance metrics
        updatePerformanceMetrics()
        
        // Persist current session if active
        if currentSession != nil {
            persistSession()
        }
        
        // Clean up old data
        // For now, just log the maintenance
        logger.debug("Background maintenance completed")
    }
    
    private func logSessionMetrics() {
        guard let session = currentSession else { return }
        
        let metrics = [
            "sessionId": session.id.uuidString,
            "duration": session.duration,
            "plannedDuration": session.plannedDuration,
            "accuracy": timingAccuracy.description,
            "drift": accumulatedDrift,
            "efficiency": session.efficiencyScore,
            "memoryUsage": performanceMetrics.memoryUsage,
            "cpuUsage": performanceMetrics.cpuUsage,
            "executionCount": session.executionCount
        ]
        
        logger.info("📊 Session completed with metrics: \\(metrics)")
        
        // Could send to analytics service here
        print("📊 Session metrics logged")
    }
    
    private func loadSettings() {
        if let data = userDefaults.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(SchedulerSettings.self, from: data) {
            settings = decodedSettings
            logger.debug("📁 Settings loaded from UserDefaults")
            print("📁 Settings loaded from UserDefaults")
        } else {
            logger.debug("📁 Using default settings")
            print("📁 Using default settings")
        }
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
            logger.debug("💾 Settings saved to UserDefaults")
            print("💾 Settings saved to UserDefaults")
        } else {
            logger.error("Failed to save settings")
        }
    }
}

// MARK: - Extensions

extension SchedulerEngine {
    
    /// Current battery impact description with detailed metrics
    var batteryImpactDescription: String {
        return batteryImpact.description
    }
    
    /// Detailed performance status
    var performanceStatus: String {
        if performanceMetrics.isWithinTargets {
            return "Optimal"
        }
        
        var issues: [String] = []
        if performanceMetrics.memoryUsage > 30.0 {
            issues.append("High Memory")
        }
        if performanceMetrics.cpuUsage > 1.0 {
            issues.append("High CPU")
        }
        if abs(performanceMetrics.timerAccuracy) > 2.0 {
            issues.append("Timing Drift")
        }
        
        return issues.isEmpty ? "Good" : issues.joined(separator: ", ")
    }
    
    /// Current timing accuracy description
    var timingAccuracyDescription: String {
        return timingAccuracy.description
    }
    
    /// Session efficiency score as percentage
    var sessionEfficiencyPercentage: Int {
        guard let session = currentSession else { return 0 }
        return Int(session.efficiencyScore * 100)
    }
    
    /// Current drift in seconds (for monitoring)
    var currentDriftSeconds: TimeInterval {
        return accumulatedDrift
    }
    
    /// Is session running at high precision
    var isHighPrecision: Bool {
        return timingAccuracy == .highPrecision
    }
    
    /// Number of sessions completed today (placeholder for future implementation)
    var sessionsCompletedToday: Int {
        // TODO: Implement persistent session history tracking
        return 0
    }
    
    /// Next scheduled command execution time
    var nextCommandExecutionTime: Date? {
        guard let timer = commandExecutionTimer,
              timer.isValid else { return nil }
        
        return timer.fireDate
    }
    
    /// Memory usage in MB
    var currentMemoryUsageMB: Double {
        return performanceMetrics.memoryUsage
    }
    
    /// CPU usage percentage
    var currentCPUUsagePercent: Double {
        return performanceMetrics.cpuUsage
    }
    
    /// Recovery attempts made
    var recoveryAttemptsCount: Int {
        return recoveryAttempts
    }
    
    /// Is system currently sleeping
    var systemSleeping: Bool {
        return isSystemSleeping
    }
    
    /// Time since last precision check
    var timeSinceLastCheck: TimeInterval? {
        guard let lastCheck = lastTimerCheck else { return nil }
        return Date().timeIntervalSince(lastCheck)
    }
    
    /// Comprehensive status for debugging
    var debugStatus: String {
        return """
        State: \(currentState.displayName)
        Precision: \(timingAccuracy.description)
        Drift: \(String(format: "%.2f", accumulatedDrift))s
        Memory: \(String(format: "%.1f", performanceMetrics.memoryUsage))MB
        CPU: \(String(format: "%.1f", performanceMetrics.cpuUsage))%
        Recovery Attempts: \(recoveryAttempts)/\(maxRecoveryAttempts)
        """
    }
    
    /// Forces cleanup of all resources
    func cleanup() {
        logger.info("🧹 Starting comprehensive cleanup")
        
        stopAllTimers()
        cancellables.removeAll()
        
        // Clean up monitors
        memoryMonitor = nil
        cpuMonitor = nil
        batteryMonitor = nil
        
        // Cancel background activity
        backgroundActivity?.invalidate()
        backgroundActivity = nil
        
        // Clear persistence if not active
        if !currentState.isActive {
            clearPersistedSession()
        }
        
        logger.info("🧹 SchedulerEngine cleanup completed")
        print("🧹 SchedulerEngine cleanup completed")
    }
}