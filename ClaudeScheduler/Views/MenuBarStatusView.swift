import SwiftUI

/// SwiftUI view for the menu bar status item
/// Displays current scheduler state and progress in the menu bar
struct MenuBarStatusView: View {
    
    // MARK: - Dependencies
    
    @ObservedObject var scheduler: SchedulerViewModelImpl
    
    // MARK: - View
    
    var body: some View {
        HStack(spacing: 4) {
            // Status icon with state-based color
            statusIcon
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(scheduler.state.color)
                .animation(ClaudeAnimation.stateTransition, value: scheduler.state)
            
            // Progress indicator (only shown when running)
            if scheduler.state == .running || scheduler.state == .paused {
                progressIndicator
            }
        }
        .frame(maxWidth: 60, maxHeight: 22)
        .contentShape(Rectangle())
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var statusIcon: some View {
        Image(systemName: scheduler.state.systemIconName)
            .symbolRenderingMode(.hierarchical)
            .symbolEffect(.bounce, value: scheduler.state)
    }
    
    @ViewBuilder
    private var progressIndicator: some View {
        if scheduler.progress > 0 {
            CircularProgressRing(
                progress: scheduler.progress,
                lineWidth: 2,
                color: scheduler.state.color
            )
            .frame(width: 14, height: 14)
            .animation(ClaudeAnimation.progressUpdate, value: scheduler.progress)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Idle State") {
    MenuBarStatusView(scheduler: MockSchedulerViewModel())
        .frame(width: 60, height: 22)
        .background(Color.gray.opacity(0.1))
}

#Preview("Running State") {
    let mock = MockSchedulerViewModel()
    mock.state = .running
    
    return MenuBarStatusView(scheduler: mock)
        .frame(width: 60, height: 22)
        .background(Color.gray.opacity(0.1))
}

#Preview("Error State") {
    let mock = MockSchedulerViewModel()
    mock.state = .error
    
    return MenuBarStatusView(scheduler: mock)
        .frame(width: 60, height: 22)
        .background(Color.gray.opacity(0.1))
}
#endif