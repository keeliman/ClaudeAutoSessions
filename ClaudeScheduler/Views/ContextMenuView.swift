import SwiftUI

/// Main context menu view that appears when clicking the menu bar icon
/// Provides contextual actions and real-time status information
struct SchedulerContextMenu: View {
    @ObservedObject var scheduler: SchedulerViewModelImpl
    @State private var menuHeight: CGFloat = 200
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dynamic header with real-time info
            menuHeader
                .background(headerBackgroundColor)
            
            MenuDivider()
            
            // Context-sensitive actions
            contextualActions
                .animation(.easeInOut(duration: 0.3), value: scheduler.state)
            
            MenuDivider()
            
            // Real-time status information
            statusSection
                .animation(.easeOut(duration: 0.5), value: scheduler.progress)
            
            MenuDivider()
            
            // Always-available actions
            standardActions
            
            MenuDivider()
            
            // Quit action
            quitAction
        }
        .padding(.vertical, ClaudeSpacing.sm)
        .background(Color.claudeSurface)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .frame(width: 280, height: menuHeight)
        .animation(.easeInOut(duration: 0.2), value: menuHeight)
    }
    
    // MARK: - Header Section
    
    private var menuHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ClaudeScheduler")
                    .font(.claudeMenuTitle)
                    .foregroundColor(.claudePrimaryText)
                
                Text(scheduler.state.displayName)
                    .font(.claudeMenuCaption)
                    .foregroundColor(.claudeSecondaryText)
            }
            
            Spacer()
            
            // Status indicator with progress
            statusIndicator
        }
        .padding(.horizontal, ClaudeSpacing.md)
        .padding(.vertical, ClaudeSpacing.sm)
    }
    
    private var statusIndicator: some View {
        HStack(spacing: ClaudeSpacing.xs) {
            CircularProgressRing(
                progress: scheduler.progress,
                state: scheduler.state,
                size: 20
            )
            
            if scheduler.state == .running || scheduler.state == .paused {
                Text(scheduler.progressPercentage)
                    .font(.claudeMenuCaption)
                    .foregroundColor(.claudeSecondaryText)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: scheduler.progress)
            }
        }
    }
    
    private var headerBackgroundColor: Color {
        Color.claudeBackground.opacity(0.3)
    }
    
    // MARK: - Actions Section
    
    private var contextualActions: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.xs) {
            switch scheduler.state {
            case .idle:
                idleActions
            case .running:
                runningActions
            case .paused:
                pausedActions
            case .completed:
                completedActions
            case .error:
                errorActions
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }
    
    private var idleActions: some View {
        MenuActionButton(
            icon: "play.circle.fill",
            title: "Start 5-hour Session",
            subtitle: scheduler.canStartSession ? "Ready to begin" : "Loading...",
            action: scheduler.startSession,
            isEnabled: scheduler.canStartSession
        )
    }
    
    private var runningActions: some View {
        VStack(spacing: ClaudeSpacing.xs) {
            MenuActionButton(
                icon: "pause.circle.fill",
                title: "Pause Session",
                subtitle: "Temporarily stop the timer",
                action: scheduler.pauseSession
            )
            
            MenuActionButton(
                icon: "stop.circle.fill",
                title: "Stop Session",
                subtitle: "End current session",
                action: scheduler.stopSession,
                isDestructive: true
            )
        }
    }
    
    private var pausedActions: some View {
        VStack(spacing: ClaudeSpacing.xs) {
            MenuActionButton(
                icon: "play.circle.fill",
                title: "Resume Session",
                subtitle: "Continue the timer",
                action: scheduler.resumeSession
            )
            
            MenuActionButton(
                icon: "stop.circle.fill",
                title: "Stop Session",
                subtitle: "End current session",
                action: scheduler.stopSession,
                isDestructive: true
            )
        }
    }
    
    private var completedActions: some View {
        MenuActionButton(
            icon: "play.circle.fill",
            title: "Start New Session",
            subtitle: "Begin another 5-hour session",
            action: scheduler.startSession
        )
    }
    
    private var errorActions: some View {
        VStack(spacing: ClaudeSpacing.xs) {
            if scheduler.canAutoRecover {
                MenuActionButton(
                    icon: "arrow.clockwise.circle.fill",
                    title: "Retry Now",
                    subtitle: "Attempt to recover automatically",
                    action: scheduler.retryExecution
                )
            }
            
            MenuActionButton(
                icon: "doc.text.fill",
                title: "View Error Details",
                subtitle: "See what went wrong",
                action: scheduler.showLogs
            )
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.xs) {
            if scheduler.hasActiveTimers {
                // Live session information
                StatusInfoRow(
                    icon: "clock.fill",
                    label: "Time Remaining:",
                    value: scheduler.timeRemainingFormatted,
                    isLive: true
                )
                
                StatusInfoRow(
                    icon: "target",
                    label: "Next Execution:",
                    value: scheduler.nextExecutionFormatted
                )
                
                // Progress bar for active sessions
                progressBar
            }
            
            StatusInfoRow(
                icon: "chart.bar.fill",
                label: "Sessions Today:",
                value: "\(scheduler.sessionsToday) completed"
            )
            
            StatusInfoRow(
                icon: "battery.100",
                label: "Battery Impact:",
                value: scheduler.batteryImpact,
                valueColor: batteryImpactColor
            )
        }
        .padding(.horizontal, ClaudeSpacing.md)
        .padding(.vertical, ClaudeSpacing.sm)
    }
    
    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.claudeIdle.opacity(0.2))
                        .frame(height: 3)
                        .cornerRadius(1.5)
                    
                    // Progress fill
                    Rectangle()
                        .fill(scheduler.state.color)
                        .frame(width: geometry.size.width * scheduler.progress, height: 3)
                        .cornerRadius(1.5)
                        .animation(.easeOut(duration: 0.5), value: scheduler.progress)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, ClaudeSpacing.md)
    }
    
    private var batteryImpactColor: Color {
        switch scheduler.batteryImpact.lowercased() {
        case let impact where impact.contains("low"), let impact where impact.contains("minimal"):
            return .claudeCompleted
        case let impact where impact.contains("medium"):
            return .claudeWarning
        case let impact where impact.contains("high"):
            return .claudeError
        default:
            return .claudeSecondaryText
        }
    }
    
    // MARK: - Standard Actions
    
    private var standardActions: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.xs) {
            MenuActionButton(
                icon: "gearshape.fill",
                title: "Preferences...",
                action: scheduler.showPreferences
            )
            
            MenuActionButton(
                icon: "clock.arrow.circlepath",
                title: "Session History",
                action: scheduler.showHistory
            )
            
            MenuActionButton(
                icon: "questionmark.circle.fill",
                title: "Help & Support",
                action: scheduler.showHelp
            )
        }
    }
    
    private var quitAction: some View {
        MenuActionButton(
            icon: "xmark.circle.fill",
            title: "Quit ClaudeScheduler",
            action: scheduler.quitApplication,
            isDestructive: true
        )
        .padding(.horizontal, ClaudeSpacing.md)
    }
}

// MARK: - Supporting Views

/// Enhanced menu action button with rich feedback and accessibility
struct MenuActionButton: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    let isDestructive: Bool
    let isEnabled: Bool
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    init(
        icon: String, 
        title: String, 
        subtitle: String? = nil, 
        action: @escaping () -> Void, 
        isDestructive: Bool = false,
        isEnabled: Bool = true
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.isDestructive = isDestructive
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            
            // Haptic feedback simulation with visual feedback
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: ClaudeSpacing.sm) {
                // Icon with state-aware styling
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.claudeMenuBody)
                        .foregroundColor(textColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.claudeMenuCaption)
                            .foregroundColor(.claudeSecondaryText)
                    }
                }
                
                Spacer()
                
                // Loading indicator or chevron
                if !isEnabled {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: .claudeSecondaryText))
                }
            }
            .padding(.horizontal, ClaudeSpacing.md)
            .padding(.vertical, ClaudeSpacing.sm)
            .background(backgroundColor)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isPressed)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering && isEnabled
            }
        }
    }
    
    private var backgroundColor: Color {
        if !isEnabled {
            return Color.clear
        }
        
        if isHovered {
            return Color.claudeAccent.opacity(0.1)
        }
        
        return Color.clear
    }
    
    private var textColor: Color {
        if !isEnabled {
            return .claudeDisabledText
        }
        
        if isDestructive {
            return .claudeError
        }
        
        return .claudePrimaryText
    }
    
    private var iconColor: Color {
        if !isEnabled {
            return .claudeDisabledText
        }
        
        if isDestructive {
            return .claudeError
        }
        
        return isHovered ? .claudeAccent : .claudeSecondaryText
    }
}

/// Status information row with optional live updates
struct StatusInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let isLive: Bool
    let valueColor: Color?
    
    init(icon: String, label: String, value: String, isLive: Bool = false, valueColor: Color? = nil) {
        self.icon = icon
        self.label = label
        self.value = value
        self.isLive = isLive
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack(spacing: ClaudeSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.claudeSecondaryText)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 16, height: 16)
            
            Text(label)
                .font(.claudeMenuCaption)
                .foregroundColor(.claudeSecondaryText)
            
            Spacer()
            
            HStack(spacing: 4) {
                if isLive {
                    // Live indicator
                    Circle()
                        .fill(Color.claudeCompleted)
                        .frame(width: 4, height: 4)
                        .opacity(0.8)
                }
                
                Text(value)
                    .font(.claudeMenuCaption)
                    .foregroundColor(valueColor ?? .claudePrimaryText)
                    .contentTransition(.numericText())
            }
        }
    }
}

/// Custom menu divider with proper spacing
struct MenuDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.claudeSeparator)
            .frame(height: 0.5)
            .padding(.horizontal, ClaudeSpacing.sm)
            .padding(.vertical, ClaudeSpacing.xs)
    }
}

// MARK: - Menu Bar Status View

/// View displayed in the menu bar status item
struct MenuBarStatusView: View {
    @ObservedObject var scheduler: SchedulerViewModelImpl
    
    var body: some View {
        HStack(spacing: ClaudeSpacing.xs) {
            CircularProgressRing(
                progress: scheduler.progress,
                state: scheduler.state,
                size: 16
            )
            .withAccessibility()
            
            if scheduler.hasActiveTimers {
                Text(timeDisplay)
                    .font(.claudeTimer)
                    .foregroundColor(.claudeSecondaryText)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: scheduler.timeRemaining)
            }
        }
        .padding(.horizontal, ClaudeSpacing.xs)
        .help(toolTipText)
    }
    
    private var timeDisplay: String {
        // Show abbreviated format for menu bar
        let totalSeconds = Int(scheduler.timeRemaining)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var toolTipText: String {
        switch scheduler.state {
        case .idle:
            return "ClaudeScheduler - Ready to start"
        case .running:
            return "ClaudeScheduler - Session running (\(scheduler.progressPercentage))"
        case .paused:
            return "ClaudeScheduler - Session paused (\(scheduler.progressPercentage))"
        case .completed:
            return "ClaudeScheduler - Session completed"
        case .error:
            return "ClaudeScheduler - Error occurred"
        }
    }
}

// MARK: - Preview Support

#if DEBUG
#Preview("Context Menu States") {
    VStack(spacing: 20) {
        // Running state
        SchedulerContextMenu(scheduler: {
            let mock = MockSchedulerViewModel()
            mock.state = .running
            mock.progress = 0.45
            return mock as! SchedulerViewModelImpl
        }())
        
        // Error state
        SchedulerContextMenu(scheduler: {
            let mock = MockSchedulerViewModel()
            mock.state = .error
            return mock as! SchedulerViewModelImpl
        }())
    }
}

#Preview("Menu Bar View") {
    HStack(spacing: 20) {
        // Idle
        MenuBarStatusView(scheduler: {
            let mock = MockSchedulerViewModel()
            mock.state = .idle
            return mock as! SchedulerViewModelImpl
        }())
        .background(Color.black.opacity(0.1))
        
        // Running
        MenuBarStatusView(scheduler: {
            let mock = MockSchedulerViewModel()
            mock.state = .running
            return mock as! SchedulerViewModelImpl
        }())
        .background(Color.black.opacity(0.1))
    }
    .padding()
}
#endif