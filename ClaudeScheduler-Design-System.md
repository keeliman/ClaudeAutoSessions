# ClaudeScheduler Design System
*Complete Visual Identity & Implementation Guide*

---

## 1. Brand Identity & Values

### Brand Personality
**ClaudeScheduler** embodies the principles of elegant productivity and seamless macOS integration. The brand reflects:

- **Precision**: Every detail matters, from timing accuracy to pixel-perfect alignment
- **Discretion**: Powerful functionality without visual noise or interruption
- **Intelligence**: Adaptive behavior that learns and optimizes for user workflows
- **Reliability**: Consistent, dependable performance that users can trust
- **Native**: Feels like an integral part of macOS, not an external addition

### Brand Promise
*"Effortless automation that respects your workflow and enhances your productivity without getting in the way."*

---

## 2. Native macOS Color System

### Primary Color Palette

```swift
// ClaudeScheduler Color System
struct ClaudeSchedulerColors {
    // State Colors (macOS System Colors)
    static let idle = NSColor.secondaryLabelColor
    static let running = NSColor.systemBlue
    static let paused = NSColor.systemOrange
    static let completed = NSColor.systemGreen
    static let error = NSColor.systemRed
    static let warning = NSColor.systemYellow
    
    // Interface Colors
    static let background = NSColor.controlBackgroundColor
    static let surface = NSColor.windowBackgroundColor
    static let separator = NSColor.separatorColor
    
    // Text Hierarchy
    static let primaryText = NSColor.labelColor
    static let secondaryText = NSColor.secondaryLabelColor
    static let tertiaryText = NSColor.tertiaryLabelColor
    static let quaternaryText = NSColor.quaternaryLabelColor
    
    // Interactive Elements
    static let controlAccent = NSColor.controlAccentColor
    static let selection = NSColor.selectedContentBackgroundColor
    static let hover = NSColor.controlColor
}
```

### Dark/Light Mode Adaptation

The color system automatically adapts to system appearance:

**Light Mode Values**:
- `idle`: RGB(142, 142, 147) - 88% opacity
- `running`: RGB(0, 122, 255) - System Blue
- `paused`: RGB(255, 149, 0) - System Orange
- `completed`: RGB(52, 199, 89) - System Green
- `error`: RGB(255, 59, 48) - System Red

**Dark Mode Values**:
- `idle`: RGB(142, 142, 147) - 60% opacity
- `running`: RGB(10, 132, 255) - System Blue
- `paused`: RGB(255, 159, 10) - System Orange
- `completed`: RGB(50, 215, 75) - System Green
- `error`: RGB(255, 69, 58) - System Red

### Color Usage Guidelines

1. **Never use hardcoded RGB values** - Always reference NSColor system colors
2. **Test in both light and dark modes** - Ensure contrast ratios meet WCAG AA standards
3. **Use semantic color names** - `running` instead of `blue`, `error` instead of `red`
4. **Respect user's accent color** - Use `controlAccentColor` for primary actions

---

## 3. Menu Bar Iconography

### Icon Design Principles

- **Monochromatic**: Use single color with transparency for depth
- **Template Icons**: Automatically adapt to menu bar appearance
- **Sharp at All Sizes**: Crisp at 16px, 20px, 24px, and 32px
- **Minimal Detail**: Clear readability at small sizes
- **System Consistent**: Match existing macOS menu bar icons

### Primary Icon Set

#### 3.1 Idle State Icon
```
Design: Circle with subtle play triangle
Size: 16x16px @ 1x, 32x32px @ 2x
Style: Template icon (black with alpha channel)
Symbol: SF Symbol "play.circle" customized
```

#### 3.2 Running State Icon
```
Design: Circular progress ring with pause symbol in center
Animation: Gradual fill clockwise over 5 hours
Stroke Width: 2px
Ring Gap: 1px
Center Symbol: "pause.fill" (4x4px)
```

#### 3.3 Paused State Icon
```
Design: Partially filled ring with double-bar pause
Color: systemOrange
Animation: Gentle pulse (2s cycle)
Alpha: 1.0 → 0.7 → 1.0
```

#### 3.4 Completed State Icon
```
Design: Filled circle with checkmark
Duration: Shows for 10 seconds
Animation: Scale bounce entry (1.15x → 1.0x)
Symbol: "checkmark.circle.fill"
```

#### 3.5 Error State Icon
```
Design: Triangle with exclamation mark
Animation: Subtle flash every 3 seconds
Symbol: "exclamationmark.triangle.fill"
Color: systemRed with 80% opacity
```

### Icon Assets Structure

```
Assets.xcassets/
└── MenuBarIcons/
    ├── idle-state.imageset/
    │   ├── idle@1x.png (16x16)
    │   ├── idle@2x.png (32x32)
    │   └── idle@3x.png (48x48)
    ├── running-ring.imageset/
    │   ├── ring@1x.png (16x16)
    │   └── ring@2x.png (32x32)
    ├── pause-symbol.imageset/
    │   ├── pause@1x.png (4x4)
    │   └── pause@2x.png (8x8)
    └── status-indicators.imageset/
        ├── checkmark@1x.png
        ├── checkmark@2x.png
        ├── exclamation@1x.png
        └── exclamation@2x.png
```

---

## 4. Typography System

### Font Hierarchy (San Francisco System Font)

```swift
struct ClaudeSchedulerTypography {
    // Menu Bar Context
    static let menuTitle = NSFont.menuBarFont(ofSize: 13)
    static let menuItem = NSFont.menuFont(ofSize: 13)
    static let menuDescription = NSFont.menuFont(ofSize: 11)
    
    // Settings Window
    static let windowTitle = NSFont.systemFont(ofSize: 13, weight: .semibold)
    static let sectionHeader = NSFont.systemFont(ofSize: 11, weight: .medium)
    static let bodyText = NSFont.systemFont(ofSize: 11, weight: .regular)
    static let caption = NSFont.systemFont(ofSize: 9, weight: .regular)
    
    // Status Display
    static let timerDisplay = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
    static let statusLabel = NSFont.systemFont(ofSize: 10, weight: .regular)
}
```

### Typography Guidelines

1. **Use System Fonts Only**: Ensures perfect OS integration
2. **Monospaced for Numbers**: Timer displays use monospaced digits
3. **Weight Hierarchy**: Semibold for titles, Medium for emphasis, Regular for body
4. **Dynamic Type Support**: Respect user's font size preferences
5. **Proper Line Heights**: 1.2x font size for menu items, 1.4x for body text

---

## 5. Progress Visualization System

### 5.1 Circular Progress Ring

The signature visual element of ClaudeScheduler:

```swift
struct CircularProgressRing {
    // Visual Properties
    let ringWidth: CGFloat = 2.0
    let ringRadius: CGFloat = 6.0  // For 16px icon
    let centerRadius: CGFloat = 4.0
    
    // Animation Properties
    let strokeAnimationDuration: TimeInterval = 0.5
    let rotationAnimationDuration: TimeInterval = 18000  // 5 hours in seconds
    
    // Colors
    let backgroundRingColor = NSColor.quaternaryLabelColor
    let progressRingColor = NSColor.systemBlue
    
    // State Management
    @Published var progress: Double = 0.0  // 0.0 to 1.0
    @Published var isAnimating: Bool = false
}
```

### 5.2 Progress States & Animations

#### Running State Animation
```swift
// Smooth progress updates every 5 seconds
func updateProgress() {
    let newProgress = calculateSessionProgress()
    
    NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.5
        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
        self.progress = newProgress
    }
}
```

#### Micro-Interactions
- **Hover**: Scale 1.0 → 1.1 (0.15s ease-out)
- **Click**: Scale 1.1 → 0.95 → 1.0 (0.1s bounce)
- **State Change**: Color transition (0.3s ease-in-out)

### 5.3 Battery-Optimized Updates

Performance optimization for long sessions:

```swift
func adjustUpdateFrequency() {
    let interval: TimeInterval
    
    switch ProcessInfo.processInfo.isLowPowerModeEnabled {
    case true: interval = 30.0  // 30 second updates
    case false: interval = 5.0  // 5 second updates
    }
    
    scheduleProgressUpdates(interval: interval)
}
```

---

## 6. Menu System Design

### 6.1 Contextual Menu Structure

```
┌─────────────────────────────────────────────────────┐
│ ClaudeScheduler                          [Icon]     │
│ ═══════════════════════════════════════════════════ │
│                                                     │
│ ▶  Start 5-hour Session                            │
│ ⏸  Pause Current Session                           │ (if running)
│ ⏹  Stop Session                                    │ (if running/paused)
│                                                     │
│ ─────────────────────────────────────────────────── │
│                                                     │
│ ⏰ Next Execution: Today at 3:45 PM               │
│ 📊 Sessions Today: 3 completed                    │
│ 🔋 Battery Impact: Low                            │
│                                                     │
│ ─────────────────────────────────────────────────── │
│                                                     │
│ ⚙️  Preferences...                                  │
│ 📋 Session History                                 │
│ ❓ Help & Support                                  │
│                                                     │
│ ─────────────────────────────────────────────────── │
│                                                     │
│ ❌ Quit ClaudeScheduler                            │
└─────────────────────────────────────────────────────┘
```

### 6.2 Menu Item Specifications

```swift
struct MenuItemDesign {
    // Spacing
    static let itemHeight: CGFloat = 22
    static let separatorHeight: CGFloat = 9
    static let horizontalPadding: CGFloat = 16
    static let iconSpacing: CGFloat = 8
    
    // Typography
    static let primaryFont = NSFont.menuFont(ofSize: 13)
    static let secondaryFont = NSFont.menuFont(ofSize: 11)
    
    // States
    static let normalColor = NSColor.labelColor
    static let disabledColor = NSColor.disabledControlTextColor
    static let highlightColor = NSColor.selectedMenuItemTextColor
}
```

### 6.3 Smart Context Awareness

Menu items dynamically show/hide based on current state:

- **Idle**: Show "Start Session" only
- **Running**: Show "Pause" and "Stop", hide "Start"
- **Paused**: Show "Resume" and "Stop", hide "Start"
- **Error**: Show "Retry" and "View Logs"

---

## 7. Notification System Design

### 7.1 Native macOS Notifications

```swift
struct NotificationDesign {
    // Notification Types
    enum NotificationType {
        case sessionCompleted
        case sessionFailed
        case batteryPause
        case systemWake
    }
    
    // Visual Properties
    static let appIcon = "ClaudeScheduler"
    static let soundEnabled = true
    static let actionButtonsEnabled = true
}
```

### 7.2 Notification Templates

#### Session Completed
```
Title: "Claude Session Completed"
Subtitle: "5-hour session finished successfully"
Body: "3 executions completed. Next session can start now."
Sound: NSUserNotificationDefaultSoundName
Actions: ["Start New Session", "View Logs"]
```

#### Session Failed
```
Title: "Claude Scheduler Error"
Subtitle: "Unable to execute claude command"
Body: "Will retry automatically in 30 seconds."
Sound: NSUserNotificationDefaultSoundName
Actions: ["Retry Now", "Open Settings"]
```

#### Battery Pause
```
Title: "Session Paused"
Subtitle: "Timer paused due to low battery mode"
Body: "Session will resume when battery improves."
Sound: None (respect low power mode)
Actions: ["Resume Anyway", "Stop Session"]
```

### 7.3 Notification Behavior Rules

1. **Do Not Disturb Respect**: Honor system DND settings
2. **Frequency Limiting**: Max 1 notification per 30 minutes
3. **Critical Only Persist**: Only error notifications persist
4. **User Preference Override**: All notifications can be disabled

---

## 8. Settings Interface Design

### 8.1 Settings Window Layout

```
┌─────────────────── ClaudeScheduler Settings ──────────────────┐
│                                                               │
│ 🕒 Timer Configuration                                        │
│ ┌───────────────────────────────────────────────────────────┐ │
│ │ Session Duration:  [  5  ] hours [  0  ] minutes         │ │
│ │                                                           │ │
│ │ Update Frequency:  ○ 1 sec  ● 5 sec  ○ 30 sec           │ │
│ │ Auto-restart:      ☑ Start new session after completion  │ │
│ │ Battery Adaptive:  ☑ Reduce updates in low power mode    │ │
│ └───────────────────────────────────────────────────────────┘ │
│                                                               │
│ 🔔 Notifications                                             │
│ ┌───────────────────────────────────────────────────────────┐ │
│ │ ☑ Session completion alerts                              │ │
│ │ ☑ Error notifications                                    │ │
│ │ ☐ Hourly progress updates                               │ │
│ │ ☑ Respect "Do Not Disturb" mode                         │ │
│ │ ☑ Play notification sounds                              │ │
│ └───────────────────────────────────────────────────────────┘ │
│                                                               │
│ ⚡ Advanced Settings                                         │
│ ┌───────────────────────────────────────────────────────────┐ │
│ │ Claude Command:                                           │ │
│ │ [claude salut ça va -p                            ]      │ │
│ │                                                           │ │
│ │ Retry Settings:                                           │ │
│ │ Attempts: [ 3 ]  Delay: [ 30 ] seconds                  │ │
│ │                                                           │ │
│ │ ☑ Launch at login                                        │ │
│ │ ☑ Show icon in Dock (requires restart)                  │ │
│ └───────────────────────────────────────────────────────────┘ │
│                                                               │
│                    [ Cancel ]  [ Apply ]  [ OK ]             │
└───────────────────────────────────────────────────────────────┘
```

### 8.2 Settings UI Specifications

```swift
struct SettingsWindowDesign {
    // Window Properties
    static let windowWidth: CGFloat = 480
    static let windowHeight: CGFloat = 400
    static let resizable = false
    static let minimizable = false
    
    // Section Spacing
    static let sectionSpacing: CGFloat = 20
    static let itemSpacing: CGFloat = 8
    static let groupPadding: CGFloat = 16
    
    // Control Dimensions
    static let textFieldWidth: CGFloat = 300
    static let numberFieldWidth: CGFloat = 60
    static let buttonWidth: CGFloat = 80
    static let checkboxSize: CGFloat = 16
}
```

---

## 9. Animation & Interaction Guidelines

### 9.1 Timing Functions & Durations

```swift
struct AnimationConstants {
    // Micro-interactions (hover, click)
    static let microDuration: TimeInterval = 0.15
    static let microTimingFunction = CAMediaTimingFunction(name: .easeOut)
    
    // State transitions
    static let transitionDuration: TimeInterval = 0.3
    static let transitionTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    
    // Progress updates
    static let progressDuration: TimeInterval = 0.5
    static let progressTimingFunction = CAMediaTimingFunction(name: .easeOut)
    
    // Success celebrations
    static let successDuration: TimeInterval = 0.4
    static let successTimingFunction = CAMediaTimingFunction(controlPoints: 0.68, -0.55, 0.265, 1.55)
}
```

### 9.2 Animation Accessibility

```swift
// Respect user's motion preferences
func shouldAnimate() -> Bool {
    return !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
}

func animationDuration(base: TimeInterval) -> TimeInterval {
    return shouldAnimate() ? base : 0.0
}
```

### 9.3 Performance Optimization

```swift
// Layer-backed views for smooth animations
func configureForAnimation() {
    view.wantsLayer = true
    view.layer?.cornerRadius = 4.0
    view.layer?.masksToBounds = true
    
    // Enable metal rendering for complex animations
    if let metalLayer = view.layer as? CAMetalLayer {
        metalLayer.presentsWithTransaction = false
    }
}
```

---

## 10. Accessibility & Inclusion

### 10.1 VoiceOver Support

```swift
// Menu bar icon accessibility
statusItem.button?.setAccessibilityLabel("Claude Scheduler")
statusItem.button?.setAccessibilityValue(currentStateDescription)
statusItem.button?.setAccessibilityRole(.button)

// Progress ring accessibility
progressRing.setAccessibilityLabel("Session progress")
progressRing.setAccessibilityValue("\(Int(progress * 100))% complete")
progressRing.setAccessibilityRole(.progressIndicator)
```

### 10.2 Keyboard Navigation

```swift
// Full keyboard menu navigation
menu.allowsContextMenuPlugIns = true
menu.showsStateColumn = true

// Settings window keyboard support
window.initialFirstResponder = sessionDurationField
window.autorecalculatesKeyViewLoop = true
```

### 10.3 High Contrast Support

```swift
// Adaptive contrast for accessibility
extension NSColor {
    static var accessibleMenuBarIcon: NSColor {
        if NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast {
            return .labelColor
        }
        return .secondaryLabelColor
    }
}
```

---

## 11. Performance Guidelines

### 11.1 Memory Management

```swift
class MenuBarController: NSObject {
    // Weak references to prevent retain cycles
    weak var delegate: MenuBarDelegate?
    
    // Lazy loading for heavy resources
    lazy var progressRenderer = CircularProgressRenderer()
    
    // Release unused assets
    deinit {
        progressRenderer.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
```

### 11.2 CPU Optimization

```swift
// Efficient timer management
func optimizeForBatteryLife() {
    // Reduce update frequency on battery
    let interval = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30.0 : 5.0
    
    // Pause animations when not visible
    let isVisible = NSApplication.shared.isActive
    progressView.pauseAnimations = !isVisible
}
```

### 11.3 Startup Performance

```swift
// Fast launch targets
struct PerformanceTargets {
    static let launchTime: TimeInterval = 2.0      // < 2 seconds
    static let menuResponse: TimeInterval = 0.05   // < 50ms
    static let iconUpdate: TimeInterval = 0.1      // < 100ms
}
```

---

## 12. Implementation Checklist

### 12.1 Phase 1: Core Visual Identity
- [ ] Asset creation (16px, 32px icons all states)
- [ ] Color system implementation
- [ ] Typography hierarchy setup
- [ ] Menu bar integration

### 12.2 Phase 2: Interactive Elements
- [ ] Circular progress ring component
- [ ] Menu system with dynamic states
- [ ] Hover/click micro-interactions
- [ ] State transition animations

### 12.3 Phase 3: Advanced Features
- [ ] Settings window with live preview
- [ ] Native notification system
- [ ] Accessibility implementation
- [ ] Performance optimization

### 12.4 Quality Assurance
- [ ] Dark/Light mode testing
- [ ] All screen densities (@1x, @2x, @3x)
- [ ] VoiceOver compatibility
- [ ] High contrast accessibility
- [ ] Battery usage validation

---

## 13. Design Tokens (SwiftUI Implementation)

```swift
import SwiftUI

extension Color {
    static let claudeIdle = Color(NSColor.secondaryLabelColor)
    static let claudeRunning = Color(NSColor.systemBlue)
    static let claudePaused = Color(NSColor.systemOrange)
    static let claudeCompleted = Color(NSColor.systemGreen)
    static let claudeError = Color(NSColor.systemRed)
}

extension Font {
    static let claudeMenuTitle = Font.system(size: 13, weight: .semibold)
    static let claudeMenuBody = Font.system(size: 11, weight: .regular)
    static let claudeTimer = Font.system(size: 11, weight: .medium, design: .monospaced)
}

struct ClaudeSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
```

---

## Conclusion

Ce design system pour ClaudeScheduler établit une identité visuelle cohérente et performante qui s'intègre parfaitement dans l'écosystème macOS. Chaque décision de design privilégie:

1. **L'intégration native** - Utilisation exclusive des patterns et composants système Apple
2. **La performance** - Optimisations pour la batterie et fluidité 60fps
3. **L'accessibilité** - Support complet VoiceOver et préférences utilisateur
4. **La discrétion** - Interface qui enrichit sans perturber le workflow

L'implémentation de ce design system garantit une application menu bar élégante, fiable et respectueuse des conventions macOS, positionnant ClaudeScheduler comme un outil professionnel indispensable.

---

*Design System v1.0 - Créé le 13 août 2024*  
*Agent: brand-design*  
*Dépendances: UX-Research-ClaudeScheduler.md*