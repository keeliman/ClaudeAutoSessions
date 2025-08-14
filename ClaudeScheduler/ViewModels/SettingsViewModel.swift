import SwiftUI
import Combine
import Foundation

/// Protocol defining the interface for SettingsViewModel
/// This allows for easy testing and dependency injection
protocol SettingsViewModel: ObservableObject {
    var sessionHours: Int { get set }
    var sessionMinutes: Int { get set }
    var updateInterval: Double { get set }
    var autoRestart: Bool { get set }
    var batteryAdaptive: Bool { get set }
    var hasChanges: Bool { get }
    var isValid: Bool { get }
    
    func cancel()
    func apply()
    func saveAndClose()
}

/// ViewModel for the settings/preferences window
/// Manages configuration state and validation
class SettingsViewModelImpl: ObservableObject, SettingsViewModel {
    
    // MARK: - Published Properties
    
    @Published var sessionHours: Int = 5
    @Published var sessionMinutes: Int = 0
    @Published var updateInterval: Double = 5.0
    @Published var autoRestart: Bool = false
    @Published var batteryAdaptive: Bool = true
    @Published var claudeCommand: String = "claude salut ça va -p"
    @Published var maxRetryAttempts: Int = 3
    @Published var retryDelay: Double = 30.0
    @Published var launchAtLogin: Bool = false
    
    // Notification Settings
    @Published var notificationsEnabled: Bool = true
    @Published var sessionCompleteNotifications: Bool = true
    @Published var errorNotifications: Bool = true
    @Published var hourlyProgressNotifications: Bool = false
    @Published var respectDoNotDisturb: Bool = true
    @Published var playNotificationSounds: Bool = true
    @Published var richNotifications: Bool = true
    @Published var customNotificationSounds: Bool = true
    @Published var selectedNotificationSound: EnhancedNotificationManager.CustomSound = .sessionComplete
    
    // UI State
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var validationErrors: [ValidationError] = []
    
    // MARK: - Types
    
    enum ValidationError: LocalizedError {
        case sessionDurationTooShort
        case sessionDurationTooLong
        case updateIntervalTooShort
        case updateIntervalTooLong
        case invalidCommand
        case invalidRetrySettings
        
        var errorDescription: String? {
            switch self {
            case .sessionDurationTooShort:
                return "Session duration must be at least 1 minute"
            case .sessionDurationTooLong:
                return "Session duration cannot exceed 24 hours"
            case .updateIntervalTooShort:
                return "Update interval must be at least 1 second"
            case .updateIntervalTooLong:
                return "Update interval cannot exceed 5 minutes"
            case .invalidCommand:
                return "Command cannot be empty"
            case .invalidRetrySettings:
                return "Invalid retry settings"
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let schedulerEngine: SchedulerEngine
    private var originalSettings: SchedulerSettings
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasChanges: Bool {
        return currentSettings != originalSettings
    }
    
    var isValid: Bool {
        validateSettings()
        return validationErrors.isEmpty
    }
    
    var totalDurationFormatted: String {
        let totalSeconds = sessionHours * 3600 + sessionMinutes * 60
        return TimeInterval(totalSeconds).formatted()
    }
    
    var batteryImpactLevel: BatteryImpactLevel {
        if updateInterval <= 1.0 {
            return .high
        } else if updateInterval <= 5.0 {
            return .medium
        } else if updateInterval <= 30.0 {
            return .low
        } else {
            return .minimal
        }
    }
    
    private var currentSettings: SchedulerSettings {
        var settings = SchedulerSettings()
        settings.sessionDuration = TimeInterval(sessionHours * 3600 + sessionMinutes * 60)
        settings.updateInterval = updateInterval
        settings.autoRestart = autoRestart
        settings.batteryAdaptive = batteryAdaptive
        settings.claudeCommand = claudeCommand
        settings.maxRetryAttempts = maxRetryAttempts
        settings.retryDelay = retryDelay
        settings.launchAtLogin = launchAtLogin
        
        // Notification settings
        settings.notificationsEnabled = notificationsEnabled
        settings.sessionCompleteNotifications = sessionCompleteNotifications
        settings.errorNotifications = errorNotifications
        settings.hourlyProgressNotifications = hourlyProgressNotifications
        settings.respectDoNotDisturb = respectDoNotDisturb
        settings.playNotificationSounds = playNotificationSounds
        
        return settings
    }
    
    // MARK: - Initialization
    
    init(schedulerEngine: SchedulerEngine) {
        self.schedulerEngine = schedulerEngine
        self.originalSettings = schedulerEngine.settings
        
        loadFromSettings(originalSettings)
        setupValidation()
        
        print("⚙️ SettingsViewModel initialized")
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public API
    
    func cancel() {
        // Revert to original settings
        loadFromSettings(originalSettings)
        closeWindow()
    }
    
    func apply() {
        guard isValid else {
            print("⚠️ Cannot apply invalid settings")
            return
        }
        
        isLoading = true
        
        // Apply settings to scheduler engine
        schedulerEngine.updateSettings(currentSettings)
        
        // Update original settings to reflect applied changes
        originalSettings = currentSettings
        
        // Update notification manager
        NotificationManager.shared.updateSettings(currentSettings)
        
        isLoading = false
        
        print("✅ Settings applied successfully")
    }
    
    func saveAndClose() {
        apply()
        closeWindow()
    }
    
    func resetToDefaults() {
        let defaults = SchedulerSettings()
        loadFromSettings(defaults)
        print("🔄 Settings reset to defaults")
    }
    
    // MARK: - Private Methods
    
    private func loadFromSettings(_ settings: SchedulerSettings) {
        sessionHours = settings.sessionHours
        sessionMinutes = settings.sessionMinutes
        updateInterval = settings.updateInterval
        autoRestart = settings.autoRestart
        batteryAdaptive = settings.batteryAdaptive
        claudeCommand = settings.claudeCommand
        maxRetryAttempts = settings.maxRetryAttempts
        retryDelay = settings.retryDelay
        launchAtLogin = settings.launchAtLogin
        
        // Notification settings
        notificationsEnabled = settings.notificationsEnabled
        sessionCompleteNotifications = settings.sessionCompleteNotifications
        errorNotifications = settings.errorNotifications
        hourlyProgressNotifications = settings.hourlyProgressNotifications
        respectDoNotDisturb = settings.respectDoNotDisturb
        playNotificationSounds = settings.playNotificationSounds
    }
    
    private func setupValidation() {
        // Validate settings whenever they change
        Publishers.CombineLatest4(
            $sessionHours,
            $sessionMinutes,
            $updateInterval,
            $claudeCommand
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] _, _, _, _ in
            self?.validateSettings()
        }
        .store(in: &cancellables)
    }
    
    @discardableResult
    private func validateSettings() -> Bool {
        validationErrors.removeAll()
        
        // Validate session duration
        let totalMinutes = sessionHours * 60 + sessionMinutes
        if totalMinutes < 1 {
            validationErrors.append(.sessionDurationTooShort)
        } else if totalMinutes > 24 * 60 {
            validationErrors.append(.sessionDurationTooLong)
        }
        
        // Validate update interval
        if updateInterval < 1.0 {
            validationErrors.append(.updateIntervalTooShort)
        } else if updateInterval > 300.0 { // 5 minutes
            validationErrors.append(.updateIntervalTooLong)
        }
        
        // Validate command
        if claudeCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append(.invalidCommand)
        }
        
        // Validate retry settings
        if maxRetryAttempts < 0 || retryDelay < 0 {
            validationErrors.append(.invalidRetrySettings)
        }
        
        return validationErrors.isEmpty
    }
    
    private func closeWindow() {
        // Close the settings window
        // In a real implementation, this would be handled by a window manager
        print("🪟 Closing settings window")
    }
}

// MARK: - Battery Impact Types

enum BatteryImpactLevel: CaseIterable {
    case minimal
    case low
    case medium
    case high
    
    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: Color {
        switch self {
        case .minimal: return .claudeCompleted
        case .low: return .claudeRunning
        case .medium: return .claudeWarning
        case .high: return .claudeError
        }
    }
    
    var description: String {
        switch self {
        case .minimal: return "Negligible battery usage"
        case .low: return "Low battery impact"
        case .medium: return "Moderate battery usage"
        case .high: return "Higher battery consumption"
        }
    }
}

// MARK: - Update Frequency Options

enum UpdateFrequency: CaseIterable {
    case fast // 1 second
    case normal // 5 seconds
    case slow // 30 seconds
    
    var interval: TimeInterval {
        switch self {
        case .fast: return 1.0
        case .normal: return 5.0
        case .slow: return 30.0
        }
    }
    
    var displayName: String {
        switch self {
        case .fast: return "1 second (High precision)"
        case .normal: return "5 seconds (Recommended)"
        case .slow: return "30 seconds (Battery saving)"
        }
    }
    
    var batteryImpact: BatteryImpactLevel {
        switch self {
        case .fast: return .high
        case .normal: return .low
        case .slow: return .minimal
        }
    }
}

// MARK: - Extensions

extension SettingsViewModelImpl {
    
    /// Returns formatted session duration for display
    var sessionDurationDisplay: String {
        if sessionHours > 0 && sessionMinutes > 0 {
            return "\(sessionHours)h \(sessionMinutes)m"
        } else if sessionHours > 0 {
            return "\(sessionHours)h"
        } else {
            return "\(sessionMinutes)m"
        }
    }
    
    /// Returns appropriate update frequency enum for current interval
    var currentUpdateFrequency: UpdateFrequency {
        switch updateInterval {
        case 1.0:
            return .fast
        case 5.0:
            return .normal
        case 30.0:
            return .slow
        default:
            return .normal
        }
    }
    
    /// Sets update interval from frequency enum
    func setUpdateFrequency(_ frequency: UpdateFrequency) {
        updateInterval = frequency.interval
    }
    
    /// Validation message for current state
    var validationMessage: String? {
        guard let firstError = validationErrors.first else { return nil }
        return firstError.localizedDescription
    }
    
    /// Whether settings can be saved
    var canSave: Bool {
        return hasChanges && isValid && !isLoading
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockSettingsViewModel: ObservableObject, SettingsViewModel {
    @Published var sessionHours: Int = 5
    @Published var sessionMinutes: Int = 0
    @Published var updateInterval: Double = 5.0
    @Published var autoRestart: Bool = false
    @Published var batteryAdaptive: Bool = true
    
    let hasChanges = true
    let isValid = true
    
    func cancel() { print("Cancel") }
    func apply() { print("Apply") }
    func saveAndClose() { print("Save and close") }
}
#endif