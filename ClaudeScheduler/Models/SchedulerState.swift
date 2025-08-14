import Foundation
import SwiftUI

/// Represents the current state of the scheduler with enhanced state management
enum SchedulerState: CaseIterable, Equatable {
    case idle
    case running
    case paused
    case completed
    case error
    case recovering  // New state for system recovery
    case backgrounded // New state for background operation
    
    var displayName: String {
        switch self {
        case .idle:
            return "Ready"
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed"
        case .error:
            return "Error"
        case .recovering:
            return "Recovering"
        case .backgrounded:
            return "Background"
        }
    }
    
    var systemIconName: String {
        switch self {
        case .idle:
            return "play.circle"
        case .running:
            return "pause.circle.fill"
        case .paused:
            return "pause.circle"
        case .completed:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .recovering:
            return "arrow.clockwise.circle"
        case .backgrounded:
            return "moon.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .idle:
            return .claudeIdle
        case .running:
            return .claudeRunning
        case .paused:
            return .claudePaused
        case .completed:
            return .claudeCompleted
        case .error:
            return .claudeError
        case .recovering:
            return .claudeWarning
        case .backgrounded:
            return .claudePaused
        }
    }
    
    /// Determines if this state allows starting a new session
    var canStartSession: Bool {
        switch self {
        case .idle, .completed, .error:
            return true
        case .running, .paused, .recovering, .backgrounded:
            return false
        }
    }
    
    /// Determines if this state allows pausing
    var canPause: Bool {
        return self == .running || self == .backgrounded
    }
    
    /// Determines if this state allows resuming
    var canResume: Bool {
        return self == .paused || self == .recovering
    }
    
    /// Determines if this state allows stopping
    var canStop: Bool {
        switch self {
        case .running, .paused, .recovering, .backgrounded:
            return true
        case .idle, .completed, .error:
            return false
        }
    }
    
    /// Determines if this state can transition to background
    var canBackground: Bool {
        return self == .running
    }
    
    /// Determines if this state can recover
    var canRecover: Bool {
        return self == .error || self == .paused
    }
    
    /// Determines if this state is actively processing
    var isActive: Bool {
        switch self {
        case .running, .backgrounded, .recovering:
            return true
        case .idle, .paused, .completed, .error:
            return false
        }
    }
    
    /// State priority for UI updates (higher = more important)
    var priority: Int {
        switch self {
        case .error: return 10
        case .recovering: return 9
        case .completed: return 8
        case .running: return 7
        case .backgrounded: return 6
        case .paused: return 5
        case .idle: return 1
        }
    }
}

/// Represents different types of scheduler errors with enhanced categorization
enum SchedulerError: LocalizedError, Equatable {
    case claudeCLINotFound
    case claudeExecutionFailed(details: String)
    case permissionsDenied
    case networkUnavailable
    case systemSleepInterruption
    case configurationInvalid(reason: String)
    case unknownError(details: String)
    
    // New high-precision timing errors
    case timingPrecisionLost(drift: TimeInterval)
    case backgroundTaskFailed
    case memoryPressure
    case batteryLevelCritical
    case systemResourceUnavailable
    case persistenceCorrupted
    case recoveryFailed(attempts: Int)
    
    var errorDescription: String? {
        switch self {
        case .claudeCLINotFound:
            return "Claude CLI not found"
        case .claudeExecutionFailed(let details):
            return "Claude execution failed: \(details)"
        case .permissionsDenied:
            return "Required permissions not granted"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .systemSleepInterruption:
            return "System sleep interrupted the session"
        case .configurationInvalid(let reason):
            return "Invalid configuration: \(reason)"
        case .unknownError(let details):
            return "Unknown error: \(details)"
        case .timingPrecisionLost(let drift):
            return "Timing precision lost: \(String(format: "%.1f", drift))s drift"
        case .backgroundTaskFailed:
            return "Background task execution failed"
        case .memoryPressure:
            return "System memory pressure detected"
        case .batteryLevelCritical:
            return "Battery level critically low"
        case .systemResourceUnavailable:
            return "Required system resources unavailable"
        case .persistenceCorrupted:
            return "Session persistence data corrupted"
        case .recoveryFailed(let attempts):
            return "Recovery failed after \(attempts) attempts"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .claudeCLINotFound:
            return "Please install Claude CLI using 'npm install -g @anthropic-ai/claude-cli'"
        case .claudeExecutionFailed:
            return "Check your Claude API key and network connection"
        case .permissionsDenied:
            return "Grant necessary permissions in System Preferences"
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .systemSleepInterruption:
            return "Session will resume automatically when system wakes"
        case .configurationInvalid:
            return "Check your settings and try again"
        case .unknownError:
            return "Try restarting ClaudeScheduler"
        case .timingPrecisionLost:
            return "Timer will auto-calibrate. Consider reducing system load"
        case .backgroundTaskFailed:
            return "Enable background app refresh for ClaudeScheduler"
        case .memoryPressure:
            return "Close other applications to free up memory"
        case .batteryLevelCritical:
            return "Connect to power source or enable battery saving mode"
        case .systemResourceUnavailable:
            return "Restart ClaudeScheduler or check system resources"
        case .persistenceCorrupted:
            return "Session data will be reset. Previous sessions may be lost"
        case .recoveryFailed:
            return "Manual intervention required. Please restart the application"
        }
    }
    
    /// Determines if this error can be automatically recovered from
    var canAutoRecover: Bool {
        switch self {
        case .claudeExecutionFailed, .networkUnavailable, .systemSleepInterruption, .timingPrecisionLost, .backgroundTaskFailed, .memoryPressure:
            return true
        case .claudeCLINotFound, .permissionsDenied, .configurationInvalid, .unknownError, .batteryLevelCritical, .systemResourceUnavailable, .persistenceCorrupted, .recoveryFailed:
            return false
        }
    }
    
    /// Error severity level for UI presentation
    var severity: ErrorSeverity {
        switch self {
        case .systemSleepInterruption, .timingPrecisionLost, .memoryPressure:
            return .warning
        case .claudeExecutionFailed, .networkUnavailable, .backgroundTaskFailed, .batteryLevelCritical:
            return .recoverable
        case .claudeCLINotFound, .permissionsDenied, .configurationInvalid, .unknownError, .systemResourceUnavailable, .persistenceCorrupted, .recoveryFailed:
            return .critical
        }
    }
    
    /// Maximum retry attempts for this error type
    var maxRetryAttempts: Int {
        switch self {
        case .claudeExecutionFailed, .networkUnavailable:
            return 5
        case .backgroundTaskFailed, .timingPrecisionLost:
            return 3
        case .memoryPressure, .systemSleepInterruption:
            return 1
        default:
            return 0
        }
    }
    
    /// Recommended retry delay for this error type
    var retryDelay: TimeInterval {
        switch self {
        case .claudeExecutionFailed, .networkUnavailable:
            return 30.0
        case .backgroundTaskFailed:
            return 60.0
        case .timingPrecisionLost, .memoryPressure:
            return 10.0
        case .systemSleepInterruption:
            return 5.0
        default:
            return 0.0
        }
    }
}

/// Error severity levels
enum ErrorSeverity {
    case warning
    case recoverable
    case critical
    
    var color: Color {
        switch self {
        case .warning:
            return .claudeWarning
        case .recoverable:
            return .claudePaused
        case .critical:
            return .claudeError
        }
    }
    
    var iconName: String {
        switch self {
        case .warning:
            return "exclamationmark.triangle"
        case .recoverable:
            return "arrow.clockwise"
        case .critical:
            return "xmark.octagon"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let startNewSession = Notification.Name("com.claudescheduler.startNewSession")
    static let retryFailedOperation = Notification.Name("com.claudescheduler.retryFailedOperation")
    static let resumeSession = Notification.Name("com.claudescheduler.resumeSession")
    static let showSettings = Notification.Name("com.claudescheduler.showSettings")
}