import SwiftUI
import AppKit

/// ClaudeScheduler color system based on native macOS colors
/// All colors automatically adapt to dark/light mode
extension Color {
    // MARK: - State Colors
    
    /// Color for idle state (secondary label color with proper opacity)
    static let claudeIdle = Color(NSColor.secondaryLabelColor)
    
    /// Color for running state (system blue)
    static let claudeRunning = Color(NSColor.systemBlue)
    
    /// Color for paused state (system orange)
    static let claudePaused = Color(NSColor.systemOrange)
    
    /// Color for completed state (system green)
    static let claudeCompleted = Color(NSColor.systemGreen)
    
    /// Color for error state (system red)
    static let claudeError = Color(NSColor.systemRed)
    
    /// Color for warning state (system yellow)
    static let claudeWarning = Color(NSColor.systemYellow)
    
    // MARK: - Interface Colors
    
    /// Background color for controls
    static let claudeBackground = Color(NSColor.controlBackgroundColor)
    
    /// Surface color for windows and panels
    static let claudeSurface = Color(NSColor.windowBackgroundColor)
    
    /// Separator color for dividers
    static let claudeSeparator = Color(NSColor.separatorColor)
    
    /// Selected content background color
    static let claudeSelection = Color(NSColor.selectedContentBackgroundColor)
    
    /// Control tint color
    static let claudeAccent = Color(NSColor.controlAccentColor)
    
    // MARK: - Text Colors
    
    /// Primary text color (highest contrast)
    static let claudePrimaryText = Color(NSColor.labelColor)
    
    /// Secondary text color (medium contrast)
    static let claudeSecondaryText = Color(NSColor.secondaryLabelColor)
    
    /// Tertiary text color (low contrast)
    static let claudeTertiaryText = Color(NSColor.tertiaryLabelColor)
    
    /// Quaternary text color (lowest contrast)
    static let claudeQuaternaryText = Color(NSColor.quaternaryLabelColor)
    
    /// Disabled text color
    static let claudeDisabledText = Color(NSColor.disabledControlTextColor)
    
    // MARK: - Interactive Colors
    
    /// Hover state background
    static let claudeHover = Color(NSColor.controlColor)
    
    /// Selected menu item background
    static let claudeSelectedMenuItem = Color(NSColor.selectedMenuItemColor)
    
    /// Selected menu item text
    static let claudeSelectedMenuItemText = Color(NSColor.selectedMenuItemTextColor)
    
    // MARK: - Utility Methods
    
    /// Returns color with specified opacity that respects the current appearance
    func withOpacity(_ opacity: Double, respectingAppearance: Bool = true) -> Color {
        if respectingAppearance {
            return self.opacity(opacity)
        }
        return self.opacity(opacity)
    }
    
    /// Returns appropriate text color for this background color
    var contrastingTextColor: Color {
        // For now, use the system's automatic text colors
        // In a more complex implementation, we could calculate contrast ratios
        return .claudePrimaryText
    }
}

/// NSColor extensions for additional color utilities
extension NSColor {
    
    /// Convenience method to get color for scheduler state
    static func colorForSchedulerState(_ state: SchedulerState) -> NSColor {
        switch state {
        case .idle:
            return .secondaryLabelColor
        case .running:
            return .systemBlue
        case .paused:
            return .systemOrange
        case .completed:
            return .systemGreen
        case .error:
            return .systemRed
        }
    }
    
    /// Returns if the current appearance is dark mode
    var isDarkMode: Bool {
        if let appearance = NSApp.effectiveAppearance.name {
            return appearance == .darkAqua || appearance == .vibrantDark || appearance == .accessibilityHighContrastDarkAqua
        }
        return false
    }
    
    /// Returns color with better contrast for accessibility if needed
    func accessibilityColor(increaseContrast: Bool) -> NSColor {
        if increaseContrast {
            // Increase contrast by making colors more extreme
            return self.blended(withFraction: 0.2, of: isDarkMode ? .white : .black) ?? self
        }
        return self
    }
}

/// Color constants for specific design elements
struct ClaudeColors {
    
    // MARK: - Progress Ring Colors
    
    static let progressRingBackground = Color.claudeIdle.opacity(0.2)
    static let progressRingForeground = Color.claudeRunning
    
    // MARK: - Menu Colors
    
    static let menuBackground = Color.claudeSurface
    static let menuItemHover = Color.claudeHover
    static let menuSeparator = Color.claudeSeparator
    
    // MARK: - Settings Colors
    
    static let settingsBackground = Color.claudeSurface
    static let settingsSectionBackground = Color.claudeBackground
    static let settingsAccent = Color.claudeAccent
    
    // MARK: - Notification Colors
    
    static let notificationSuccess = Color.claudeCompleted.opacity(0.1)
    static let notificationWarning = Color.claudeWarning.opacity(0.1)
    static let notificationError = Color.claudeError.opacity(0.1)
    static let notificationInfo = Color.claudeRunning.opacity(0.1)
    
    // MARK: - Battery Impact Colors
    
    static let batteryImpactLow = Color.claudeCompleted
    static let batteryImpactMedium = Color.claudeWarning
    static let batteryImpactHigh = Color.claudeError
}

/// Color theme management for future dark/light mode customization
class ColorThemeManager: ObservableObject {
    
    @Published var currentTheme: ColorTheme = .system
    
    enum ColorTheme: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    /// Apply the selected theme
    func applyTheme(_ theme: ColorTheme) {
        currentTheme = theme
        
        switch theme {
        case .system:
            NSApp.appearance = nil // Use system appearance
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
    
    /// Get theme-appropriate color
    func color(for state: SchedulerState) -> Color {
        return state.color // Colors already adapt to current appearance
    }
}