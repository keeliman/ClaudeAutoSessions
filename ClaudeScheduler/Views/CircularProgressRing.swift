import SwiftUI

/// Circular progress ring component with smooth animations and state-aware styling
/// This is the signature visual element of ClaudeScheduler
struct CircularProgressRing: View {
    let progress: Double
    let state: SchedulerState
    let size: CGFloat
    
    init(progress: Double, state: SchedulerState, size: CGFloat = 16) {
        self.progress = progress
        self.state = state
        self.size = size
    }
    
    private var ringWidth: CGFloat { 
        size * 0.125 // 2px for 16px icon, scales proportionally
    }
    
    private var ringRadius: CGFloat { 
        (size - ringWidth) / 2 
    }
    
    private var progressColor: Color {
        switch state {
        case .idle: 
            return .claudeIdle
        case .running: 
            return .claudeRunning
        case .paused: 
            return .claudePaused
        case .completed: 
            return .claudeCompleted
        case .error: 
            return .claudeError
        }
    }
    
    @State private var isHovered = false
    @State private var pulsePhase = 0.0
    @State private var flashPhase = 0.0
    @State private var shakeOffset: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // Background Ring
            Circle()
                .stroke(Color.claudeIdle.opacity(0.2), lineWidth: ringWidth)
                .frame(width: size, height: size)
            
            // Progress Ring (only visible when there's progress)
            if progress > 0 {
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
                    .animation(.easeOut(duration: ClaudeAnimation.progress), value: progress)
            }
            
            // Center Icon
            centerIcon
                .font(.system(size: size * 0.25, weight: .medium))
        }
        .opacity(dynamicOpacity)
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .offset(x: shakeOffset)
        .animation(ClaudeAnimation.easeOut, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            startStateAnimations()
        }
        .onChange(of: state) { _, newState in
            startStateAnimations()
        }
    }
    
    // MARK: - Dynamic Properties
    
    private var dynamicOpacity: Double {
        switch state {
        case .paused:
            return 0.7 + 0.3 * sin(pulsePhase)
        case .error:
            return 0.8 + 0.2 * sin(flashPhase)
        default:
            return 1.0
        }
    }
    
    private var centerIcon: some View {
        Group {
            switch state {
            case .idle:
                Image(systemName: "play.fill")
                    .foregroundColor(.claudeIdle)
                    .transition(.scale.combined(with: .opacity))
                    
            case .running:
                Image(systemName: "pause.fill")
                    .foregroundColor(.claudeRunning)
                    .transition(.scale.combined(with: .opacity))
                    
            case .paused:
                HStack(spacing: 1) {
                    Rectangle()
                        .fill(Color.claudePaused)
                        .frame(width: 1, height: size * 0.25)
                    Rectangle()
                        .fill(Color.claudePaused)
                        .frame(width: 1, height: size * 0.25)
                }
                .transition(.scale.combined(with: .opacity))
                
            case .completed:
                Image(systemName: "checkmark")
                    .foregroundColor(.claudeCompleted)
                    .scaleEffect(1.15)
                    .transition(.scale.combined(with: .opacity))
                    
            case .error:
                Image(systemName: "exclamationmark")
                    .foregroundColor(.claudeError)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Animation Methods
    
    private func startStateAnimations() {
        switch state {
        case .paused:
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulsePhase = .pi * 2
            }
            
        case .error:
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                flashPhase = .pi * 2
            }
            
            // Subtle shake on error
            withAnimation(.easeInOut(duration: 0.1)) {
                shakeOffset = 1.0
            }
            withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                shakeOffset = -1.0
            }
            withAnimation(.easeInOut(duration: 0.1).delay(0.2)) {
                shakeOffset = 0.0
            }
            
        case .completed:
            // Success bounce animation
            withAnimation(.interpolatingSpring(stiffness: 400, damping: 20)) {
                // Animation is handled by scaleEffect in centerIcon
            }
            
        default:
            // Reset animation states
            pulsePhase = 0.0
            flashPhase = 0.0
            shakeOffset = 0.0
        }
    }
}

// MARK: - Accessibility Support

extension CircularProgressRing {
    
    var accessibilityLabel: String {
        switch state {
        case .idle:
            return "Ready to start session"
        case .running:
            return "Session in progress"
        case .paused:
            return "Session paused"
        case .completed:
            return "Session completed"
        case .error:
            return "Error occurred"
        }
    }
    
    var accessibilityValue: String {
        switch state {
        case .running, .paused:
            return "\(Int(progress * 100)) percent complete"
        case .completed:
            return "100 percent complete"
        default:
            return state.displayName
        }
    }
    
    func withAccessibility() -> some View {
        self
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue)
            .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Preview Support

#if DEBUG
#Preview("Progress States") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            VStack {
                CircularProgressRing(progress: 0.0, state: .idle, size: 32)
                Text("Idle")
                    .font(.caption)
            }
            
            VStack {
                CircularProgressRing(progress: 0.45, state: .running, size: 32)
                Text("Running")
                    .font(.caption)
            }
            
            VStack {
                CircularProgressRing(progress: 0.65, state: .paused, size: 32)
                Text("Paused")
                    .font(.caption)
            }
        }
        
        HStack(spacing: 20) {
            VStack {
                CircularProgressRing(progress: 1.0, state: .completed, size: 32)
                Text("Completed")
                    .font(.caption)
            }
            
            VStack {
                CircularProgressRing(progress: 0.3, state: .error, size: 32)
                Text("Error")
                    .font(.caption)
            }
        }
        
        // Size variations
        HStack(spacing: 10) {
            CircularProgressRing(progress: 0.5, state: .running, size: 16)
            CircularProgressRing(progress: 0.5, state: .running, size: 24)
            CircularProgressRing(progress: 0.5, state: .running, size: 32)
            CircularProgressRing(progress: 0.5, state: .running, size: 48)
        }
    }
    .padding()
}

#Preview("Menu Bar Size") {
    HStack(spacing: 8) {
        CircularProgressRing(progress: 0.0, state: .idle, size: 16)
        Text("2h 34m")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(.secondary)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color.black.opacity(0.1))
    .cornerRadius(4)
}

#Preview("Dark Mode") {
    VStack(spacing: 20) {
        CircularProgressRing(progress: 0.45, state: .running, size: 32)
        CircularProgressRing(progress: 0.65, state: .paused, size: 32)
        CircularProgressRing(progress: 1.0, state: .completed, size: 32)
    }
    .padding()
    .preferredColorScheme(.dark)
}
#endif