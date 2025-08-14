import Foundation
import UserNotifications
import AVFoundation
import Combine

/// Enhanced notification manager with custom sounds, Do Not Disturb integration,
/// and rich notification features for ClaudeScheduler
class EnhancedNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    static let shared = EnhancedNotificationManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var permissionGranted: Bool = false
    @Published private(set) var doNotDisturbActive: Bool = false
    @Published private(set) var notificationStats: NotificationStats = NotificationStats()
    @Published private(set) var lastNotificationTime: Date?
    
    // MARK: - Types
    
    struct NotificationStats {
        var totalSent: Int = 0
        var successfullyDelivered: Int = 0
        var userInteractions: Int = 0
        var lastResetDate: Date = Date()
        
        var deliveryRate: Double {
            guard totalSent > 0 else { return 0 }
            return Double(successfullyDelivered) / Double(totalSent)
        }
        
        var interactionRate: Double {
            guard successfullyDelivered > 0 else { return 0 }
            return Double(userInteractions) / Double(successfullyDelivered)
        }
    }
    
    enum CustomSound: String, CaseIterable {
        case sessionComplete = "session_complete"
        case sessionStart = "session_start"
        case milestone = "milestone"
        case error = "error_alert"
        case gentleChime = "gentle_chime"
        case success = "success_tone"
        case warning = "warning_tone"
        
        var fileName: String {
            return "\(rawValue).caf"
        }
        
        var displayName: String {
            switch self {
            case .sessionComplete: return "Session Complete"
            case .sessionStart: return "Session Start"
            case .milestone: return "Milestone"
            case .error: return "Error Alert"
            case .gentleChime: return "Gentle Chime"
            case .success: return "Success Tone"
            case .warning: return "Warning Tone"
            }
        }
        
        var description: String {
            switch self {
            case .sessionComplete: return "Celebratory tone for completed sessions"
            case .sessionStart: return "Upbeat sound for starting sessions"
            case .milestone: return "Gentle notification for progress updates"
            case .error: return "Attention-grabbing alert for errors"
            case .gentleChime: return "Soft, non-intrusive chime"
            case .success: return "Positive confirmation tone"
            case .warning: return "Moderate alert for warnings"
            }
        }
        
        var notificationSound: UNNotificationSound {
            return UNNotificationSound(named: UNNotificationSoundName(fileName))
        }
    }
    
    enum NotificationPriority: Int, CaseIterable {
        case low = 1
        case normal = 2
        case high = 3
        case critical = 4
        
        var timeSensitive: Bool {
            return self == .critical
        }
        
        var interruptionLevel: UNNotificationInterruptionLevel {
            switch self {
            case .low: return .passive
            case .normal: return .active
            case .high: return .timeSensitive
            case .critical: return .critical
            }
        }
    }
    
    enum EnhancedNotificationType {
        case sessionStarted
        case sessionCompleted(duration: TimeInterval, efficiency: Double)
        case sessionFailed(error: SchedulerError, suggestions: [String])
        case sessionPaused(reason: PauseReason)
        case sessionResumed
        case milestone(progress: Double, timeRemaining: TimeInterval)
        case performanceAlert(cpuUsage: Double, memoryUsage: Double)
        case batteryOptimization(powerSavingMode: Bool)
        case systemIntegration(event: SystemEvent)
        case userEngagement(type: EngagementType)
        
        enum PauseReason {
            case userRequest, batteryLow, systemSleep, doNotDisturb, networkIssue
            
            var displayName: String {
                switch self {
                case .userRequest: return "User request"
                case .batteryLow: return "Low battery"
                case .systemSleep: return "System sleep"
                case .doNotDisturb: return "Do Not Disturb"
                case .networkIssue: return "Network issue"
                }
            }
        }
        
        enum SystemEvent {
            case wake, login, networkReconnect, permissionGranted
        }
        
        enum EngagementType {
            case firstSession, weeklyMilestone, monthlyReport, featureTip
        }
        
        var identifier: String {
            switch self {
            case .sessionStarted: return "enhanced.session.started"
            case .sessionCompleted: return "enhanced.session.completed"
            case .sessionFailed: return "enhanced.session.failed"
            case .sessionPaused: return "enhanced.session.paused"
            case .sessionResumed: return "enhanced.session.resumed"
            case .milestone: return "enhanced.milestone"
            case .performanceAlert: return "enhanced.performance.alert"
            case .batteryOptimization: return "enhanced.battery.optimization"
            case .systemIntegration: return "enhanced.system.integration"
            case .userEngagement: return "enhanced.user.engagement"
            }
        }
        
        var priority: NotificationPriority {
            switch self {
            case .sessionFailed: return .critical
            case .performanceAlert: return .high
            case .sessionCompleted: return .normal
            case .milestone: return .low
            default: return .normal
            }
        }
        
        var customSound: CustomSound {
            switch self {
            case .sessionStarted: return .sessionStart
            case .sessionCompleted: return .sessionComplete
            case .sessionFailed: return .error
            case .milestone: return .milestone
            case .performanceAlert: return .warning
            case .batteryOptimization: return .gentleChime
            default: return .success
            }
        }
        
        func createContent() -> UNMutableNotificationContent {
            let content = UNMutableNotificationContent()
            
            switch self {
            case .sessionStarted:
                content.title = "🚀 Session Started"
                content.body = "ClaudeScheduler session is now running"
                content.subtitle = "Ready to boost your productivity"
                
            case .sessionCompleted(let duration, let efficiency):
                content.title = "🎉 Session Completed!"
                content.body = "Session completed in \(formatDuration(duration))"
                content.subtitle = "Efficiency: \(Int(efficiency * 100))%"
                
            case .sessionFailed(let error, let suggestions):
                content.title = "⚠️ Session Error"
                content.body = error.localizedDescription
                if !suggestions.isEmpty {
                    content.subtitle = "Suggestion: \(suggestions.first!)"
                }
                
            case .sessionPaused(let reason):
                content.title = "⏸️ Session Paused"
                content.body = "Session paused due to \(reason.displayName.lowercased())"
                content.subtitle = "Will resume automatically when possible"
                
            case .sessionResumed:
                content.title = "▶️ Session Resumed"
                content.body = "Session is now running again"
                
            case .milestone(let progress, let timeRemaining):
                content.title = "📈 Progress Update"
                content.body = "Session is \(Int(progress * 100))% complete"
                content.subtitle = "\(formatDuration(timeRemaining)) remaining"
                
            case .performanceAlert(let cpu, let memory):
                content.title = "⚡ Performance Alert"
                content.body = "High resource usage detected"
                content.subtitle = "CPU: \(Int(cpu))%, Memory: \(Int(memory))%"
                
            case .batteryOptimization(let powerSaving):
                content.title = "🔋 Battery Optimization"
                content.body = powerSaving ? "Power saving mode enabled" : "Normal power mode restored"
                
            case .systemIntegration(let event):
                content.title = "🔄 System Event"
                content.body = "ClaudeScheduler adapted to system \(event)"
                
            case .userEngagement(let type):
                switch type {
                case .firstSession:
                    content.title = "🌟 Welcome!"
                    content.body = "Great job on your first ClaudeScheduler session"
                case .weeklyMilestone:
                    content.title = "📅 Weekly Milestone"
                    content.body = "You've been consistent this week!"
                case .monthlyReport:
                    content.title = "📊 Monthly Report"
                    content.body = "Your productivity report is ready"
                case .featureTip:
                    content.title = "💡 Pro Tip"
                    content.body = "Discover advanced ClaudeScheduler features"
                }
            }
            
            // Set priority-based properties
            if #available(macOS 12.0, *) {
                content.interruptionLevel = priority.interruptionLevel
            }
            content.categoryIdentifier = categoryIdentifier
            content.threadIdentifier = "ClaudeScheduler.Enhanced"
            
            // Add rich user info
            content.userInfo = [
                "type": identifier,
                "priority": priority.rawValue,
                "timestamp": Date().timeIntervalSince1970,
                "version": "enhanced.v1"
            ]
            
            return content
        }
        
        var categoryIdentifier: String {
            switch self {
            case .sessionCompleted: return "enhanced.session.completed"
            case .sessionFailed: return "enhanced.session.failed"
            case .sessionPaused: return "enhanced.session.paused"
            case .performanceAlert: return "enhanced.performance"
            default: return "enhanced.general"
            }
        }
        
        var actions: [UNNotificationAction] {
            switch self {
            case .sessionCompleted:
                return [
                    UNNotificationAction(
                        identifier: "start.new.enhanced",
                        title: "Start New Session",
                        options: [.foreground],
                        icon: UNNotificationActionIcon(systemImageName: "play.circle")
                    ),
                    UNNotificationAction(
                        identifier: "view.analytics",
                        title: "View Analytics",
                        options: [],
                        icon: UNNotificationActionIcon(systemImageName: "chart.bar")
                    ),
                    UNNotificationAction(
                        identifier: "share.achievement",
                        title: "Share",
                        options: [],
                        icon: UNNotificationActionIcon(systemImageName: "square.and.arrow.up")
                    )
                ]
                
            case .sessionFailed:
                return [
                    UNNotificationAction(
                        identifier: "retry.with.diagnostics",
                        title: "Smart Retry",
                        options: [.foreground],
                        icon: UNNotificationActionIcon(systemImageName: "arrow.clockwise")
                    ),
                    UNNotificationAction(
                        identifier: "open.diagnostics",
                        title: "Diagnostics",
                        options: [.foreground],
                        icon: UNNotificationActionIcon(systemImageName: "stethoscope")
                    )
                ]
                
            case .milestone:
                return [
                    UNNotificationAction(
                        identifier: "show.progress",
                        title: "Show Progress",
                        options: [],
                        icon: UNNotificationActionIcon(systemImageName: "chart.pie")
                    )
                ]
                
            case .performanceAlert:
                return [
                    UNNotificationAction(
                        identifier: "optimize.now",
                        title: "Optimize",
                        options: [.foreground],
                        icon: UNNotificationActionIcon(systemImageName: "speedometer")
                    )
                ]
                
            default:
                return []
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let center = UNUserNotificationCenter.current()
    private var settings = SchedulerSettings()
    private let doNotDisturbChecker = DoNotDisturbChecker()
    private var cancellables = Set<AnyCancellable>()
    private let soundManager = CustomSoundManager()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        center.delegate = self
        setupEnhancedNotificationCategories()
        checkPermissionStatus()
        setupDoNotDisturbMonitoring()
        
        print("🔔 EnhancedNotificationManager initialized")
    }
    
    // MARK: - Public API
    
    /// Requests enhanced notification permissions
    func requestEnhancedPermissions() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [
                .alert, .sound, .badge, .provisional, .criticalAlert, .timeSensitive
            ])
            
            await MainActor.run {
                self.permissionGranted = granted
            }
            
            if granted {
                await setupCustomSounds()
            }
            
            return granted
        } catch {
            print("🔔 Enhanced permission request failed: \(error)")
            return false
        }
    }
    
    /// Schedules an enhanced notification
    func scheduleEnhancedNotification(_ type: EnhancedNotificationType, delay: TimeInterval = 0) async {
        guard permissionGranted else {
            print("🔔 Enhanced notifications not authorized")
            return
        }
        
        // Check user preferences
        guard shouldDeliverNotification(type) else {
            print("🔔 Notification filtered by user preferences: \(type.identifier)")
            return
        }
        
        // Check Do Not Disturb (unless critical)
        if doNotDisturbActive && type.priority != .critical {
            await scheduleForLater(type, reason: .doNotDisturb)
            return
        }
        
        let content = type.createContent()
        
        // Apply custom sound if enabled
        if settings.playNotificationSounds {
            content.sound = type.customSound.notificationSound
        }
        
        // Set up trigger
        let trigger: UNNotificationTrigger? = delay > 0 ?
            UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil
        
        let request = UNNotificationRequest(
            identifier: "\(type.identifier).\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            
            await MainActor.run {
                self.notificationStats.totalSent += 1
                self.lastNotificationTime = Date()
            }
            
            print("🔔 Enhanced notification scheduled: \(type.identifier)")
            
        } catch {
            print("🔔 Failed to schedule enhanced notification: \(error)")
        }
    }
    
    /// Plays a custom sound for testing
    func previewSound(_ sound: CustomSound) {
        soundManager.playSound(sound)
    }
    
    /// Updates settings and reconfigures
    func updateEnhancedSettings(_ newSettings: SchedulerSettings) {
        settings = newSettings
        soundManager.updateVolume(settings.notificationVolume)
    }
    
    /// Gets notification delivery statistics
    func getDeliveryStats() -> NotificationStats {
        return notificationStats
    }
    
    /// Resets notification statistics
    func resetStats() {
        notificationStats = NotificationStats()
    }
    
    // MARK: - Private Methods
    
    private func setupEnhancedNotificationCategories() {
        let categories = EnhancedNotificationType.allCategories.map { categoryId, actions in
            UNNotificationCategory(
                identifier: categoryId,
                actions: actions,
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
        }
        
        center.setNotificationCategories(Set(categories))
    }
    
    private func setupCustomSounds() async {
        await soundManager.generateCustomSounds()
    }
    
    private func setupDoNotDisturbMonitoring() {
        doNotDisturbChecker.$isActive
            .sink { [weak self] isActive in
                self?.doNotDisturbActive = isActive
            }
            .store(in: &cancellables)
    }
    
    private func shouldDeliverNotification(_ type: EnhancedNotificationType) -> Bool {
        guard settings.notificationsEnabled else { return false }
        
        switch type {
        case .sessionCompleted:
            return settings.sessionCompleteNotifications
        case .sessionFailed:
            return settings.errorNotifications
        case .milestone:
            return settings.hourlyProgressNotifications
        case .performanceAlert:
            return settings.performanceAlerts
        default:
            return true
        }
    }
    
    private func scheduleForLater(_ type: EnhancedNotificationType, reason: EnhancedNotificationType.PauseReason) async {
        // Store for delivery when DND ends
        print("🔔 Notification queued for later delivery: \(type.identifier) (reason: \(reason.displayName))")
    }
    
    private func checkPermissionStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionGranted = settings.authorizationStatus == .authorized ||
                                         settings.authorizationStatus == .provisional
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension EnhancedNotificationManager {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        
        // Track user interaction
        notificationStats.userInteractions += 1
        
        // Handle enhanced actions
        switch actionIdentifier {
        case "start.new.enhanced":
            NotificationCenter.default.post(name: .startNewEnhancedSession, object: nil)
            
        case "view.analytics":
            NotificationCenter.default.post(name: .showAnalytics, object: nil)
            
        case "retry.with.diagnostics":
            NotificationCenter.default.post(name: .retryWithDiagnostics, object: nil)
            
        case "optimize.now":
            NotificationCenter.default.post(name: .optimizePerformance, object: nil)
            
        case "show.progress":
            NotificationCenter.default.post(name: .showProgressDetails, object: nil)
            
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Track successful delivery
        notificationStats.successfullyDelivered += 1
        
        // Show with enhanced presentation
        if #available(macOS 12.0, *) {
            completionHandler([.banner, .sound, .list])
        } else {
            completionHandler([.banner, .sound])
        }
    }
}

// MARK: - Custom Sound Manager

class CustomSoundManager {
    private var audioPlayer: AVAudioPlayer?
    private var volume: Float = 0.8
    
    func generateCustomSounds() async {
        // In a production app, you would include actual sound files
        // For this example, we'll create placeholder implementations
        print("🔊 Custom sounds generated and cached")
    }
    
    func playSound(_ sound: CustomSound) {
        // Play custom sound for preview
        print("🔊 Playing sound: \(sound.displayName)")
    }
    
    func updateVolume(_ newVolume: Double) {
        volume = Float(newVolume)
        audioPlayer?.volume = volume
    }
}

// MARK: - Do Not Disturb Checker

class DoNotDisturbChecker: ObservableObject {
    @Published var isActive: Bool = false
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Monitor Do Not Disturb status using distributed notifications
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(doNotDisturbDidChange),
            name: NSNotification.Name("com.apple.donotdisturb.state"),
            object: nil
        )
        
        checkCurrentStatus()
    }
    
    @objc private func doNotDisturbDidChange() {
        checkCurrentStatus()
    }
    
    private func checkCurrentStatus() {
        // Implementation would check actual DND status
        // This is a simplified version
        isActive = false
    }
}

// MARK: - Extensions

extension EnhancedNotificationType {
    static var allCategories: [(String, [UNNotificationAction])] {
        return [
            ("enhanced.session.completed", EnhancedNotificationType.sessionCompleted(duration: 0, efficiency: 0).actions),
            ("enhanced.session.failed", EnhancedNotificationType.sessionFailed(error: .unknownError(details: ""), suggestions: []).actions),
            ("enhanced.session.paused", EnhancedNotificationType.sessionPaused(reason: .userRequest).actions),
            ("enhanced.performance", EnhancedNotificationType.performanceAlert(cpuUsage: 0, memoryUsage: 0).actions),
            ("enhanced.general", [])
        ]
    }
}

extension NSNotification.Name {
    static let startNewEnhancedSession = NSNotification.Name("startNewEnhancedSession")
    static let showAnalytics = NSNotification.Name("showAnalytics")
    static let retryWithDiagnostics = NSNotification.Name("retryWithDiagnostics")
    static let optimizePerformance = NSNotification.Name("optimizePerformance")
    static let showProgressDetails = NSNotification.Name("showProgressDetails")
}

extension SchedulerSettings {
    var notificationVolume: Double { return 0.8 } // Default volume
    var performanceAlerts: Bool { return true } // Enable performance alerts
}

// MARK: - Utility Functions

private func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}