import SwiftUI
import AppKit

// MARK: - ClaudeScheduler Design System Implementation
// Complete SwiftUI components ready for production

// MARK: - Color System
extension Color {
    // State Colors
    static let claudeIdle = Color(NSColor.secondaryLabelColor)
    static let claudeRunning = Color(NSColor.systemBlue)
    static let claudePaused = Color(NSColor.systemOrange)
    static let claudeCompleted = Color(NSColor.systemGreen)
    static let claudeError = Color(NSColor.systemRed)
    static let claudeWarning = Color(NSColor.systemYellow)
    
    // Interface Colors
    static let claudeBackground = Color(NSColor.controlBackgroundColor)
    static let claudeSurface = Color(NSColor.windowBackgroundColor)
    static let claudeSeparator = Color(NSColor.separatorColor)
    
    // Text Hierarchy
    static let claudePrimaryText = Color(NSColor.labelColor)
    static let claudeSecondaryText = Color(NSColor.secondaryLabelColor)
    static let claudeTertiaryText = Color(NSColor.tertiaryLabelColor)
}

// MARK: - Typography System
extension Font {
    // Menu Bar Context
    static let claudeMenuTitle = Font.system(size: 13, weight: .semibold)
    static let claudeMenuBody = Font.system(size: 11, weight: .regular)
    static let claudeMenuCaption = Font.system(size: 9, weight: .regular)
    
    // Settings Window
    static let claudeWindowTitle = Font.system(size: 13, weight: .semibold)
    static let claudeSectionHeader = Font.system(size: 11, weight: .medium)
    static let claudeBodyText = Font.system(size: 11, weight: .regular)
    
    // Status Display
    static let claudeTimer = Font.system(size: 11, weight: .medium, design: .monospaced)
    static let claudeStatusLabel = Font.system(size: 10, weight: .regular)
}

// MARK: - Spacing System
struct ClaudeSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Animation Constants
struct ClaudeAnimation {
    static let microDuration = 0.15
    static let transitionDuration = 0.3
    static let progressDuration = 0.5
    static let successDuration = 0.4
    
    static let easeOut = Animation.easeOut(duration: microDuration)
    static let easeInOut = Animation.easeInOut(duration: transitionDuration)
    static let bouncy = Animation.interpolatingSpring(stiffness: 300, damping: 30)
}

// MARK: - Circular Progress Ring Component
struct CircularProgressRing: View {
    let progress: Double
    let state: SchedulerState
    let size: CGFloat
    
    init(progress: Double, state: SchedulerState, size: CGFloat = 16) {
        self.progress = progress
        self.state = state
        self.size = size
    }
    
    private var ringWidth: CGFloat { size * 0.125 } // 2px for 16px icon
    private var ringRadius: CGFloat { (size - ringWidth) / 2 }
    
    private var progressColor: Color {
        switch state {
        case .idle: return .claudeIdle
        case .running: return .claudeRunning
        case .paused: return .claudePaused
        case .completed: return .claudeCompleted
        case .error: return .claudeError
        }
    }
    
    var body: some View {
        ZStack {
            // Background Ring
            Circle()
                .stroke(Color.claudeIdle.opacity(0.2), lineWidth: ringWidth)
                .frame(width: size, height: size)
            
            // Progress Ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(
                        lineWidth: ringWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90)) // Start from top
                .animation(.easeOut(duration: ClaudeAnimation.progressDuration), value: progress)
            
            // Center Icon
            centerIcon
        }
        .opacity(state == .paused ? pulsingOpacity : 1.0)
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(ClaudeAnimation.easeOut, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    @State private var isHovered = false
    @State private var pulsePhase = 0.0
    
    private var pulsingOpacity: Double {
        if state == .paused {
            return 0.7 + 0.3 * sin(pulsePhase)
        }
        return 1.0
    }
    
    private var centerIcon: some View {
        Group {
            switch state {
            case .idle:
                Image(systemName: "play.fill")
                    .foregroundColor(.claudeIdle)
            case .running:
                Image(systemName: "pause.fill")
                    .foregroundColor(.claudeRunning)
            case .paused:
                Image(systemName: "pause.fill")
                    .foregroundColor(.claudePaused)
            case .completed:
                Image(systemName: "checkmark")
                    .foregroundColor(.claudeCompleted)
                    .scaleEffect(1.15)
                    .animation(ClaudeAnimation.bouncy, value: state)
            case .error:
                Image(systemName: "exclamationmark")
                    .foregroundColor(.claudeError)
            }
        }
        .font(.system(size: size * 0.25, weight: .medium))
        .onAppear {
            if state == .paused {
                withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                    pulsePhase = .pi * 2
                }
            }
        }
    }
}

// MARK: - Scheduler State Enum
enum SchedulerState {
    case idle
    case running
    case paused
    case completed
    case error
    
    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .running: return "Running"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .error: return "Error"
        }
    }
}

// MARK: - Menu Bar Status Item View
struct MenuBarStatusView: View {
    @ObservedObject var scheduler: SchedulerViewModel
    
    var body: some View {
        HStack(spacing: ClaudeSpacing.xs) {
            CircularProgressRing(
                progress: scheduler.progress,
                state: scheduler.state,
                size: 16
            )
            
            if scheduler.state == .running || scheduler.state == .paused {
                Text(scheduler.timeRemainingFormatted)
                    .font(.claudeTimer)
                    .foregroundColor(.claudeSecondaryText)
            }
        }
        .padding(.horizontal, ClaudeSpacing.xs)
    }
}

// MARK: - Context Menu View
struct SchedulerContextMenu: View {
    @ObservedObject var scheduler: SchedulerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            menuHeader
            
            Divider()
                .padding(.vertical, ClaudeSpacing.xs)
            
            // Primary Actions
            primaryActions
            
            Divider()
                .padding(.vertical, ClaudeSpacing.xs)
            
            // Status Information
            statusInformation
            
            Divider()
                .padding(.vertical, ClaudeSpacing.xs)
            
            // Secondary Actions
            secondaryActions
            
            Divider()
                .padding(.vertical, ClaudeSpacing.xs)
            
            // Quit Action
            quitAction
        }
        .padding(.vertical, ClaudeSpacing.sm)
    }
    
    private var menuHeader: some View {
        HStack {
            Text("ClaudeScheduler")
                .font(.claudeMenuTitle)
                .foregroundColor(.claudePrimaryText)
            
            Spacer()
            
            CircularProgressRing(
                progress: scheduler.progress,
                state: scheduler.state,
                size: 20
            )
        }
        .padding(.horizontal, ClaudeSpacing.md)
    }
    
    private var primaryActions: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.xs) {
            switch scheduler.state {
            case .idle:
                MenuButton(
                    title: "Start 5-hour Session",
                    icon: "play.fill",
                    action: scheduler.startSession
                )
            case .running:
                MenuButton(
                    title: "Pause Session",
                    icon: "pause.fill",
                    action: scheduler.pauseSession
                )
                MenuButton(
                    title: "Stop Session",
                    icon: "stop.fill",
                    action: scheduler.stopSession
                )
            case .paused:
                MenuButton(
                    title: "Resume Session",
                    icon: "play.fill",
                    action: scheduler.resumeSession
                )
                MenuButton(
                    title: "Stop Session",
                    icon: "stop.fill",
                    action: scheduler.stopSession
                )
            case .completed:
                MenuButton(
                    title: "Start New Session",
                    icon: "play.fill",
                    action: scheduler.startSession
                )
            case .error:
                MenuButton(
                    title: "Retry Now",
                    icon: "arrow.clockwise",
                    action: scheduler.retryExecution
                )
                MenuButton(
                    title: "View Logs",
                    icon: "doc.text",
                    action: scheduler.showLogs
                )
            }
        }
    }
    
    private var statusInformation: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.xs) {
            if scheduler.state == .running || scheduler.state == .paused {
                StatusInfoRow(
                    icon: "clock",
                    label: "Time Remaining:",
                    value: scheduler.timeRemainingFormatted
                )
            }
            
            StatusInfoRow(
                icon: "target",
                label: "Next Execution:",
                value: scheduler.nextExecutionFormatted
            )
            
            StatusInfoRow(
                icon: "chart.bar",
                label: "Sessions Today:",
                value: "\(scheduler.sessionsToday) completed"
            )
            
            StatusInfoRow(
                icon: "battery.100",
                label: "Battery Impact:",
                value: scheduler.batteryImpact
            )
        }
    }
    
    private var secondaryActions: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.xs) {
            MenuButton(
                title: "Preferences...",
                icon: "gearshape",
                action: scheduler.showPreferences
            )
            MenuButton(
                title: "Session History",
                icon: "clock.arrow.circlepath",
                action: scheduler.showHistory
            )
            MenuButton(
                title: "Help & Support",
                icon: "questionmark.circle",
                action: scheduler.showHelp
            )
        }
    }
    
    private var quitAction: some View {
        MenuButton(
            title: "Quit ClaudeScheduler",
            icon: "xmark.circle",
            isDestructive: true,
            action: scheduler.quitApplication
        )
        .padding(.horizontal, ClaudeSpacing.md)
    }
}

// MARK: - Menu Button Component
struct MenuButton: View {
    let title: String
    let icon: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(title: String, icon: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ClaudeSpacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 16, height: 16)
                
                Text(title)
                    .font(.claudeMenuBody)
                    .foregroundColor(textColor)
                
                Spacer()
            }
            .padding(.horizontal, ClaudeSpacing.md)
            .padding(.vertical, ClaudeSpacing.xs)
            .background(backgroundColor)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(ClaudeAnimation.easeOut) {
                isHovered = hovering
            }
        }
    }
    
    private var backgroundColor: Color {
        if isHovered {
            return Color(NSColor.selectedMenuItemColor)
        }
        return Color.clear
    }
    
    private var textColor: Color {
        if isDestructive {
            return .claudeError
        }
        return isHovered ? Color(NSColor.selectedMenuItemTextColor) : .claudePrimaryText
    }
    
    private var iconColor: Color {
        if isDestructive {
            return .claudeError
        }
        return isHovered ? Color(NSColor.selectedMenuItemTextColor) : .claudeSecondaryText
    }
}

// MARK: - Status Information Row
struct StatusInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: ClaudeSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.claudeSecondaryText)
                .frame(width: 16, height: 16)
            
            Text(label)
                .font(.claudeMenuCaption)
                .foregroundColor(.claudeSecondaryText)
            
            Spacer()
            
            Text(value)
                .font(.claudeMenuCaption)
                .foregroundColor(.claudePrimaryText)
        }
        .padding(.horizontal, ClaudeSpacing.md)
    }
}

// MARK: - Settings Window View
struct SettingsWindow: View {
    @ObservedObject var settings: SettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.lg) {
            // Timer Configuration
            SettingsSection(
                title: "Timer Configuration",
                icon: "clock"
            ) {
                TimerConfigurationView(settings: settings)
            }
            
            // Notifications
            SettingsSection(
                title: "Notifications",
                icon: "bell"
            ) {
                NotificationSettingsView(settings: settings)
            }
            
            // Advanced Settings
            SettingsSection(
                title: "Advanced Settings",
                icon: "gearshape.2"
            ) {
                AdvancedSettingsView(settings: settings)
            }
            
            Spacer()
            
            // Action Buttons
            HStack {
                Spacer()
                
                Button("Cancel", action: settings.cancel)
                    .keyboardShortcut(.cancelAction)
                
                Button("Apply", action: settings.apply)
                    .disabled(!settings.hasChanges)
                
                Button("OK", action: settings.saveAndClose)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!settings.isValid)
            }
            .padding(.top, ClaudeSpacing.md)
        }
        .padding(ClaudeSpacing.lg)
        .frame(width: 480, height: 400)
        .background(Color.claudeSurface)
    }
}

// MARK: - Settings Section Component
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.sm) {
            // Section Header
            HStack(spacing: ClaudeSpacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(.claudeRunning)
                
                Text(title)
                    .font(.claudeSectionHeader)
                    .foregroundColor(.claudePrimaryText)
            }
            
            // Section Content
            VStack(alignment: .leading, spacing: ClaudeSpacing.sm) {
                content
            }
            .padding(ClaudeSpacing.md)
            .background(Color.claudeBackground)
            .cornerRadius(8)
        }
    }
}

// MARK: - Timer Configuration View
struct TimerConfigurationView: View {
    @ObservedObject var settings: SettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.md) {
            // Session Duration
            HStack {
                Text("Session Duration:")
                    .font(.claudeBodyText)
                
                TextField("Hours", value: $settings.sessionHours, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                
                Text("hours")
                    .font(.claudeBodyText)
                
                TextField("Minutes", value: $settings.sessionMinutes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                
                Text("minutes")
                    .font(.claudeBodyText)
                
                Spacer()
            }
            
            // Update Frequency
            VStack(alignment: .leading, spacing: ClaudeSpacing.xs) {
                Text("Update Frequency:")
                    .font(.claudeBodyText)
                
                HStack(spacing: ClaudeSpacing.lg) {
                    RadioButton(
                        title: "1 second",
                        isSelected: settings.updateInterval == 1.0,
                        action: { settings.updateInterval = 1.0 }
                    )
                    
                    RadioButton(
                        title: "5 seconds",
                        isSelected: settings.updateInterval == 5.0,
                        action: { settings.updateInterval = 5.0 }
                    )
                    
                    RadioButton(
                        title: "30 seconds",
                        isSelected: settings.updateInterval == 30.0,
                        action: { settings.updateInterval = 30.0 }
                    )
                    
                    Spacer()
                }
            }
            
            // Auto-restart Option
            Toggle("Start new session after completion", isOn: $settings.autoRestart)
                .font(.claudeBodyText)
            
            // Battery Adaptive Option
            Toggle("Reduce updates in low power mode", isOn: $settings.batteryAdaptive)
                .font(.claudeBodyText)
        }
    }
}

// MARK: - Radio Button Component
struct RadioButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ClaudeSpacing.xs) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .claudeRunning : .claudeSecondaryText)
                
                Text(title)
                    .font(.claudeBodyText)
                    .foregroundColor(.claudePrimaryText)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Models (Protocol Definitions)
// These would be implemented in separate files

protocol SchedulerViewModel: ObservableObject {
    var progress: Double { get }
    var state: SchedulerState { get }
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

// MARK: - Notification Settings (Additional Components)
struct NotificationSettingsView: View {
    @ObservedObject var settings: SettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.sm) {
            Toggle("Session completion alerts", isOn: .constant(true))
                .font(.claudeBodyText)
            
            Toggle("Error notifications", isOn: .constant(true))
                .font(.claudeBodyText)
            
            Toggle("Hourly progress updates", isOn: .constant(false))
                .font(.claudeBodyText)
            
            Toggle("Respect \"Do Not Disturb\" mode", isOn: .constant(true))
                .font(.claudeBodyText)
            
            Toggle("Play notification sounds", isOn: .constant(true))
                .font(.claudeBodyText)
        }
    }
}

struct AdvancedSettingsView: View {
    @ObservedObject var settings: SettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.md) {
            // Claude Command
            VStack(alignment: .leading, spacing: ClaudeSpacing.xs) {
                Text("Claude Command:")
                    .font(.claudeBodyText)
                
                TextField("Command", text: .constant("claude salut ça va -p"))
                    .textFieldStyle(.roundedBorder)
                    .font(.claudeTimer)
            }
            
            // Retry Settings
            HStack {
                Text("Retry Settings:")
                    .font(.claudeBodyText)
                
                Text("Attempts:")
                    .font(.claudeBodyText)
                
                TextField("3", text: .constant("3"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
                
                Text("Delay:")
                    .font(.claudeBodyText)
                
                TextField("30", text: .constant("30"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
                
                Text("seconds")
                    .font(.claudeBodyText)
                
                Spacer()
            }
            
            // System Integration
            Toggle("Launch at login", isOn: .constant(false))
                .font(.claudeBodyText)
            
            Toggle("Show icon in Dock (requires restart)", isOn: .constant(false))
                .font(.claudeBodyText)
        }
    }
}