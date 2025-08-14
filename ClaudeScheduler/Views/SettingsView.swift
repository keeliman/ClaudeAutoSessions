import SwiftUI
import Combine

/// Main settings window view with tabbed interface and live preview
struct SettingsWindow: View {
    @ObservedObject var settings: SettingsViewModelImpl
    @State private var selectedTab: SettingsTab = .timer
    
    enum SettingsTab: CaseIterable {
        case timer, notifications, advanced, about
        
        var title: String {
            switch self {
            case .timer: return "Timer"
            case .notifications: return "Notifications"
            case .advanced: return "Advanced"
            case .about: return "About"
            }
        }
        
        var icon: String {
            switch self {
            case .timer: return "clock"
            case .notifications: return "bell"
            case .advanced: return "gearshape.2"
            case .about: return "info.circle"
            }
        }
    }
    
    var body: some View {
        HSplitView {
            // Settings sidebar
            settingsSidebar
                .frame(minWidth: 150, maxWidth: 200)
            
            // Main content area
            settingsContent
                .frame(minWidth: 320, maxWidth: .infinity)
        }
        .frame(width: 600, height: 450)
        .background(Color.claudeSurface)
    }
    
    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                SettingsSidebarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
            
            Spacer()
            
            // Action buttons at bottom
            VStack(spacing: ClaudeSpacing.xs) {
                Button("Reset to Defaults") {
                    settings.resetToDefaults()
                }
                .buttonStyle(.borderless)
                .font(.claudeBodyText)
                .foregroundColor(.claudeSecondaryText)
            }
            .padding(ClaudeSpacing.md)
        }
        .background(Color.claudeBackground)
    }
    
    private var settingsContent: some View {
        VStack {
            // Content area
            Group {
                switch selectedTab {
                case .timer:
                    TimerSettingsView(settings: settings)
                case .notifications:
                    NotificationSettingsView(settings: settings)
                case .advanced:
                    AdvancedSettingsView(settings: settings)
                case .about:
                    AboutPanelView()
                }
            }
            .padding(ClaudeSpacing.lg)
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            Spacer()
            
            // Bottom action bar
            actionBar
        }
    }
    
    private var actionBar: some View {
        HStack {
            // Validation message
            if let validationMessage = settings.validationMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.claudeWarning)
                    Text(validationMessage)
                        .font(.claudeBodyText)
                        .foregroundColor(.claudeWarning)
                }
            }
            
            Spacer()
            
            HStack(spacing: ClaudeSpacing.sm) {
                Button("Cancel", action: settings.cancel)
                    .keyboardShortcut(.cancelAction)
                
                Button("Apply", action: settings.apply)
                    .disabled(!settings.hasChanges || !settings.isValid)
                
                Button("OK", action: settings.saveAndClose)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!settings.canSave)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(ClaudeSpacing.md)
        .background(Color.claudeBackground.opacity(0.5))
    }
}

// MARK: - Sidebar Item

struct SettingsSidebarItem: View {
    let tab: SettingsWindow.SettingsTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ClaudeSpacing.sm) {
                Image(systemName: tab.icon)
                    .foregroundColor(isSelected ? .claudeAccent : .claudeSecondaryText)
                    .frame(width: 16, height: 16)
                
                Text(tab.title)
                    .font(.claudeBodyText)
                    .foregroundColor(isSelected ? .claudePrimaryText : .claudeSecondaryText)
                
                Spacer()
            }
            .padding(.horizontal, ClaudeSpacing.md)
            .padding(.vertical, ClaudeSpacing.sm)
            .background(isSelected ? Color.claudeSelection : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Timer Settings

struct TimerSettingsView: View {
    @ObservedObject var settings: SettingsViewModelImpl
    @State private var previewProgress: Double = 0.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ClaudeSpacing.lg) {
                // Section header with preview
                sectionHeader
                
                Divider()
                
                // Session Duration Controls
                sessionDurationSection
                
                // Update Frequency with Battery Impact
                updateFrequencySection
                
                Divider()
                
                // Additional Options
                additionalOptionsSection
            }
        }
    }
    
    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Timer Configuration")
                    .font(.claudeWindowTitle)
                
                Text("Configure session duration and update frequency")
                    .font(.claudeBodyText)
                    .foregroundColor(.claudeSecondaryText)
            }
            
            Spacer()
            
            // Live preview of settings
            VStack(alignment: .trailing, spacing: 4) {
                Text("Preview")
                    .font(.claudeStatusLabel)
                    .foregroundColor(.claudeSecondaryText)
                
                CircularProgressRing(
                    progress: previewProgress,
                    state: .running,
                    size: 32
                )
                .onAppear {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        previewProgress = 1.0
                    }
                }
            }
        }
    }
    
    private var sessionDurationSection: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.md) {
            Text("Session Duration")
                .font(.claudeSectionHeader)
            
            HStack(spacing: ClaudeSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hours")
                        .font(.claudeBodyText)
                        .foregroundColor(.claudeSecondaryText)
                    
                    TextField("5", value: $settings.sessionHours, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Minutes")
                        .font(.claudeBodyText)
                        .foregroundColor(.claudeSecondaryText)
                    
                    TextField("0", value: $settings.sessionMinutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
                
                Spacer()
                
                // Duration summary
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Duration")
                        .font(.claudeBodyText)
                        .foregroundColor(.claudeSecondaryText)
                    
                    Text(settings.totalDurationFormatted)
                        .font(.claudeTimer)
                        .foregroundColor(.claudePrimaryText)
                }
            }
        }
    }
    
    private var updateFrequencySection: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.md) {
            HStack {
                Text("Update Frequency")
                    .font(.claudeSectionHeader)
                
                Spacer()
                
                BatteryImpactIndicator(level: settings.batteryImpactLevel)
            }
            
            VStack(alignment: .leading, spacing: ClaudeSpacing.sm) {
                ForEach(UpdateFrequency.allCases, id: \.self) { frequency in
                    FrequencyOption(
                        frequency: frequency,
                        isSelected: settings.currentUpdateFrequency == frequency,
                        action: { settings.setUpdateFrequency(frequency) }
                    )
                }
            }
        }
    }
    
    private var additionalOptionsSection: some View {
        VStack(alignment: .leading, spacing: ClaudeSpacing.sm) {
            Toggle("Auto-restart sessions", isOn: $settings.autoRestart)
                .font(.claudeBodyText)
            
            Toggle("Battery-adaptive updates", isOn: $settings.batteryAdaptive)
                .font(.claudeBodyText)
                .help("Reduces update frequency when in low power mode")
        }
    }
}

// MARK: - Frequency Option

struct FrequencyOption: View {
    let frequency: UpdateFrequency
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ClaudeSpacing.sm) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .claudeAccent : .claudeSecondaryText)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(frequency.displayName)
                        .font(.claudeBodyText)
                        .foregroundColor(.claudePrimaryText)
                    
                    Text(frequency.batteryImpact.description)
                        .font(.claudeMenuCaption)
                        .foregroundColor(.claudeSecondaryText)
                }
                
                Spacer()
                
                // Battery impact indicator
                Circle()
                    .fill(frequency.batteryImpact.color)
                    .frame(width: 8, height: 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, ClaudeSpacing.sm)
        .padding(.vertical, ClaudeSpacing.xs)
        .background(isSelected ? Color.claudeAccent.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - Battery Impact Indicator

struct BatteryImpactIndicator: View {
    let level: BatteryImpactLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(level.color)
                .frame(width: 6, height: 6)
            
            Text(level.displayName)
                .font(.claudeMenuCaption)
                .foregroundColor(level.color)
        }
        .padding(.horizontal, ClaudeSpacing.sm)
        .padding(.vertical, 4)
        .background(level.color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @ObservedObject var settings: SettingsViewModelImpl
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ClaudeSpacing.lg) {
                Text("Notification Preferences")
                    .font(.claudeWindowTitle)
                
                Text("Configure when and how ClaudeScheduler notifies you")
                    .font(.claudeBodyText)
                    .foregroundColor(.claudeSecondaryText)
                
                Divider()
                
                VStack(alignment: .leading, spacing: ClaudeSpacing.md) {
                    Toggle("Enable notifications", isOn: $settings.notificationsEnabled)
                        .font(.claudeBodyText)
                    
                    if settings.notificationsEnabled {
                        VStack(alignment: .leading, spacing: ClaudeSpacing.sm) {
                            Toggle("Session completion alerts", isOn: $settings.sessionCompleteNotifications)
                                .font(.claudeBodyText)
                            
                            Toggle("Error notifications", isOn: $settings.errorNotifications)
                                .font(.claudeBodyText)
                            
                            Toggle("Hourly progress updates", isOn: $settings.hourlyProgressNotifications)
                                .font(.claudeBodyText)
                            
                            Toggle("Respect \"Do Not Disturb\" mode", isOn: $settings.respectDoNotDisturb)
                                .font(.claudeBodyText)
                            
                            Toggle("Play notification sounds", isOn: $settings.playNotificationSounds)
                                .font(.claudeBodyText)
                        }
                        .padding(.leading, ClaudeSpacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: settings.notificationsEnabled)
            }
        }
    }
}

// MARK: - Advanced Settings

struct AdvancedSettingsView: View {
    @ObservedObject var settings: SettingsViewModelImpl
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ClaudeSpacing.lg) {
                Text("Advanced Configuration")
                    .font(.claudeWindowTitle)
                
                Text("Expert settings for power users")
                    .font(.claudeBodyText)
                    .foregroundColor(.claudeSecondaryText)
                
                Divider()
                
                // Claude Command
                VStack(alignment: .leading, spacing: ClaudeSpacing.sm) {
                    Text("Claude Command:")
                        .font(.claudeSectionHeader)
                    
                    TextField("Command", text: $settings.claudeCommand)
                        .textFieldStyle(.roundedBorder)
                        .font(.claudeTimer)
                    
                    Text("The command that will be executed during sessions")
                        .font(.claudeMenuCaption)
                        .foregroundColor(.claudeSecondaryText)
                }
                
                // Retry Settings
                VStack(alignment: .leading, spacing: ClaudeSpacing.sm) {
                    Text("Error Recovery:")
                        .font(.claudeSectionHeader)
                    
                    HStack {
                        Text("Maximum attempts:")
                            .font(.claudeBodyText)
                        
                        TextField("3", value: $settings.maxRetryAttempts, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                        
                        Spacer()
                        
                        Text("Retry delay:")
                            .font(.claudeBodyText)
                        
                        TextField("30", value: $settings.retryDelay, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        
                        Text("seconds")
                            .font(.claudeBodyText)
                    }
                }
                
                Divider()
                
                // System Integration
                VStack(alignment: .leading, spacing: ClaudeSpacing.sm) {
                    Text("System Integration:")
                        .font(.claudeSectionHeader)
                    
                    Toggle("Launch at login", isOn: $settings.launchAtLogin)
                        .font(.claudeBodyText)
                        .help("Automatically start ClaudeScheduler when you log in")
                }
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: ClaudeSpacing.lg) {
            // App icon and info
            VStack(spacing: ClaudeSpacing.md) {
                Image(systemName: "clock.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.claudeAccent)
                
                Text("ClaudeScheduler")
                    .font(.system(size: 24, weight: .semibold))
                
                Text("Version 1.0.0")
                    .font(.claudeBodyText)
                    .foregroundColor(.claudeSecondaryText)
            }
            
            VStack(spacing: ClaudeSpacing.sm) {
                Text("A productivity tool for scheduling Claude CLI commands")
                    .font(.claudeBodyText)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.claudeSecondaryText)
                
                Text("Built with SwiftUI and Combine for macOS")
                    .font(.claudeMenuCaption)
                    .foregroundColor(.claudeSecondaryText)
            }
            
            Spacer()
            
            // Links
            VStack(spacing: ClaudeSpacing.xs) {
                Link("View on GitHub", destination: URL(string: "https://github.com/anthropic-ai/claude-cli")!)
                    .font(.claudeBodyText)
                
                Link("Report Issues", destination: URL(string: "https://github.com/anthropic-ai/claude-cli/issues")!)
                    .font(.claudeBodyText)
            }
        }
        .padding(ClaudeSpacing.xl)
    }
}

// MARK: - Preview Support

#if DEBUG
#Preview("Settings Window") {
    SettingsWindow(settings: MockSettingsViewModel() as! SettingsViewModelImpl)
        .frame(width: 600, height: 450)
}

#Preview("Timer Settings") {
    TimerSettingsView(settings: MockSettingsViewModel() as! SettingsViewModelImpl)
        .padding()
        .frame(width: 400, height: 500)
}

#Preview("About View") {
    AboutView()
        .frame(width: 300, height: 400)
}
#endif