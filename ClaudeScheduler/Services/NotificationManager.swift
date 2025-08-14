import Foundation
import UserNotifications
import Combine

/// Manages system notifications for ClaudeScheduler
/// Handles permission requests, notification scheduling, and user interactions
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var permissionGranted: Bool = false
    @Published private(set) var lastNotificationTime: Date?
    @Published private(set) var notificationsSent: Int = 0
    
    // MARK: - Types
    
    enum NotificationType {
        case sessionStarted
        case sessionCompleted
        case sessionFailed(error: SchedulerError)
        case sessionPaused
        case sessionResumed
        case batteryPause
        case systemWake
        case milestone(progress: Double)
        
        var identifier: String {
            switch self {
            case .sessionStarted:
                return "session.started"
            case .sessionCompleted:
                return "session.completed"
            case .sessionFailed:
                return "session.failed"
            case .sessionPaused:
                return "session.paused"
            case .sessionResumed:
                return "session.resumed"
            case .batteryPause:
                return "battery.paused"
            case .systemWake:
                return "system.wake"
            case .milestone(let progress):
                return "milestone.\(Int(progress * 100))"
            }
        }
        
        var title: String {
            switch self {
            case .sessionStarted:
                return "Session Started"
            case .sessionCompleted:
                return "Session Completed! 🎉"
            case .sessionFailed:
                return "Session Error ⚠️"
            case .sessionPaused:
                return "Session Paused"
            case .sessionResumed:
                return "Session Resumed"
            case .batteryPause:
                return "Session Paused 🔋"
            case .systemWake:
                return "Session Resumed"
            case .milestone(let progress):
                return "Progress Update"
            }
        }
        
        var body: String {
            switch self {
            case .sessionStarted:
                return "ClaudeScheduler session has started successfully"
            case .sessionCompleted:
                return "5-hour session completed successfully. Ready for next session."
            case .sessionFailed(let error):
                return error.localizedDescription
            case .sessionPaused:
                return "Timer has been paused. Resume when ready."
            case .sessionResumed:
                return "Timer has been resumed and is running."
            case .batteryPause:
                return "Session paused due to low battery mode. Will resume automatically."
            case .systemWake:
                return "Session resumed after system wake."
            case .milestone(let progress):
                return "Session is \(Int(progress * 100))% complete"
            }
        }
        
        var sound: UNNotificationSound? {
            switch self {
            case .sessionCompleted:
                return .default
            case .sessionFailed:
                return .defaultCritical
            case .batteryPause, .systemWake:
                return nil // Silent for battery/system events
            default:
                return .default
            }
        }
        
        var actions: [UNNotificationAction] {
            switch self {
            case .sessionCompleted:
                return [
                    UNNotificationAction(
                        identifier: "start.new",
                        title: "Start New Session",
                        options: [.foreground]
                    ),
                    UNNotificationAction(
                        identifier: "view.stats",
                        title: "View Statistics",
                        options: []
                    )
                ]
            case .sessionFailed:
                return [
                    UNNotificationAction(
                        identifier: "retry.now",
                        title: "Retry Now",
                        options: [.foreground]
                    ),
                    UNNotificationAction(
                        identifier: "open.settings",
                        title: "Open Settings",
                        options: [.foreground]
                    )
                ]
            case .sessionPaused:
                return [
                    UNNotificationAction(
                        identifier: "resume.session",
                        title: "Resume",
                        options: [.foreground]
                    )
                ]
            default:
                return []
            }
        }
        
        var categoryIdentifier: String {
            switch self {
            case .sessionCompleted:
                return "session.completed.category"
            case .sessionFailed:
                return "session.failed.category"
            case .sessionPaused:
                return "session.paused.category"
            default:
                return "general.category"
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let center = UNUserNotificationCenter.current()
    private var settings = SchedulerSettings()
    private let rateLimitInterval: TimeInterval = 300 // 5 minutes minimum between notifications
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        center.delegate = self
        setupNotificationCategories()
        checkPermissionStatus()
        
        print("🔔 NotificationManager initialized")
    }
    
    // MARK: - Public API
    
    /// Requests notification permissions from the user
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                
                if let error = error {
                    print("🔔 Notification permission error: \(error.localizedDescription)")
                }
                
                completion(granted)
            }
        }
    }
    
    /// Schedules a notification for the specified type
    func scheduleNotification(_ type: NotificationType) {
        guard permissionGranted else {
            print("🔔 Notification permission not granted")
            return
        }
        
        // Check settings to see if this type of notification is enabled
        guard isNotificationTypeEnabled(type) else {
            print("🔔 Notification type disabled in settings: \(type.identifier)")
            return
        }
        
        // Rate limiting - prevent spam
        if let lastTime = lastNotificationTime,
           Date().timeIntervalSince(lastTime) < rateLimitInterval &&
           !type.isCritical {
            print("🔔 Rate limited notification: \(type.identifier)")
            return
        }
        
        // Check Do Not Disturb
        if settings.respectDoNotDisturb && isDoNotDisturbActive() {
            print("🔔 Do Not Disturb active - skipping notification")
            return
        }
        
        let content = createNotificationContent(for: type)
        let request = UNNotificationRequest(
            identifier: type.identifier,
            content: content,
            trigger: nil // Immediate delivery
        )
        
        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🔔 Failed to schedule notification: \(error.localizedDescription)")
                } else {
                    self?.lastNotificationTime = Date()
                    self?.notificationsSent += 1
                    print("🔔 Notification scheduled: \(type.identifier)")
                }
            }
        }
    }
    
    /// Updates notification settings
    func updateSettings(_ newSettings: SchedulerSettings) {
        settings = newSettings
    }
    
    /// Cancels all pending notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        print("🔔 All notifications cancelled")
    }
    
    /// Cancels specific notification
    func cancelNotification(_ type: NotificationType) {
        center.removePendingNotificationRequests(withIdentifiers: [type.identifier])
        print("🔔 Notification cancelled: \(type.identifier)")
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationCategories() {
        let categories: [UNNotificationCategory] = [
            UNNotificationCategory(
                identifier: "session.completed.category",
                actions: NotificationType.sessionCompleted.actions,
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: "session.failed.category",
                actions: NotificationType.sessionFailed(error: .unknownError(details: "")).actions,
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: "session.paused.category",
                actions: NotificationType.sessionPaused.actions,
                intentIdentifiers: [],
                options: []
            )
        ]
        
        center.setNotificationCategories(Set(categories))
    }
    
    private func createNotificationContent(for type: NotificationType) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        content.title = type.title
        content.body = type.body
        content.sound = settings.playNotificationSounds ? type.sound : nil
        content.categoryIdentifier = type.categoryIdentifier
        content.threadIdentifier = "ClaudeScheduler"
        
        // Add custom data
        content.userInfo = [
            "type": type.identifier,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        return content
    }
    
    private func isNotificationTypeEnabled(_ type: NotificationType) -> Bool {
        guard settings.notificationsEnabled else { return false }
        
        switch type {
        case .sessionCompleted:
            return settings.sessionCompleteNotifications
        case .sessionFailed:
            return settings.errorNotifications
        case .milestone:
            return settings.hourlyProgressNotifications
        default:
            return true
        }
    }
    
    private func checkPermissionStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionGranted = settings.authorizationStatus == .authorized ||
                                         settings.authorizationStatus == .provisional
            }
        }
    }
    
    private func isDoNotDisturbActive() -> Bool {
        // Check if system Do Not Disturb is active
        // Note: This is a simplified check - full implementation would use
        // private APIs or heuristics to detect DND status
        return false
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let notificationIdentifier = response.notification.request.identifier
        
        print("🔔 Notification action: \(actionIdentifier) for \(notificationIdentifier)")
        
        // Handle notification actions
        switch actionIdentifier {
        case "start.new":
            NotificationCenter.default.post(name: .startNewSession, object: nil)
            
        case "retry.now":
            NotificationCenter.default.post(name: .retryFailedOperation, object: nil)
            
        case "resume.session":
            NotificationCenter.default.post(name: .resumeSession, object: nil)
            
        case "open.settings":
            NotificationCenter.default.post(name: .showSettings, object: nil)
            
        case "view.stats":
            NotificationCenter.default.post(name: .showStatistics, object: nil)
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            NotificationCenter.default.post(name: .showMainInterface, object: nil)
            
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
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}

// MARK: - Extensions

extension NotificationType {
    
    var isCritical: Bool {
        switch self {
        case .sessionFailed:
            return true
        default:
            return false
        }
    }
    
    var priority: Int {
        switch self {
        case .sessionFailed:
            return 3 // High priority
        case .sessionCompleted:
            return 2 // Medium priority
        default:
            return 1 // Normal priority
        }
    }
}

// MARK: - Notification Names

extension NSNotification.Name {
    static let startNewSession = NSNotification.Name("startNewSession")
    static let retryFailedOperation = NSNotification.Name("retryFailedOperation")
    static let resumeSession = NSNotification.Name("resumeSession")
    static let showSettings = NSNotification.Name("showSettings")
    static let showStatistics = NSNotification.Name("showStatistics")
    static let showMainInterface = NSNotification.Name("showMainInterface")
}