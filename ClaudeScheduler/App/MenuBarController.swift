import SwiftUI
import AppKit
import Combine

/// Controls the NSStatusBar item and manages menu bar interactions
class MenuBarController: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem?
    private var hostingView: NSHostingView<MenuBarStatusView>?
    private var contextMenuHostingView: NSHostingView<SchedulerContextMenu>?
    private let schedulerEngine: SchedulerEngine
    private var schedulerViewModel: SchedulerViewModelImpl
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(schedulerEngine: SchedulerEngine) {
        self.schedulerEngine = schedulerEngine
        self.schedulerViewModel = SchedulerViewModelImpl(schedulerEngine: schedulerEngine)
        super.init()
        
        setupStatusItem()
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupStatusItem() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else {
            fatalError("Failed to create status item")
        }
        
        // Create SwiftUI view for the menu bar button
        let menuBarView = MenuBarStatusView(scheduler: schedulerViewModel)
        hostingView = NSHostingView(rootView: menuBarView)
        hostingView?.frame = NSRect(x: 0, y: 0, width: 60, height: 22)
        
        // Set the hosting view as the button's view
        statusItem.button?.addSubview(hostingView!)
        hostingView?.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup constraints
        if let button = statusItem.button, let hostingView = hostingView {
            NSLayoutConstraint.activate([
                hostingView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                hostingView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                hostingView.widthAnchor.constraint(lessThanOrEqualToConstant: 100),
                hostingView.heightAnchor.constraint(equalToConstant: 22)
            ])
        }
        
        // Setup click action for context menu
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.target = self
        
        print("📍 Menu bar status item created")
    }
    
    private func setupBindings() {
        // Subscribe to state changes to update the menu bar view
        schedulerViewModel.$state
            .combineLatest(schedulerViewModel.$progress)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] state, progress in
                self?.updateMenuBarAppearance(state: state, progress: progress)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func statusItemClicked() {
        showContextMenu()
    }
    
    private func showContextMenu() {
        guard let statusItem = statusItem else { return }
        
        // Create context menu view
        let contextMenuView = SchedulerContextMenu(scheduler: schedulerViewModel)
        contextMenuHostingView = NSHostingView(rootView: contextMenuView)
        
        // Create NSMenu with hosting view
        let menu = NSMenu()
        let menuItem = NSMenuItem()
        menuItem.view = contextMenuHostingView
        menu.addItem(menuItem)
        
        // Show menu
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        
        // Clear menu after showing to prevent issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            statusItem.menu = nil
        }
    }
    
    private func updateMenuBarAppearance(state: SchedulerState, progress: Double) {
        // Update accessibility
        statusItem?.button?.toolTip = generateToolTip(state: state, progress: progress)
        
        // The SwiftUI view will automatically update based on @Published properties
        // No manual drawing needed thanks to reactive architecture
    }
    
    private func generateToolTip(state: SchedulerState, progress: Double) -> String {
        switch state {
        case .idle:
            return "ClaudeScheduler - Ready to start"
        case .running:
            return "ClaudeScheduler - Session running (\(Int(progress * 100))% complete)"
        case .paused:
            return "ClaudeScheduler - Session paused (\(Int(progress * 100))% complete)"
        case .completed:
            return "ClaudeScheduler - Session completed"
        case .error:
            return "ClaudeScheduler - Error occurred"
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        statusItem = nil
        hostingView = nil
        contextMenuHostingView = nil
        cancellables.removeAll()
        
        print("🧹 MenuBarController cleanup completed")
    }
}

// MARK: - MenuBarController Extensions

extension MenuBarController {
    
    /// Updates the menu bar item size based on content
    private func updateStatusItemLength() {
        // SwiftUI will handle this automatically through its layout system
        // The variableLength status item will adapt to content
    }
    
    /// Handles system appearance changes
    @objc private func systemAppearanceChanged() {
        // SwiftUI automatically handles dark/light mode changes
        // No manual intervention needed
        print("🎨 System appearance changed")
    }
}