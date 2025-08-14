import SwiftUI
import Combine

/// Real-time performance monitoring view with live charts and system metrics
struct PerformanceMonitoringView: View {
    @StateObject private var monitor = RealTimePerformanceMonitor()
    @State private var selectedTab: MonitorTab = .realtime
    @State private var autoRefresh = true
    @State private var refreshInterval: Double = 1.0
    
    enum MonitorTab: String, CaseIterable {
        case realtime = "Real-time"
        case history = "History"
        case diagnostics = "Diagnostics"
        case export = "Export"
        
        var icon: String {
            switch self {
            case .realtime: return "waveform.path.ecg"
            case .history: return "clock.arrow.circlepath"
            case .diagnostics: return "stethoscope"
            case .export: return "square.and.arrow.up"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            headerSection
            
            Divider()
            
            // Tab content
            TabView(selection: $selectedTab) {
                // Real-time monitoring
                realTimeView
                    .tabItem {
                        Label("Real-time", systemImage: "waveform.path.ecg")
                    }
                    .tag(MonitorTab.realtime)
                
                // Historical data
                historyView
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(MonitorTab.history)
                
                // Diagnostics
                diagnosticsView
                    .tabItem {
                        Label("Diagnostics", systemImage: "stethoscope")
                    }
                    .tag(MonitorTab.diagnostics)
                
                // Export tools
                exportView
                    .tabItem {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .tag(MonitorTab.export)
            }
        }
        .frame(width: 800, height: 600)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            if autoRefresh {
                monitor.startMonitoring(interval: refreshInterval)
            }
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Title and status
            VStack(alignment: .leading, spacing: 4) {
                Text("Performance Monitor")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    StatusIndicator(
                        status: monitor.systemHealth,
                        label: "System Health"
                    )
                    
                    StatusIndicator(
                        status: monitor.appPerformance,
                        label: "App Performance"
                    )
                    
                    StatusIndicator(
                        status: monitor.batteryImpact,
                        label: "Battery Impact"
                    )
                }
            }
            
            Spacer()
            
            // Controls
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 8) {
                    Toggle("Auto Refresh", isOn: $autoRefresh)
                        .onChange(of: autoRefresh) { enabled in
                            if enabled {
                                monitor.startMonitoring(interval: refreshInterval)
                            } else {
                                monitor.stopMonitoring()
                            }
                        }
                    
                    if autoRefresh {
                        Picker("Interval", selection: $refreshInterval) {
                            Text("0.5s").tag(0.5)
                            Text("1s").tag(1.0)
                            Text("2s").tag(2.0)
                            Text("5s").tag(5.0)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 60)
                        .onChange(of: refreshInterval) { interval in
                            monitor.updateInterval(interval)
                        }
                    }
                }
                
                HStack(spacing: 8) {
                    Button("Reset", action: monitor.resetData)
                        .controlSize(.small)
                    
                    Button("Optimize", action: monitor.optimizeNow)
                        .controlSize(.small)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Real-time View
    
    private var realTimeView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Key metrics cards
                keyMetricsSection
                
                // Live charts
                liveChartsSection
                
                // Resource usage details
                resourceDetailsSection
                
                // Recent events
                recentEventsSection
            }
            .padding()
        }
    }
    
    private var keyMetricsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
            MetricCard(
                title: "CPU Usage",
                value: String(format: "%.1f%%", monitor.currentMetrics.cpuUsage),
                trend: monitor.cpuTrend,
                color: monitor.currentMetrics.cpuUsage > 50 ? .orange : .green,
                target: "< 5%"
            )
            
            MetricCard(
                title: "Memory",
                value: String(format: "%.1f MB", monitor.currentMetrics.memoryUsage),
                trend: monitor.memoryTrend,
                color: monitor.currentMetrics.memoryUsage > 100 ? .red : .blue,
                target: "< 100 MB"
            )
            
            MetricCard(
                title: "Battery Impact",
                value: monitor.currentMetrics.batteryImpact.displayName,
                trend: .stable,
                color: monitor.currentMetrics.batteryImpact.color,
                target: "Low"
            )
            
            MetricCard(
                title: "Frame Rate",
                value: String(format: "%.0f fps", monitor.currentMetrics.frameRate),
                trend: monitor.frameRateTrend,
                color: monitor.currentMetrics.frameRate >= 60 ? .green : .yellow,
                target: "60 fps"
            )
        }
    }
    
    private var liveChartsSection: some View {
        VStack(spacing: 16) {
            Text("Live Performance Charts")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                // CPU Chart
                ChartView(
                    title: "CPU Usage",
                    data: monitor.cpuHistory,
                    color: .orange,
                    yAxisMax: 100
                )
                
                // Memory Chart
                ChartView(
                    title: "Memory Usage",
                    data: monitor.memoryHistory,
                    color: .blue,
                    yAxisMax: 200
                )
            }
            
            HStack(spacing: 16) {
                // Network Chart
                ChartView(
                    title: "Network Activity",
                    data: monitor.networkHistory,
                    color: .purple,
                    yAxisMax: 1000
                )
                
                // Disk Chart
                ChartView(
                    title: "Disk I/O",
                    data: monitor.diskHistory,
                    color: .green,
                    yAxisMax: 100
                )
            }
        }
    }
    
    private var resourceDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resource Details")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ResourceDetailCard(
                    icon: "cpu",
                    title: "Processor",
                    details: monitor.systemInfo.processorDetails
                )
                
                ResourceDetailCard(
                    icon: "memorychip",
                    title: "Memory",
                    details: monitor.systemInfo.memoryDetails
                )
                
                ResourceDetailCard(
                    icon: "network",
                    title: "Network",
                    details: monitor.systemInfo.networkDetails
                )
                
                ResourceDetailCard(
                    icon: "internaldrive",
                    title: "Storage",
                    details: monitor.systemInfo.storageDetails
                )
            }
        }
    }
    
    private var recentEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Events")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(monitor.recentEvents.prefix(10), id: \.id) { event in
                    EventRow(event: event)
                }
            }
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    // MARK: - History View
    
    private var historyView: some View {
        VStack {
            // Time range selector
            HStack {
                Text("Time Range:")
                    .font(.headline)
                
                Picker("Range", selection: $monitor.selectedTimeRange) {
                    Text("Last Hour").tag(TimeRange.hour)
                    Text("Last 6 Hours").tag(TimeRange.sixHours)
                    Text("Last Day").tag(TimeRange.day)
                    Text("Last Week").tag(TimeRange.week)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
                
                Button("Export Data") {
                    monitor.exportHistoricalData()
                }
            }
            .padding()
            
            // Historical charts
            ScrollView {
                LazyVStack(spacing: 20) {
                    LargeChartView(
                        title: "CPU Usage Over Time",
                        data: monitor.historicalCPU,
                        color: .orange
                    )
                    
                    LargeChartView(
                        title: "Memory Usage Over Time",
                        data: monitor.historicalMemory,
                        color: .blue
                    )
                    
                    LargeChartView(
                        title: "Battery Impact Over Time",
                        data: monitor.historicalBattery,
                        color: .green
                    )
                }
                .padding()
            }
        }
    }
    
    // MARK: - Diagnostics View
    
    private var diagnosticsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // System diagnostics
                DiagnosticSection(
                    title: "System Diagnostics",
                    items: monitor.systemDiagnostics
                )
                
                // App diagnostics
                DiagnosticSection(
                    title: "Application Diagnostics",
                    items: monitor.appDiagnostics
                )
                
                // Performance recommendations
                RecommendationsSection(
                    recommendations: monitor.performanceRecommendations
                )
                
                // Benchmarks
                BenchmarkSection(
                    results: monitor.benchmarkResults
                )
            }
            .padding()
        }
    }
    
    // MARK: - Export View
    
    private var exportView: some View {
        VStack(spacing: 20) {
            Text("Export Performance Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ExportCard(
                    icon: "doc.text",
                    title: "Performance Report",
                    description: "Comprehensive PDF report with charts and analysis",
                    action: { monitor.exportPerformanceReport() }
                )
                
                ExportCard(
                    icon: "tablecells",
                    title: "Raw Data (CSV)",
                    description: "Export raw metrics data for analysis",
                    action: { monitor.exportRawData() }
                )
                
                ExportCard(
                    icon: "chart.bar",
                    title: "Charts Bundle",
                    description: "High-resolution charts and graphs",
                    action: { monitor.exportCharts() }
                )
                
                ExportCard(
                    icon: "gear",
                    title: "Diagnostic Report",
                    description: "Technical diagnostic information",
                    action: { monitor.exportDiagnostics() }
                )
            }
            
            Spacer()
            
            // Export settings
            GroupBox("Export Settings") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Include system information", isOn: $monitor.includeSystemInfo)
                    Toggle("Include historical data", isOn: $monitor.includeHistoricalData)
                    Toggle("Include recommendations", isOn: $monitor.includeRecommendations)
                    Toggle("Anonymize sensitive data", isOn: $monitor.anonymizeData)
                }
            }
        }
        .padding()
    }
}

// MARK: - Supporting Views

struct StatusIndicator: View {
    let status: PerformanceStatus
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let trend: TrendDirection
    let color: Color
    let target: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                TrendIndicator(direction: trend)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("Target: \(target)")
                .font(.caption2)
                .foregroundColor(.tertiary)
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct TrendIndicator: View {
    let direction: TrendDirection
    
    var body: some View {
        Image(systemName: direction.iconName)
            .font(.caption)
            .foregroundColor(direction.color)
    }
}

struct ChartView: View {
    let title: String
    let data: [Double]
    let color: Color
    let yAxisMax: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Simple line chart representation
            GeometryReader { geometry in
                Path { path in
                    guard !data.isEmpty else { return }
                    
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepWidth = width / CGFloat(max(data.count - 1, 1))
                    
                    path.move(to: CGPoint(
                        x: 0,
                        y: height - (CGFloat(data[0] / yAxisMax) * height)
                    ))
                    
                    for i in 1..<data.count {
                        path.addLine(to: CGPoint(
                            x: CGFloat(i) * stepWidth,
                            y: height - (CGFloat(data[i] / yAxisMax) * height)
                        ))
                    }
                }
                .stroke(color, lineWidth: 2)
                
                // Data points
                ForEach(0..<data.count, id: \.self) { index in
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                        .position(
                            x: CGFloat(index) * (geometry.size.width / CGFloat(max(data.count - 1, 1))),
                            y: geometry.size.height - (CGFloat(data[index] / yAxisMax) * geometry.size.height)
                        )
                }
            }
            .frame(height: 80)
            .background(Color(.controlBackgroundColor).opacity(0.3))
            .cornerRadius(4)
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Types

enum PerformanceStatus {
    case excellent, good, fair, poor, critical
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .orange
        case .critical: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .critical: return "Critical"
        }
    }
}

enum TrendDirection {
    case up, down, stable
    
    var iconName: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .red
        case .down: return .green
        case .stable: return .secondary
        }
    }
}

enum TimeRange {
    case hour, sixHours, day, week
}

// MARK: - Preview

#if DEBUG
#Preview("Performance Monitor") {
    PerformanceMonitoringView()
}
#endif