import SwiftUI
import AppKit
import Combine

/// Enhanced menu bar controller with polish features, micro-interactions, and advanced functionality
class EnhancedMenuBarController: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem?
    private var enhancedHostingView: NSHostingView<EnhancedMenuBarView>?
    private var contextMenuHostingView: NSHostingView<EnhancedContextMenuView>?
    private var settingsWindowController: NSWindowController?
    private var performanceMonitorController: NSWindowController?
    private var aboutWindowController: NSWindowController?
    
    private let schedulerEngine: SchedulerEngine
    private var schedulerViewModel: SchedulerViewModelImpl
    private var settingsViewModel: SettingsViewModelImpl
    private let launchAtLoginService = LaunchAtLoginService()
    private let enhancedNotificationManager = EnhancedNotificationManager.shared
    private let performanceMonitor = RealTimePerformanceMonitor()
    
    private var cancellables = Set<AnyCancellable>()
    private var keyboardShortcutMonitor: Any?
    
    // State management
    @Published private(set) var isVisible = true
    @Published private(set) var isDarkMode = false
    @Published private(set) var systemAppearance: NSAppearance.Name = .aqua
    
    // MARK: - Initialization
    
    init(schedulerEngine: SchedulerEngine) {
        self.schedulerEngine = schedulerEngine
        self.schedulerViewModel = SchedulerViewModelImpl(schedulerEngine: schedulerEngine)
        self.settingsViewModel = SettingsViewModelImpl(schedulerEngine: schedulerEngine)
        
        super.init()
        
        setupStatusItem()
        setupKeyboardShortcuts()
        setupNotificationObservers()
        setupAppearanceMonitoring()
        setupBindings()
        
        print("🚀 EnhancedMenuBarController initialized with all polish features")
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup Methods
    
    private func setupStatusItem() {
        // Create status item with enhanced configuration
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else {
            fatalError("Failed to create enhanced status item")
        }
        
        // Create enhanced SwiftUI view for the menu bar
        let enhancedMenuBarView = EnhancedMenuBarView(viewModel: schedulerViewModel)
        enhancedHostingView = NSHostingView(rootView: enhancedMenuBarView)
        enhancedHostingView?.frame = NSRect(x: 0, y: 0, width: 28, height: 22)
        
        // Configure status item button
        configureStatusItemButton()
        
        // Set up advanced interactions
        setupAdvancedInteractions()
        
        print("✨ Enhanced menu bar status item created with micro-interactions")
    }
    
    private func configureStatusItemButton() {
        guard let button = statusItem?.button,
              let hostingView = enhancedHostingView else { return }
        
        // Add hosting view to button
        button.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup enhanced constraints
        NSLayoutConstraint.activate([
            hostingView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            hostingView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            hostingView.widthAnchor.constraint(equalToConstant: 28),
            hostingView.heightAnchor.constraint(equalToConstant: 22)
        ])
        
        // Configure button properties
        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        // Enable accessibility
        button.cell?.accessibilityElement = true
        button.cell?.accessibilityRole = .button
        button.cell?.accessibilityLabel = "ClaudeScheduler"
    }
    
    private func setupAdvancedInteractions() {
        guard let button = statusItem?.button else { return }
        
        // Add tracking area for hover effects
        let trackingArea = NSTrackingArea(
            rect: button.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        button.addTrackingArea(trackingArea)
        
        // Setup gesture recognizers
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        guard let button = statusItem?.button else { return }
        
        // Long press gesture for quick settings
        let longPressGesture = NSPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        button.addGestureRecognizer(longPressGesture)
        
        // Double-click gesture for performance monitor
        let doubleClickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleClick(_:)))
        doubleClickGesture.numberOfClicksRequired = 2
        button.addGestureRecognizer(doubleClickGesture)
    }
    
    private func setupKeyboardShortcuts() {
        // Global keyboard shortcuts
        keyboardShortcutMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
        }
        
        print("⌨️ Global keyboard shortcuts enabled")
    }
    
    private func setupNotificationObservers() {
        let notificationCenter = NotificationCenter.default
        
        // Enhanced context menu requests
        notificationCenter.addObserver(
            self,
            selector: #selector(showEnhancedContextMenu),
            name: .showEnhancedContextMenu,
            object: nil
        )
        
        // Performance monitor requests
        notificationCenter.addObserver(
            self,
            selector: #selector(showPerformanceMonitor),
            name: .showPerformanceMonitor,
            object: nil
        )
        
        // Settings window requests
        notificationCenter.addObserver(
            self,
            selector: #selector(showSettings),
            name: .showSettings,
            object: nil
        )
        
        // About panel requests
        notificationCenter.addObserver(
            self,
            selector: #selector(showAboutPanel),
            name: .showAboutPanel,
            object: nil
        )
        
        // System notifications
        notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    private func setupAppearanceMonitoring() {
        // Monitor system appearance changes
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(systemAppearanceChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
        
        updateAppearanceState()
    }
    
    private func setupBindings() {
        // Scheduler state changes
        schedulerViewModel.$state
            .combineLatest(schedulerViewModel.$progress)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] state, progress in
                self?.updateEnhancedMenuBarAppearance(state: state, progress: progress)
                self?.updateNotificationState(state: state, progress: progress)
            }
            .store(in: &cancellables)
        
        // Performance monitoring
        performanceMonitor.$currentMetrics
            .throttle(for: .seconds(5), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] metrics in
                self?.handlePerformanceUpdate(metrics)
            }
            .store(in: &cancellables)
        
        // Settings changes
        settingsViewModel.$launchAtLogin
            .sink { [weak self] enabled in
                self?.handleLaunchAtLoginChange(enabled)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Event Handlers
    
    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        
        switch event.type {
        case .rightMouseUp:
            showContextMenu()
        case .leftMouseUp:
            if event.modifierFlags.contains(.option) {
                showSettings()
            } else if event.modifierFlags.contains(.command) {
                showPerformanceMonitor()
            } else {
                handlePrimaryClick()
            }
        default:
            break
        }
    }
    
    @objc private func handleLongPress(_ gesture: NSPressGestureRecognizer) {
        if gesture.state == .began {
            provideTactileFeedback(.medium)
            showQuickSettings()
        }
    }
    
    @objc private func handleDoubleClick(_ gesture: NSClickGestureRecognizer) {
        provideTactileFeedback(.light)
        showPerformanceMonitor()
    }
    
    private func handlePrimaryClick() {
        provideTactileFeedback(.light)
        
        switch schedulerViewModel.state {
        case .idle:
            schedulerViewModel.startSession()
            scheduleEnhancedNotification(.sessionStarted)
        case .running:
            schedulerViewModel.pauseSession()
            scheduleEnhancedNotification(.sessionPaused(reason: .userRequest))
        case .paused:
            schedulerViewModel.resumeSession()
            scheduleEnhancedNotification(.sessionResumed)
        case .completed:
            schedulerViewModel.resetSession()
        case .error:
            schedulerViewModel.retrySession()
        }
    }
    
    private func handleGlobalKeyEvent(_ event: NSEvent) {
        // Command+Shift+C for ClaudeScheduler toggle
        if event.modifierFlags.contains([.command, .shift]) &&
           event.keyCode == 8 { // 'C' key
            handlePrimaryClick()
        }
        
        // Command+Shift+S for Settings
        if event.modifierFlags.contains([.command, .shift]) &&
           event.keyCode == 1 { // 'S' key
            showSettings()
        }
        
        // Command+Shift+P for Performance Monitor
        if event.modifierFlags.contains([.command, .shift]) &&
           event.keyCode == 35 { // 'P' key
            showPerformanceMonitor()
        }
    }
    
    // MARK: - Window Management
    
    @objc private func showEnhancedContextMenu() {
        showContextMenu()
    }
    
    private func showContextMenu() {
        guard let statusItem = statusItem else { return }
        
        let contextMenuView = EnhancedContextMenuView(
            scheduler: schedulerViewModel,
            settings: settingsViewModel,
            performanceMonitor: performanceMonitor
        )
        
        contextMenuHostingView = NSHostingView(rootView: contextMenuView)
        
        let menu = NSMenu()
        let menuItem = NSMenuItem()
        menuItem.view = contextMenuHostingView
        menu.addItem(menuItem)
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            statusItem.menu = nil
        }
    }
    
    private func showQuickSettings() {
        // Show a compact quick settings panel
        let quickSettingsView = QuickSettingsView(settings: settingsViewModel)
        let hostingView = NSHostingView(rootView: quickSettingsView)
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.utilityWindow, .closable, .titled],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "Quick Settings"
        panel.contentView = hostingView
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        
        // Auto-close after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            panel.close()
        }
    }
    
    @objc private func showSettings() {
        if settingsWindowController == nil {
            let settingsWindow = SettingsWindow(settings: settingsViewModel)
            let hostingView = NSHostingView(rootView: settingsWindow)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 450),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            
            window.title = "ClaudeScheduler Settings"
            window.contentView = hostingView
            window.center()
            window.isReleasedWhenClosed = false
            
            settingsWindowController = NSWindowController(window: window)
        }
        
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func showPerformanceMonitor() {
        if performanceMonitorController == nil {
            let performanceView = PerformanceMonitoringView()
            let hostingView = NSHostingView(rootView: performanceView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            window.title = "Performance Monitor"
            window.contentView = hostingView
            window.center()
            window.isReleasedWhenClosed = false
            
            performanceMonitorController = NSWindowController(window: window)
        }
        
        performanceMonitorController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func showAboutPanel() {
        if aboutWindowController == nil {
            let aboutView = AboutPanelView()
            let hostingView = NSHostingView(rootView: aboutView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            
            window.title = "About ClaudeScheduler"
            window.contentView = hostingView
            window.center()
            window.isReleasedWhenClosed = false
            
            aboutWindowController = NSWindowController(window: window)
        }
        
        aboutWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - State Updates
    
    private func updateEnhancedMenuBarAppearance(state: SchedulerState, progress: Double) {
        // Update tooltip with rich information
        statusItem?.button?.toolTip = generateEnhancedToolTip(state: state, progress: progress)
        
        // Update accessibility
        updateAccessibilityProperties(state: state, progress: progress)
        
        // The EnhancedMenuBarView will automatically update via @Published properties
    }
    
    private func updateNotificationState(state: SchedulerState, progress: Double) {
        // Send enhanced notifications for state changes
        switch state {
        case .completed:
            scheduleEnhancedNotification(.sessionCompleted(
                duration: schedulerEngine.settings.sessionDuration,
                efficiency: calculateSessionEfficiency()
            ))
        case .error:
            if let lastError = schedulerEngine.lastError {
                scheduleEnhancedNotification(.sessionFailed(
                    error: lastError,
                    suggestions: generateErrorSuggestions(lastError)
                ))
            }
        default:
            break
        }
        
        // Send milestone notifications
        if state == .running && shouldSendMilestoneNotification(progress) {
            scheduleEnhancedNotification(.milestone(
                progress: progress,
                timeRemaining: schedulerViewModel.timeRemaining
            ))
        }
    }
    
    private func handlePerformanceUpdate(_ metrics: RealTimePerformanceMonitor.PerformanceMetrics) {
        // Check for performance alerts
        if metrics.cpuUsage > 80 || metrics.memoryUsage > 150 {
            scheduleEnhancedNotification(.performanceAlert(
                cpuUsage: metrics.cpuUsage,
                memoryUsage: metrics.memoryUsage
            ))
        }
        
        // Battery optimization notifications
        if metrics.powerState == .lowPower {
            scheduleEnhancedNotification(.batteryOptimization(powerSavingMode: true))
        }
    }
    
    private func handleLaunchAtLoginChange(_ enabled: Bool) {
        Task {
            await launchAtLoginService.setEnabled(enabled)
        }
    }
    
    // MARK: - System Event Handlers
    
    @objc private func systemWillSleep() {
        print("💤 System will sleep - pausing session if running")
        if schedulerViewModel.state == .running {
            schedulerViewModel.pauseSession()
        }
    }
    
    @objc private func systemDidWake() {
        print("⏰ System did wake - resuming session if paused")
        scheduleEnhancedNotification(.systemIntegration(event: .wake))
    }
    
    @objc private func systemAppearanceChanged() {
        updateAppearanceState()
        print("🎨 System appearance changed to \(systemAppearance.rawValue)")
    }
    
    // MARK: - Utility Methods
    
    private func updateAppearanceState() {
        if let appearance = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            systemAppearance = appearance
            isDarkMode = (appearance == .darkAqua)
        }
    }
    
    private func updateAccessibilityProperties(state: SchedulerState, progress: Double) {
        guard let button = statusItem?.button else { return }
        
        button.cell?.accessibilityValue = "\(Int(progress * 100))% complete"
        button.cell?.accessibilityHelp = generateAccessibilityHelp(state: state)
    }
    
    private func generateEnhancedToolTip(state: SchedulerState, progress: Double) -> String {
        let baseTooltip = generateBaseToolTip(state: state, progress: progress)
        let shortcuts = generateShortcutHelp()
        return "\(baseTooltip)\n\n\(shortcuts)"
    }
    
    private func generateBaseToolTip(state: SchedulerState, progress: Double) -> String {
        switch state {
        case .idle:
            return "ClaudeScheduler - Ready\nClick to start session"
        case .running:
            let remaining = formatTimeRemaining(schedulerViewModel.timeRemaining)
            return "Session Running (\(Int(progress * 100))%)\n\(remaining) remaining\nClick to pause"
        case .paused:
            return "Session Paused (\(Int(progress * 100))%)\nClick to resume"
        case .completed:
            return "Session Completed! 🎉\nClick to start new session"
        case .error:
            return "Session Error\nClick to retry"
        }
    }
    
    private func generateShortcutHelp() -> String {
        return """
        Shortcuts:
        ⌘⇧C - Toggle session
        ⌘⇧S - Settings
        ⌘⇧P - Performance Monitor
        ⌥+Click - Settings
        ⌘+Click - Performance
        Right-click - Context menu
        """
    }
    
    private func generateAccessibilityHelp(state: SchedulerState) -> String {
        switch state {
        case .idle: return "Click to start a productivity session"
        case .running: return "Session in progress, click to pause"
        case .paused: return "Session paused, click to resume"
        case .completed: return "Session finished, click to start new one"
        case .error: return "Error occurred, click to retry"
        }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func provideTactileFeedback(_ intensity: NSHapticFeedbackManager.FeedbackPattern) {
        NSHapticFeedbackManager.defaultPerformer.perform(intensity, performanceTime: .default)
    }
    
    private func scheduleEnhancedNotification(_ type: EnhancedNotificationManager.EnhancedNotificationType) {
        Task {
            await enhancedNotificationManager.scheduleEnhancedNotification(type)
        }
    }
    
    private func calculateSessionEfficiency() -> Double {
        // Simplified efficiency calculation
        return 0.95 // 95% efficiency
    }
    
    private func generateErrorSuggestions(_ error: SchedulerError) -> [String] {
        switch error {
        case .claudeCommandFailed:
            return ["Check Claude CLI installation", "Verify network connection"]
        case .processExecutionFailed:
            return ["Restart ClaudeScheduler", "Check system permissions"]
        default:
            return ["Try restarting the session", "Check system logs"]
        }
    }
    
    private func shouldSendMilestoneNotification(_ progress: Double) -> Bool {
        // Send notifications at 25%, 50%, 75% milestones
        let milestones: [Double] = [0.25, 0.5, 0.75]
        return milestones.contains { abs($0 - progress) < 0.01 }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        statusItem = nil
        enhancedHostingView = nil
        contextMenuHostingView = nil
        settingsWindowController = nil
        performanceMonitorController = nil
        aboutWindowController = nil
        
        if let monitor = keyboardShortcutMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        NotificationCenter.default.removeObserver(self)
        DistributedNotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
        
        print("🧹 EnhancedMenuBarController cleanup completed")
    }
}

// MARK: - Enhanced Context Menu View

struct EnhancedContextMenuView: View {
    @ObservedObject var scheduler: SchedulerViewModelImpl
    @ObservedObject var settings: SettingsViewModelImpl
    @ObservedObject var performanceMonitor: RealTimePerformanceMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with current status
            contextMenuHeader
            
            Divider()
            
            // Main actions
            contextMenuActions
            
            Divider()
            
            // Performance summary
            performanceSummary
            
            Divider()
            
            // Settings and utilities
            settingsSection
        }
        .frame(width: 280)
        .background(Color(.menuBackgroundColor))
    }
    
    private var contextMenuHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("ClaudeScheduler")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(scheduler.state.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(scheduler.state.color.opacity(0.2))
                    .foregroundColor(scheduler.state.color)
                    .cornerRadius(4)
            }
            
            if scheduler.state == .running {
                HStack {
                    Text("Progress: \(Int(scheduler.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTimeRemaining(scheduler.timeRemaining))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var contextMenuActions: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(availableActions, id: \.title) { action in
                Button(action: action.action) {
                    HStack {
                        Image(systemName: action.icon)
                            .frame(width: 16)
                        
                        Text(action.title)
                            .font(.system(size: 13))
                        
                        Spacer()
                        
                        if let shortcut = action.shortcut {
                            Text(shortcut)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onHover { hovering in
                    // Add hover effect
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var performanceSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Performance")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
            
            HStack {
                PerformanceIndicator(
                    label: "CPU",
                    value: String(format: "%.1f%%", performanceMonitor.currentMetrics.cpuUsage),
                    color: performanceMonitor.currentMetrics.cpuUsage > 50 ? .orange : .green
                )
                
                PerformanceIndicator(
                    label: "RAM",
                    value: String(format: "%.0fMB", performanceMonitor.currentMetrics.memoryUsage),
                    color: performanceMonitor.currentMetrics.memoryUsage > 100 ? .red : .blue
                )
                
                PerformanceIndicator(
                    label: "Battery",
                    value: performanceMonitor.currentMetrics.batteryImpact.displayName,
                    color: performanceMonitor.currentMetrics.batteryImpact.color
                )
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 6)
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button("Settings...") {
                NotificationCenter.default.post(name: .showSettings, object: nil)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            
            Button("Performance Monitor...") {
                NotificationCenter.default.post(name: .showPerformanceMonitor, object: nil)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            
            Button("About ClaudeScheduler") {
                NotificationCenter.default.post(name: .showAboutPanel, object: nil)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            
            Divider()
            
            Button("Quit ClaudeScheduler") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .padding(.vertical, 4)
    }
    
    private var availableActions: [ContextAction] {
        switch scheduler.state {
        case .idle:
            return [
                ContextAction(title: "Start Session", icon: "play.fill", shortcut: "⌘⇧C") {
                    scheduler.startSession()
                }
            ]
        case .running:
            return [
                ContextAction(title: "Pause Session", icon: "pause.fill", shortcut: "⌘⇧C") {
                    scheduler.pauseSession()
                },
                ContextAction(title: "Stop Session", icon: "stop.fill", shortcut: nil) {
                    scheduler.stopSession()
                }
            ]
        case .paused:
            return [
                ContextAction(title: "Resume Session", icon: "play.fill", shortcut: "⌘⇧C") {
                    scheduler.resumeSession()
                },
                ContextAction(title: "Stop Session", icon: "stop.fill", shortcut: nil) {
                    scheduler.stopSession()
                }
            ]
        case .completed:
            return [
                ContextAction(title: "Start New Session", icon: "plus.circle.fill", shortcut: "⌘⇧C") {
                    scheduler.resetSession()
                    scheduler.startSession()
                }
            ]
        case .error:
            return [
                ContextAction(title: "Retry Session", icon: "arrow.clockwise", shortcut: "⌘⇧C") {
                    scheduler.retrySession()
                }
            ]
        }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct ContextAction {
    let title: String
    let icon: String
    let shortcut: String?
    let action: () -> Void
}

struct PerformanceIndicator: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickSettingsView: View {
    @ObservedObject var settings: SettingsViewModelImpl
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Auto-restart sessions", isOn: $settings.autoRestart)
                Toggle("Battery-adaptive updates", isOn: $settings.batteryAdaptive)
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                Toggle("Rich notifications", isOn: $settings.richNotifications)
            }
            
            Button("Open Full Settings") {
                NotificationCenter.default.post(name: .showSettings, object: nil)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
    }
}

// MARK: - Extension for State Display

extension SchedulerState {
    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .running: return "Running"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .error: return "Error"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .secondary
        case .running: return .blue
        case .paused: return .orange
        case .completed: return .green
        case .error: return .red
        }
    }
}

// MARK: - Notification Names

extension NSNotification.Name {
    static let showPerformanceMonitor = NSNotification.Name("showPerformanceMonitor")
    static let showAboutPanel = NSNotification.Name("showAboutPanel")
}