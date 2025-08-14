import SwiftUI
import Combine

/// Enhanced menu bar view with advanced micro-interactions, hover states, and polish animations
struct EnhancedMenuBarView: View {
    @ObservedObject var viewModel: SchedulerViewModel
    @State private var isHovered = false
    @State private var isPulsingForAttention = false
    @State private var showTooltip = false
    @State private var tooltipText = ""
    @State private var lastInteractionTime = Date()
    @State private var hoverStartTime: Date?
    @State private var bounceAnimation = false
    @State private var progressGlow = false
    
    // Animation configurations
    private let hoverAnimationDuration: Double = 0.25
    private let progressAnimationDuration: Double = 2.0
    private let tooltipDelay: Double = 0.8
    private let attentionPulseInterval: Double = 3.0
    
    var body: some View {
        ZStack {
            // Main progress ring with enhanced animations
            EnhancedCircularProgressRing(
                progress: viewModel.progress,
                state: viewModel.sessionState,
                size: ringSize,
                showGlow: progressGlow,
                isHovered: isHovered
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: hoverAnimationDuration)) {
                    isHovered = hovering
                    progressGlow = hovering
                }
                
                if hovering {
                    hoverStartTime = Date()
                    scheduleTooltip()
                } else {
                    hoverStartTime = nil
                    hideTooltip()
                }
            }
            
            // Attention-grabbing animation for important states
            if shouldShowAttentionAnimation {
                Circle()
                    .stroke(Color.claudeAccent.opacity(0.3), lineWidth: 2)
                    .scaleEffect(isPulsingForAttention ? 1.3 : 1.0)
                    .opacity(isPulsingForAttention ? 0 : 0.6)
                    .animation(
                        .easeOut(duration: 1.0)
                        .repeatForever(autoreverses: false),
                        value: isPulsingForAttention
                    )
                    .onAppear {
                        isPulsingForAttention = true
                    }
            }
            
            // Interactive touch feedback overlay
            if isPressed {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .scaleEffect(0.8)
                    .animation(.easeOut(duration: 0.15), value: isPressed)
            }
        }
        .frame(width: ringSize, height: ringSize)
        .contentShape(Circle())
        .onTapGesture {
            handleTap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            handleLongPress()
        }
        .overlay(tooltipOverlay, alignment: .topTrailing)
        .onReceive(attentionTimer) { _ in
            triggerAttentionAnimation()
        }
        .onChange(of: viewModel.sessionState) { newState in
            handleStateChange(newState)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Computed Properties
    
    private var ringSize: CGFloat {
        22 // Standard menu bar item size
    }
    
    private var shouldShowAttentionAnimation: Bool {
        viewModel.sessionState == .completed || 
        viewModel.sessionState == .error || 
        needsUserAttention
    }
    
    private var needsUserAttention: Bool {
        // Show attention animation if user hasn't interacted recently
        Date().timeIntervalSince(lastInteractionTime) > 300 && // 5 minutes
        viewModel.sessionState == .running
    }
    
    private var isPressed: Bool {
        // This would be set by gesture recognizers in a full implementation
        false
    }
    
    private var attentionTimer: Timer.TimerPublisher {
        Timer.publish(every: attentionPulseInterval, on: .main, in: .common)
    }
    
    // MARK: - Tooltip Overlay
    
    @ViewBuilder
    private var tooltipOverlay: some View {
        if showTooltip {
            TooltipView(text: tooltipText)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)),
                    removal: .opacity
                ))
                .zIndex(1000)
        }
    }
    
    // MARK: - Interaction Handlers
    
    private func handleTap() {
        lastInteractionTime = Date()
        
        // Haptic feedback
        provideTactileFeedback(.light)
        
        // Bounce animation
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
            bounceAnimation.toggle()
        }
        
        // Handle tap based on current state
        switch viewModel.sessionState {
        case .idle:
            viewModel.startSession()
        case .running:
            viewModel.pauseSession()
        case .paused:
            viewModel.resumeSession()
        case .completed:
            viewModel.resetSession()
        case .error:
            viewModel.retrySession()
        }
    }
    
    private func handleLongPress() {
        lastInteractionTime = Date()
        
        // Stronger haptic feedback for long press
        provideTactileFeedback(.medium)
        
        // Show context menu or settings
        showContextMenu()
    }
    
    private func scheduleTooltip() {
        DispatchQueue.main.asyncAfter(deadline: .now() + tooltipDelay) {
            if isHovered, let hoverStart = hoverStartTime,
               Date().timeIntervalSince(hoverStart) >= tooltipDelay {
                showTooltipWithCurrentState()
            }
        }
    }
    
    private func showTooltipWithCurrentState() {
        tooltipText = createTooltipText()
        withAnimation(.easeInOut(duration: 0.2)) {
            showTooltip = true
        }
    }
    
    private func hideTooltip() {
        withAnimation(.easeInOut(duration: 0.15)) {
            showTooltip = false
        }
    }
    
    private func createTooltipText() -> String {
        switch viewModel.sessionState {
        case .idle:
            return "ClaudeScheduler\nClick to start session"
        case .running:
            let remaining = viewModel.timeRemaining
            let progress = Int(viewModel.progress * 100)
            return "Session Running (\(progress)%)\n\(formatTimeRemaining(remaining)) remaining\nClick to pause"
        case .paused:
            return "Session Paused\nClick to resume"
        case .completed:
            return "Session Completed! 🎉\nClick to start new session"
        case .error:
            return "Session Error\nClick to retry"
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
    
    // MARK: - Animation Triggers
    
    private func triggerAttentionAnimation() {
        guard shouldShowAttentionAnimation else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            isPulsingForAttention.toggle()
        }
    }
    
    private func handleStateChange(_ newState: SchedulerState) {
        // Trigger appropriate animations based on state change
        switch newState {
        case .completed:
            triggerCompletionCelebration()
        case .error:
            triggerErrorAlert()
        case .running:
            triggerStartAnimation()
        default:
            break
        }
    }
    
    private func triggerCompletionCelebration() {
        // Celebration animation sequence
        withAnimation(.interpolatingSpring(stiffness: 400, damping: 8)) {
            bounceAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interpolatingSpring(stiffness: 400, damping: 8)) {
                bounceAnimation = false
            }
        }
        
        // Show completion effect
        triggerSuccessEffect()
    }
    
    private func triggerErrorAlert() {
        // Error shake animation
        withAnimation(.linear(duration: 0.1).repeatCount(3, autoreverses: true)) {
            // In a full implementation, this would shake the view
        }
    }
    
    private func triggerStartAnimation() {
        // Smooth start animation
        withAnimation(.easeInOut(duration: 0.3)) {
            progressGlow = true
        }
    }
    
    private func triggerSuccessEffect() {
        // Success particle effect or glow
        withAnimation(.easeInOut(duration: 1.0)) {
            // Success visual effect
        }
    }
    
    // MARK: - Utility Methods
    
    private func provideTactileFeedback(_ intensity: NSHapticFeedbackManager.FeedbackPattern) {
        NSHapticFeedbackManager.defaultPerformer.perform(intensity, performanceTime: .default)
    }
    
    private func showContextMenu() {
        // Trigger context menu display
        // This would be handled by the parent menu bar controller
        NotificationCenter.default.post(name: .showEnhancedContextMenu, object: nil)
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        switch viewModel.sessionState {
        case .idle: return "ClaudeScheduler - Ready to start"
        case .running: return "ClaudeScheduler - Session running"
        case .paused: return "ClaudeScheduler - Session paused"
        case .completed: return "ClaudeScheduler - Session completed"
        case .error: return "ClaudeScheduler - Error occurred"
        }
    }
    
    private var accessibilityHint: String {
        switch viewModel.sessionState {
        case .idle: return "Tap to start a new session"
        case .running: return "Tap to pause the current session"
        case .paused: return "Tap to resume the session"
        case .completed: return "Tap to start a new session"
        case .error: return "Tap to retry the session"
        }
    }
    
    private var accessibilityValue: String {
        let progress = Int(viewModel.progress * 100)
        let remaining = formatTimeRemaining(viewModel.timeRemaining)
        return "\(progress)% complete, \(remaining) remaining"
    }
}

// MARK: - Enhanced Circular Progress Ring

struct EnhancedCircularProgressRing: View {
    let progress: Double
    let state: SchedulerState
    let size: CGFloat
    let showGlow: Bool
    let isHovered: Bool
    
    @State private var animatedProgress: Double = 0
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    private let lineWidth: CGFloat = 2.5
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.claudeSecondaryText.opacity(0.2),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            
            // Progress ring with enhanced styling
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90 + rotationAngle))
                .shadow(color: progressColor.opacity(showGlow ? 0.6 : 0), radius: showGlow ? 4 : 0)
                .scaleEffect(pulseScale)
            
            // Center indicator for different states
            centerIndicator
                .foregroundColor(progressColor)
                .font(.system(size: size * 0.4, weight: .medium))
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .frame(width: size, height: size)
        .onChange(of: progress) { newProgress in
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedProgress = newProgress
            }
        }
        .onChange(of: state) { newState in
            updateAnimationsForState(newState)
        }
        .onAppear {
            animatedProgress = progress
        }
    }
    
    // MARK: - Computed Properties
    
    private var progressColor: Color {
        switch state {
        case .idle: return .claudeSecondaryText
        case .running: return .claudeRunning
        case .paused: return .claudePaused
        case .completed: return .claudeCompleted
        case .error: return .claudeError
        }
    }
    
    private var progressGradient: AngularGradient {
        switch state {
        case .running:
            return AngularGradient(
                colors: [
                    progressColor,
                    progressColor.opacity(0.8),
                    progressColor.opacity(0.6),
                    progressColor
                ],
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        default:
            return AngularGradient(
                colors: [progressColor, progressColor],
                center: .center
            )
        }
    }
    
    @ViewBuilder
    private var centerIndicator: some View {
        switch state {
        case .idle:
            Image(systemName: "play.fill")
        case .running:
            Image(systemName: "pause.fill")
        case .paused:
            Image(systemName: "play.fill")
        case .completed:
            Image(systemName: "checkmark")
        case .error:
            Image(systemName: "exclamationmark")
        }
    }
    
    // MARK: - Animation Methods
    
    private func updateAnimationsForState(_ newState: SchedulerState) {
        switch newState {
        case .running:
            startRunningAnimations()
        case .completed:
            triggerCompletionPulse()
        case .error:
            triggerErrorPulse()
        default:
            stopAnimations()
        }
    }
    
    private func startRunningAnimations() {
        // Continuous subtle rotation for running state
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
    
    private func triggerCompletionPulse() {
        // Success pulse animation
        withAnimation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true)) {
            pulseScale = 1.1
        }
    }
    
    private func triggerErrorPulse() {
        // Error pulse animation
        withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
            pulseScale = 1.05
        }
    }
    
    private func stopAnimations() {
        withAnimation(.easeOut(duration: 0.3)) {
            rotationAngle = 0
            pulseScale = 1.0
        }
    }
}

// MARK: - Enhanced Tooltip View

struct TooltipView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(text.components(separatedBy: "\n"), id: \.self) { line in
                Text(line)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
        .fixedSize()
        .offset(x: -10, y: 30) // Position relative to menu bar item
    }
}

// MARK: - Extensions

extension NSNotification.Name {
    static let showEnhancedContextMenu = NSNotification.Name("showEnhancedContextMenu")
}

// MARK: - Preview Support

#if DEBUG
struct EnhancedMenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EnhancedMenuBarView(viewModel: MockSchedulerViewModel())
                .previewDisplayName("Idle State")
            
            EnhancedMenuBarView(viewModel: MockSchedulerViewModel(state: .running, progress: 0.3))
                .previewDisplayName("Running State")
            
            EnhancedMenuBarView(viewModel: MockSchedulerViewModel(state: .completed, progress: 1.0))
                .previewDisplayName("Completed State")
        }
        .padding()
        .background(Color(.windowBackgroundColor))
    }
}

class MockSchedulerViewModel: ObservableObject, SchedulerViewModel {
    @Published var sessionState: SchedulerState
    @Published var progress: Double
    @Published var timeRemaining: TimeInterval = 3600
    
    init(state: SchedulerState = .idle, progress: Double = 0.0) {
        self.sessionState = state
        self.progress = progress
    }
    
    func startSession() { sessionState = .running }
    func pauseSession() { sessionState = .paused }
    func resumeSession() { sessionState = .running }
    func stopSession() { sessionState = .idle }
    func resetSession() { sessionState = .idle; progress = 0.0 }
    func retrySession() { sessionState = .running }
}
#endif