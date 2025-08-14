import Foundation
import Combine

/// Represents data for a single scheduler session with high precision timing
struct SessionData: Codable, Identifiable, Equatable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    let plannedDuration: TimeInterval
    var state: SessionState
    var executionCount: Int
    var lastExecutionTime: Date?
    var errorOccurred: SchedulerError?
    
    // High precision timing properties
    var pausedTimeInterval: TimeInterval = 0
    var pauseStartTime: Date?
    var systemSleepEvents: [SystemSleepEvent] = []
    var precisionDrift: TimeInterval = 0 // Tracks accumulated drift
    var lastPrecisionCheck: Date?
    
    // Session metrics
    var actualStartTime: Date
    var targetEndTime: Date
    var estimatedCompletionTime: Date {
        return actualStartTime.addingTimeInterval(plannedDuration)
    }
    
    // Performance metrics
    var memoryUsage: Double = 0
    var cpuUsage: Double = 0
    var batteryImpact: BatteryImpactLevel = .low
    
    init(plannedDuration: TimeInterval = 18000.0) { // Exactly 5 hours in seconds
        self.id = UUID()
        self.startTime = Date()
        self.actualStartTime = Date()
        self.targetEndTime = Date().addingTimeInterval(plannedDuration)
        self.endTime = nil
        self.duration = 0
        self.plannedDuration = plannedDuration
        self.state = .running
        self.executionCount = 0
        self.lastExecutionTime = nil
        self.errorOccurred = nil
        self.lastPrecisionCheck = Date()
    }
    
    /// Current progress as a percentage (0.0 to 1.0) with high precision
    var progress: Double {
        let adjustedDuration = max(0, duration - pausedTimeInterval)
        return min(1.0, adjustedDuration / plannedDuration)
    }
    
    /// High precision progress calculation
    var precisionProgress: Double {
        let now = Date()
        let elapsed = now.timeIntervalSince(actualStartTime) - pausedTimeInterval
        let correctedElapsed = elapsed - precisionDrift
        return min(1.0, max(0, correctedElapsed / plannedDuration))
    }
    
    /// Time remaining in the session with precision adjustment
    var timeRemaining: TimeInterval {
        let adjustedDuration = duration - pausedTimeInterval
        return max(0, plannedDuration - adjustedDuration)
    }
    
    /// High precision time remaining
    var precisionTimeRemaining: TimeInterval {
        let now = Date()
        let elapsed = now.timeIntervalSince(actualStartTime) - pausedTimeInterval - precisionDrift
        return max(0, plannedDuration - elapsed)
    }
    
    /// Whether the session is currently active
    var isActive: Bool {
        return state == .running || state == .paused
    }
    
    /// Whether the session completed successfully
    var isCompleted: Bool {
        return state == .completed && progress >= 1.0
    }
    
    /// Formatted duration string for display
    var durationFormatted: String {
        return TimeInterval.formatDuration(duration)
    }
    
    /// Formatted time remaining string for display
    var timeRemainingFormatted: String {
        return TimeInterval.formatDuration(timeRemaining)
    }
    
    /// Updates the session duration based on current time with precision tracking
    mutating func updateDuration() {
        if state == .running {
            let now = Date()
            duration = now.timeIntervalSince(startTime)
            
            // Update precision drift tracking
            if let lastCheck = lastPrecisionCheck {
                let expectedDuration = now.timeIntervalSince(lastCheck)
                let actualDuration = duration - (duration - expectedDuration)
                precisionDrift += (expectedDuration - actualDuration)
            }
            lastPrecisionCheck = now
        }
    }
    
    /// Records a system sleep event
    mutating func recordSystemSleep() {
        let sleepEvent = SystemSleepEvent(timestamp: Date(), type: .sleep)
        systemSleepEvents.append(sleepEvent)
        
        if state == .running {
            pauseStartTime = Date()
            state = .paused
        }
    }
    
    /// Records a system wake event
    mutating func recordSystemWake() {
        let wakeEvent = SystemSleepEvent(timestamp: Date(), type: .wake)
        systemSleepEvents.append(wakeEvent)
        
        if let pauseStart = pauseStartTime {
            pausedTimeInterval += Date().timeIntervalSince(pauseStart)
            pauseStartTime = nil
        }
        
        if state == .paused {
            state = .running
        }
    }
    
    /// Validates session timing accuracy
    var timingAccuracy: TimingAccuracy {
        let currentDrift = abs(precisionDrift)
        if currentDrift <= 2.0 {
            return .highPrecision
        } else if currentDrift <= 10.0 {
            return .acceptable
        } else {
            return .degraded
        }
    }
    
    /// Updates performance metrics
    mutating func updatePerformanceMetrics(memory: Double, cpu: Double, batteryLevel: BatteryImpactLevel) {
        self.memoryUsage = memory
        self.cpuUsage = cpu
        self.batteryImpact = batteryLevel
    }
    
    /// Calculates session efficiency score (0.0 to 1.0)
    var efficiencyScore: Double {
        let timingScore = timingAccuracy.score
        let performanceScore = (cpuUsage < 1.0 ? 1.0 : max(0, 1.0 - (cpuUsage - 1.0) / 4.0))
        let memoryScore = (memoryUsage < 30.0 ? 1.0 : max(0, 1.0 - (memoryUsage - 30.0) / 70.0))
        
        return (timingScore + performanceScore + memoryScore) / 3.0
    }
    
    /// Marks the session as completed
    mutating func complete() {
        endTime = Date()
        state = .completed
        updateDuration()
    }
    
    /// Records a successful Claude command execution
    mutating func recordExecution() {
        executionCount += 1
        lastExecutionTime = Date()
    }
    
    /// Records an error that occurred during the session
    mutating func recordError(_ error: SchedulerError) {
        errorOccurred = error
        if error.severity == .critical {
            state = .failed
        }
    }
}

/// Possible states of a session
enum SessionState: String, Codable, CaseIterable {
    case running = "running"
    case paused = "paused"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
}

/// User settings for the scheduler
struct SchedulerSettings: Codable {
    var sessionDuration: TimeInterval = 5 * 60 * 60 // 5 hours default
    var updateInterval: TimeInterval = 5.0 // 5 seconds default
    var autoRestart: Bool = false
    var batteryAdaptive: Bool = true
    var claudeCommand: String = "claude salut ça va -p"
    var maxRetryAttempts: Int = 3
    var retryDelay: TimeInterval = 30.0
    var launchAtLogin: Bool = false
    
    // Notification settings
    var notificationsEnabled: Bool = true
    var sessionCompleteNotifications: Bool = true
    var errorNotifications: Bool = true
    var hourlyProgressNotifications: Bool = false
    var respectDoNotDisturb: Bool = true
    var playNotificationSounds: Bool = true
    
    /// Settings validation
    var isValid: Bool {
        return sessionDuration > 0 &&
               updateInterval > 0 &&
               maxRetryAttempts >= 0 &&
               retryDelay >= 0 &&
               !claudeCommand.isEmpty
    }
    
    /// Session duration in hours (for UI binding)
    var sessionHours: Int {
        get { Int(sessionDuration / 3600) }
        set { sessionDuration = TimeInterval(newValue * 3600) + TimeInterval(sessionMinutes * 60) }
    }
    
    /// Session duration in minutes (for UI binding)
    var sessionMinutes: Int {
        get { Int((sessionDuration.truncatingRemainder(dividingBy: 3600)) / 60) }
        set { sessionDuration = TimeInterval(sessionHours * 3600) + TimeInterval(newValue * 60) }
    }
    
    /// Formatted total duration string
    var totalDurationFormatted: String {
        return TimeInterval.formatDuration(sessionDuration)
    }
    
    /// Calculates appropriate update interval based on battery state
    func adaptedUpdateInterval() -> TimeInterval {
        if batteryAdaptive && ProcessInfo.processInfo.isLowPowerModeEnabled {
            return updateInterval * 6 // Reduce frequency in low power mode
        }
        return updateInterval
    }
}

/// System sleep/wake event tracking
struct SystemSleepEvent: Codable {
    let timestamp: Date
    let type: SystemEventType
}

enum SystemEventType: String, Codable {
    case sleep
    case wake
}

/// Timing accuracy levels
enum TimingAccuracy: CaseIterable {
    case highPrecision  // ±2 seconds
    case acceptable     // ±10 seconds
    case degraded       // >10 seconds
    
    var score: Double {
        switch self {
        case .highPrecision: return 1.0
        case .acceptable: return 0.7
        case .degraded: return 0.3
        }
    }
    
    var description: String {
        switch self {
        case .highPrecision: return "High Precision (±2s)"
        case .acceptable: return "Acceptable (±10s)"
        case .degraded: return "Degraded (>10s)"
        }
    }
}

/// Battery impact levels
enum BatteryImpactLevel: String, Codable, CaseIterable {
    case minimal = "minimal"
    case low = "low" 
    case moderate = "moderate"
    case high = "high"
    
    var description: String {
        switch self {
        case .minimal: return "Minimal"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
    
    var energyImpact: Double {
        switch self {
        case .minimal: return 0.1
        case .low: return 0.5
        case .moderate: return 2.0
        case .high: return 5.0
        }
    }
}

/// Session persistence data for recovery
struct SessionPersistenceData: Codable {
    let sessionData: SessionData
    let persistenceTimestamp: Date
    let checksum: String
    
    init(session: SessionData) {
        self.sessionData = session
        self.persistenceTimestamp = Date()
        self.checksum = SessionPersistenceData.calculateChecksum(for: session)
    }
    
    static func calculateChecksum(for session: SessionData) -> String {
        let data = "\(session.id)\(session.startTime.timeIntervalSince1970)\(session.plannedDuration)"
        return data.data(using: .utf8)?.base64EncodedString() ?? ""
    }
    
    var isValid: Bool {
        return checksum == SessionPersistenceData.calculateChecksum(for: sessionData)
    }
}

/// Extension for time formatting utilities
extension TimeInterval {
    static func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    func formatted() -> String {
        return Self.formatDuration(self)
    }
    
    /// Formats with millisecond precision for debugging
    func formattedPrecise() -> String {
        let totalMilliseconds = Int(self * 1000)
        let totalSeconds = totalMilliseconds / 1000
        let milliseconds = totalMilliseconds % 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
        } else {
            return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
        }
    }
}