import SwiftUI

/// Animation constants and configurations for ClaudeScheduler
/// Provides consistent timing and easing across the application
struct ClaudeAnimation {
    
    // MARK: - Duration Constants
    
    /// Ultra-fast animations for immediate feedback
    static let immediate: TimeInterval = 0.05
    
    /// Micro-interaction duration (hover, click feedback)
    static let micro: TimeInterval = 0.15
    
    /// Standard transition duration
    static let transition: TimeInterval = 0.3
    
    /// Progress update animation duration
    static let progress: TimeInterval = 0.5
    
    /// Success/completion animation duration
    static let success: TimeInterval = 0.4
    
    /// Long animation for dramatic effect
    static let dramatic: TimeInterval = 0.8
    
    // MARK: - Easing Curves
    
    /// Quick response for hover effects
    static let easeOut = Animation.easeOut(duration: micro)
    
    /// Smooth transitions between states
    static let easeInOut = Animation.easeInOut(duration: transition)
    
    /// Gentle progress updates
    static let progressEase = Animation.easeOut(duration: progress)
    
    /// Bouncy spring for success states
    static let bouncy = Animation.interpolatingSpring(stiffness: 300, damping: 30)
    
    /// Gentle spring for general use
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    
    /// Subtle spring with less bounce
    static let subtleSpring = Animation.spring(response: 0.3, dampingFraction: 0.9)
    
    // MARK: - Specialized Animations
    
    /// Animation for menu appearance
    static let menuAppear = Animation.easeOut(duration: 0.2)
    
    /// Animation for state transitions
    static let stateTransition = Animation.easeInOut(duration: transition)
    
    /// Animation for error states (shake effect)
    static let errorShake = Animation.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)
    
    /// Pulsing animation for paused state
    static let pausePulse = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    
    /// Flash animation for error states
    static let errorFlash = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    
    /// Rotation animation for loading states
    static let rotation = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
}

/// Animation timing functions for different interaction types
struct ClaudeTimingCurve {
    
    /// Standard ease-out curve for most interactions
    static let standard = UnitCurve.easeOut
    
    /// Bounce curve for success animations
    static let bounce = UnitCurve.circularEaseOut
    
    /// Sharp curve for immediate feedback
    static let sharp = UnitCurve.easeIn
    
    /// Gentle curve for subtle animations
    static let gentle = UnitCurve.easeInOut
}

/// Animation utilities and helpers
struct AnimationUtils {
    
    /// Returns appropriate animation based on accessibility settings
    static func respectingAccessibility<V>(_ animation: Animation, value: V) -> Animation {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return .none
        }
        return animation
    }
    
    /// Creates a delay animation
    static func delayed(_ delay: TimeInterval, animation: Animation) -> Animation {
        return animation.delay(delay)
    }
    
    /// Creates a staggered animation for multiple items
    static func staggered(count: Int, delay: TimeInterval, animation: Animation) -> [Animation] {
        return (0..<count).map { index in
            animation.delay(TimeInterval(index) * delay)
        }
    }
}

/// Animation configurations for specific components
extension Animation {
    
    // MARK: - Progress Ring Animations
    
    /// Smooth progress updates for the circular ring
    static var progressRingUpdate: Animation {
        .easeOut(duration: ClaudeAnimation.progress)
    }
    
    /// Ring appearance animation when session starts
    static var progressRingAppear: Animation {
        .interpolatingSpring(stiffness: 400, damping: 25)
    }
    
    // MARK: - Menu Animations
    
    /// Menu item hover animation
    static var menuItemHover: Animation {
        .easeOut(duration: ClaudeAnimation.micro)
    }
    
    /// Context menu appearance
    static var contextMenuAppear: Animation {
        .easeOut(duration: 0.2).delay(0.05)
    }
    
    // MARK: - State Change Animations
    
    /// Animation when transitioning between scheduler states
    static var stateChange: Animation {
        .easeInOut(duration: ClaudeAnimation.transition)
    }
    
    /// Success bounce when session completes
    static var completionBounce: Animation {
        .interpolatingSpring(stiffness: 400, damping: 20)
    }
    
    // MARK: - Error Animations
    
    /// Subtle shake for error indication
    static var errorIndication: Animation {
        .easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)
    }
    
    /// Flash for critical errors
    static var criticalError: Animation {
        .easeInOut(duration: 0.3).repeatCount(2, autoreverses: true)
    }
}

/// Performance-aware animation manager
class AnimationPerformanceManager: ObservableObject {
    
    @Published var reduceMotion: Bool = false
    @Published var batteryOptimized: Bool = false
    @Published var preferPerformance: Bool = false
    
    init() {
        updatePreferences()
        
        // Listen for accessibility changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilityChanged),
            name: NSNotification.Name("NSWorkspaceAccessibilityDisplayOptionsDidChangeNotification"),
            object: nil
        )
        
        // Listen for battery state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(powerStateChanged),
            name: .NSProcessInfoPowerStateDidChange,
            object: nil
        )
    }
    
    @objc private func accessibilityChanged() {
        updatePreferences()
    }
    
    @objc private func powerStateChanged() {
        updatePreferences()
    }
    
    private func updatePreferences() {
        reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        batteryOptimized = ProcessInfo.processInfo.isLowPowerModeEnabled
        preferPerformance = batteryOptimized || reduceMotion
    }
    
    /// Returns appropriate animation based on current performance preferences
    func animation(_ defaultAnimation: Animation) -> Animation {
        if reduceMotion {
            return .none
        }
        
        if batteryOptimized {
            // Reduce animation complexity for battery savings
            return .linear(duration: defaultAnimation.base.duration * 0.5)
        }
        
        return defaultAnimation
    }
    
    /// Returns appropriate update interval based on performance preferences
    func updateInterval(_ defaultInterval: TimeInterval) -> TimeInterval {
        if batteryOptimized {
            return defaultInterval * 6 // Reduce frequency significantly
        }
        
        if preferPerformance {
            return defaultInterval * 2 // Reduce frequency moderately
        }
        
        return defaultInterval
    }
}

/// Animation extension for common transformations
extension Animation {
    
    /// Returns a simplified version of the animation for performance
    var performanceOptimized: Animation {
        switch self {
        case .spring, .interactiveSpring, .interpolatingSpring:
            return .easeOut(duration: 0.3)
        default:
            return .linear(duration: 0.2)
        }
    }
    
    /// Returns duration of the animation if available
    var duration: TimeInterval {
        // This is a simplified approximation since Animation doesn't expose duration directly
        // In practice, we track durations through our constants
        return ClaudeAnimation.transition
    }
    
    /// Creates a battery-optimized version of the animation
    var batteryOptimized: Animation {
        return .linear(duration: min(duration * 0.5, 0.2))
    }
}