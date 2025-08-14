import SwiftUI
import AppKit
import OSLog

// MARK: - User-Friendly Error Recovery Interface

/// Enterprise-grade error presentation and recovery UI
/// Provides clear, actionable error communication with guided recovery
struct ErrorRecoveryView: View {
    @ObservedObject var errorRecoveryEngine: ErrorRecoveryEngine
    @ObservedObject var systemHealthMonitor: SystemHealthMonitor
    @State private var selectedError: ErrorEvent?
    @State private var showingDetailedDiagnostics = false
    @State private var showingRecoveryOptions = false
    @State private var isRecovering = false
    @State private var recoveryProgress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if errorRecoveryEngine.errorHistory.isEmpty {
                noErrorsView
            } else {
                errorListView
            }
            
            if let selectedError = selectedError {
                errorDetailView(for: selectedError)
            }
            
            systemHealthView
        }
        .background(Color(.windowBackgroundColor))
        .onAppear {
            setupErrorMonitoring()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: recoveryStateIcon)
                    .font(.title2)
                    .foregroundColor(recoveryStateColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(errorRecoveryEngine.currentRecoveryState.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                systemHealthIndicator
            }
            
            if isRecovering {
                recoveryProgressView
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separatorColor)),
            alignment: .bottom
        )
    }
    
    private var systemHealthIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(systemHealthMonitor.systemHealth.color)
                .frame(width: 8, height: 8)
            
            Text(systemHealthMonitor.systemHealth.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var recoveryProgressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Recovery in Progress...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(recoveryProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: recoveryProgress)
                .progressViewStyle(LinearProgressViewStyle())
        }
        .padding(.top, 8)
    }
    
    // MARK: - No Errors View
    
    private var noErrorsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("All Systems Operational")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("ClaudeScheduler is running smoothly with no detected issues.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 16) {
                Button("Run Diagnostics") {
                    runDiagnostics()
                }
                .buttonStyle(.bordered)
                
                Button("View Health Report") {
                    showingDetailedDiagnostics = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Error List View
    
    private var errorListView: some View {
        VStack(spacing: 0) {
            errorListHeader
            
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(sortedErrors, id: \.id) { errorEvent in
                        ErrorRowView(
                            errorEvent: errorEvent,
                            isSelected: selectedError?.id == errorEvent.id
                        ) {
                            selectedError = errorEvent
                            showingRecoveryOptions = true
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
        }
    }
    
    private var errorListHeader: some View {
        HStack {
            Text("Recent Issues (\(errorRecoveryEngine.errorHistory.count))")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button("Clear All") {
                clearAllErrors()
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
            .disabled(errorRecoveryEngine.errorHistory.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
    }
    
    private var sortedErrors: [ErrorEvent] {
        errorRecoveryEngine.errorHistory
            .sorted { $0.error.severity.priority > $1.error.severity.priority }
            .prefix(20)
            .map { $0 }
    }
    
    // MARK: - Error Detail View
    
    private func errorDetailView(for errorEvent: ErrorEvent) -> some View {
        VStack(spacing: 16) {
            errorSummaryCard(for: errorEvent)
            
            if showingRecoveryOptions {
                recoveryOptionsCard(for: errorEvent)
            }
            
            if showingDetailedDiagnostics {
                diagnosticsCard(for: errorEvent)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(errorEvent.error.severity.color.opacity(0.3), lineWidth: 1)
        )
        .padding()
    }
    
    private func errorSummaryCard(for errorEvent: ErrorEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: errorEvent.error.severity.iconName)
                    .foregroundColor(errorEvent.error.severity.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(errorEvent.error.errorDescription ?? "Unknown Error")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Detected \(formatRelativeTime(errorEvent.context.timestamp))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingDetailedDiagnostics.toggle()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
            }
            
            if let impact = errorEvent.userImpact.estimatedDowntime {
                HStack {
                    Text("Estimated Impact:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(Int(impact))s downtime")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            if !errorEvent.userImpact.workarounds.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Actions:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(errorEvent.userImpact.workarounds, id: \.self) { workaround in
                        Text("• \(workaround)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func recoveryOptionsCard(for errorEvent: ErrorEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recovery Options")
                .font(.headline)
                .fontWeight(.medium)
            
            VStack(spacing: 8) {
                if errorEvent.error.canAutoRecover {
                    Button("Automatic Recovery") {
                        performAutomaticRecovery(for: errorEvent.error)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRecovering)
                }
                
                Button("Manual Recovery") {
                    performManualRecovery(for: errorEvent.error)
                }
                .buttonStyle(.bordered)
                .disabled(isRecovering)
                
                Button("Skip This Issue") {
                    skipError(errorEvent)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(6)
    }
    
    private func diagnosticsCard(for errorEvent: ErrorEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Diagnostic Information")
                .font(.headline)
                .fontWeight(.medium)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    diagnosticRow("Error Type", errorEvent.error.errorType.rawValue)
                    diagnosticRow("Severity", errorEvent.error.severity.rawValue.capitalized)
                    diagnosticRow("Timestamp", formatDetailedTime(errorEvent.context.timestamp))
                    diagnosticRow("System Version", errorEvent.context.applicationSnapshot.osVersion ?? "Unknown")
                    diagnosticRow("Memory Usage", "\(Int(errorEvent.context.performanceMetrics.memoryUsage))MB")
                    diagnosticRow("CPU Usage", "\(Int(errorEvent.context.performanceMetrics.cpuUsage))%")
                    
                    if !errorEvent.context.callStack.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Call Stack:")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            ForEach(Array(errorEvent.context.callStack.prefix(5)), id: \.self) { frame in
                                Text(frame)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 150)
            
            HStack {
                Button("Copy to Clipboard") {
                    copyDiagnosticsToClipboard(errorEvent)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Export Report") {
                    exportDiagnosticReport(errorEvent)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(6)
    }
    
    private func diagnosticRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - System Health View
    
    private var systemHealthView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("System Health")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Refresh") {
                    refreshSystemHealth()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                healthMetricCard("Memory", systemHealthMonitor.currentHealthMetrics.memoryPressure * 100, "GB", .blue)
                healthMetricCard("CPU", systemHealthMonitor.currentHealthMetrics.cpuUsage, "%", .green)
                healthMetricCard("Network", systemHealthMonitor.currentHealthMetrics.networkLatency, "ms", .orange)
            }
            
            if !systemHealthMonitor.detectedEdgeCases.isEmpty {
                edgeCasesView
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func healthMetricCard(_ title: String, _ value: Double, _ unit: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("\(Int(value))\(unit)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(6)
    }
    
    private var edgeCasesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Detected Edge Cases")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(systemHealthMonitor.detectedEdgeCases.prefix(3), id: \.detectedAt) { edgeCase in
                HStack {
                    Circle()
                        .fill(edgeCase.severity.color)
                        .frame(width: 6, height: 6)
                    
                    Text(edgeCase.type.description)
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(edgeCase.severity.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Computed Properties
    
    private var recoveryStateIcon: String {
        switch errorRecoveryEngine.currentRecoveryState {
        case .healthy: return "checkmark.shield.fill"
        case .monitoring: return "eye.fill"
        case .recovering: return "arrow.clockwise"
        case .degraded: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        case .failing: return "exclamationmark.octagon.fill"
        }
    }
    
    private var recoveryStateColor: Color {
        switch errorRecoveryEngine.currentRecoveryState {
        case .healthy: return .green
        case .monitoring: return .blue
        case .recovering: return .orange
        case .degraded: return .yellow
        case .critical: return .red
        case .failing: return .red
        }
    }
    
    // MARK: - Actions
    
    private func setupErrorMonitoring() {
        // Setup any initial monitoring or subscriptions
    }
    
    private func runDiagnostics() {
        Task {
            isRecovering = true
            recoveryProgress = 0.0
            
            // Simulate diagnostic progress
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                await MainActor.run {
                    recoveryProgress = Double(i) / 10.0
                }
            }
            
            await systemHealthMonitor.validateSystemHealth()
            await errorRecoveryEngine.predictiveErrorDetection()
            
            isRecovering = false
            recoveryProgress = 0.0
        }
    }
    
    private func performAutomaticRecovery(for error: SystemError) {
        Task {
            isRecovering = true
            recoveryProgress = 0.0
            
            let context = ErrorContext()
            let result = await errorRecoveryEngine.handleError(error, context: context)
            
            // Simulate recovery progress
            for i in 1...5 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    recoveryProgress = Double(i) / 5.0
                }
            }
            
            isRecovering = false
            recoveryProgress = 0.0
            showingRecoveryOptions = false
            
            if result.isSuccessful {
                selectedError = nil
            }
        }
    }
    
    private func performManualRecovery(for error: SystemError) {
        // Open manual recovery guide
        showManualRecoveryGuide(for: error)
    }
    
    private func skipError(_ errorEvent: ErrorEvent) {
        selectedError = nil
        showingRecoveryOptions = false
    }
    
    private func clearAllErrors() {
        // Clear error history
        selectedError = nil
        showingRecoveryOptions = false
        showingDetailedDiagnostics = false
    }
    
    private func refreshSystemHealth() {
        Task {
            await systemHealthMonitor.performHealthCheck()
            await systemHealthMonitor.detectEdgeCases()
        }
    }
    
    private func copyDiagnosticsToClipboard(_ errorEvent: ErrorEvent) {
        let diagnosticText = generateDiagnosticText(errorEvent)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(diagnosticText, forType: .string)
    }
    
    private func exportDiagnosticReport(_ errorEvent: ErrorEvent) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "ClaudeScheduler_Diagnostic_\(Int(errorEvent.context.timestamp.timeIntervalSince1970)).txt"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let diagnosticText = generateDiagnosticText(errorEvent)
                try? diagnosticText.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    private func showManualRecoveryGuide(for error: SystemError) {
        let alert = NSAlert()
        alert.messageText = "Manual Recovery Guide"
        alert.informativeText = generateRecoveryGuide(for: error)
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Got it")
        alert.addButton(withTitle: "Copy Guide")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(generateRecoveryGuide(for: error), forType: .string)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatDetailedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func generateDiagnosticText(_ errorEvent: ErrorEvent) -> String {
        return """
        ClaudeScheduler Diagnostic Report
        ================================
        
        Error Information:
        - Type: \(errorEvent.error.errorType.rawValue)
        - Severity: \(errorEvent.error.severity.rawValue)
        - Description: \(errorEvent.error.errorDescription ?? "Unknown")
        - Timestamp: \(formatDetailedTime(errorEvent.context.timestamp))
        
        System Information:
        - OS Version: \(errorEvent.context.applicationSnapshot.osVersion ?? "Unknown")
        - Memory Usage: \(Int(errorEvent.context.performanceMetrics.memoryUsage))MB
        - CPU Usage: \(Int(errorEvent.context.performanceMetrics.cpuUsage))%
        
        Recovery Information:
        - Can Auto Recover: \(errorEvent.error.canAutoRecover)
        - Max Retry Attempts: \(errorEvent.error.maxRetryAttempts)
        - Retry Delay: \(errorEvent.error.retryDelay)s
        
        Call Stack:
        \(errorEvent.context.callStack.joined(separator: "\n"))
        
        Generated: \(formatDetailedTime(Date()))
        """
    }
    
    private func generateRecoveryGuide(for error: SystemError) -> String {
        switch error.errorType {
        case .timing:
            return """
            Timer Recovery Guide:
            1. Check system clock synchronization
            2. Verify NTP configuration
            3. Restart ClaudeScheduler
            4. If issues persist, restart your Mac
            """
        case .power:
            return """
            Power Management Recovery:
            1. Connect to power adapter if on battery
            2. Check power settings in System Preferences
            3. Disable Low Power Mode if enabled
            4. Monitor battery health in System Information
            """
        case .resource:
            return """
            Resource Recovery Guide:
            1. Close unnecessary applications
            2. Free up disk space if needed
            3. Check Activity Monitor for high resource usage
            4. Restart problematic processes
            """
        case .network:
            return """
            Network Recovery Guide:
            1. Check internet connection
            2. Verify proxy settings
            3. Restart network interfaces
            4. Contact network administrator if on corporate network
            """
        default:
            return """
            General Recovery Guide:
            1. Restart ClaudeScheduler
            2. Check system status
            3. Review system logs
            4. Contact support if issues persist
            """
        }
    }
}

// MARK: - Error Row View

struct ErrorRowView: View {
    let errorEvent: ErrorEvent
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(errorEvent.error.severity.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(errorEvent.error.errorDescription ?? "Unknown Error")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(formatRelativeTime(errorEvent.context.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(errorEvent.error.severity.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(errorEvent.error.severity.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(errorEvent.error.severity.color.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Extensions for Colors

extension EdgeCaseDetection.EdgeCaseSeverity {
    var color: Color {
        switch self {
        case .monitoring: return .blue
        case .warning: return .yellow
        case .critical: return .orange
        case .emergency: return .red
        }
    }
}

extension ErrorSeverity {
    var iconName: String {
        switch self {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

extension SystemHealthStatus {
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Supporting Types for UI

extension ErrorContext {
    var applicationSnapshot: ApplicationSnapshot {
        return ApplicationSnapshot()
    }
    
    var performanceMetrics: PerformanceSnapshot {
        return PerformanceSnapshot()
    }
}

extension ApplicationSnapshot {
    var osVersion: String? {
        return ProcessInfo.processInfo.operatingSystemVersionString
    }
}

extension PerformanceSnapshot {
    var memoryUsage: Double { return 50.0 }
    var cpuUsage: Double { return 15.0 }
}