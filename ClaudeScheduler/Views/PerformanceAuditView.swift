import SwiftUI
import Charts

/// Performance Audit Dashboard for ClaudeScheduler
/// Provides comprehensive performance monitoring and optimization interface
struct PerformanceAuditView: View {
    
    @StateObject private var performanceProfiler = PerformanceProfiler()
    @StateObject private var performanceOptimizer: PerformanceOptimizer
    @StateObject private var performanceBenchmark: PerformanceBenchmark
    
    @State private var selectedTab: AuditTab = .overview
    @State private var isRunningBenchmark = false
    @State private var showOptimizationSettings = false
    @State private var selectedBenchmarkSuite: PerformanceBenchmark.BenchmarkSuite?
    
    private let schedulerEngine: SchedulerEngine
    
    enum AuditTab: String, CaseIterable {
        case overview = "Overview"
        case realtime = "Real-time"
        case benchmark = "Benchmark"
        case optimization = "Optimization"
        case reports = "Reports"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .realtime: return "waveform.path.ecg"
            case .benchmark: return "speedometer"
            case .optimization: return "gear.badge"
            case .reports: return "doc.text.fill"
            }
        }
    }
    
    init(schedulerEngine: SchedulerEngine) {
        self.schedulerEngine = schedulerEngine
        self._performanceOptimizer = StateObject(wrappedValue: PerformanceOptimizer(
            performanceProfiler: PerformanceProfiler(),
            schedulerEngine: schedulerEngine
        ))
        self._performanceBenchmark = StateObject(wrappedValue: PerformanceBenchmark(
            performanceProfiler: PerformanceProfiler(),
            schedulerEngine: schedulerEngine
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                auditHeader
                
                // Tab Navigation
                tabNavigation
                
                // Content
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            performanceProfiler.startProfiling()
        }
        .onDisappear {
            performanceProfiler.stopProfiling()
        }
        .sheet(isPresented: $showOptimizationSettings) {
            OptimizationSettingsView(optimizer: performanceOptimizer)
        }
    }
    
    // MARK: - Header
    
    private var auditHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Performance Audit Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 16) {
                    performanceStatusBadge
                    profilingStatusBadge
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Export Data") {
                    exportPerformanceData()
                }
                .buttonStyle(.bordered)
                
                Button("Quick Audit") {
                    runQuickAudit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunningBenchmark)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var performanceStatusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(performanceProfiler.currentMetrics.isWithinTargets ? .green : .red)
                .frame(width: 8, height: 8)
            
            Text(performanceProfiler.currentMetrics.isWithinTargets ? "Optimal" : "Issues Detected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var profilingStatusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: performanceProfiler.isProfilerActive ? "record.circle.fill" : "record.circle")
                .foregroundColor(performanceProfiler.isProfilerActive ? .red : .secondary)
                .font(.caption)
            
            Text(performanceProfiler.isProfilerActive ? "Profiling Active" : "Profiling Inactive")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Tab Navigation
    
    private var tabNavigation: some View {
        HStack(spacing: 0) {
            ForEach(AuditTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            PerformanceOverviewView(profiler: performanceProfiler)
        case .realtime:
            RealTimeMonitoringView(profiler: performanceProfiler)
        case .benchmark:
            BenchmarkView(benchmark: performanceBenchmark)
        case .optimization:
            OptimizationView(optimizer: performanceOptimizer)
        case .reports:
            ReportsView(profiler: performanceProfiler, benchmark: performanceBenchmark)
        }
    }
    
    // MARK: - Actions
    
    private func exportPerformanceData() {
        guard let data = performanceProfiler.exportPerformanceData() else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "ClaudeScheduler_Performance_\\(Date().formatted(date: .numeric, time: .omitted)).json"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? data.write(to: url)
            }
        }
    }
    
    private func runQuickAudit() {
        isRunningBenchmark = true
        
        Task {
            _ = await performanceBenchmark.runQuickValidation()
            
            await MainActor.run {
                isRunningBenchmark = false
            }
        }
    }
}

// MARK: - Overview Tab

struct PerformanceOverviewView: View {
    @ObservedObject var profiler: PerformanceProfiler
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 300), spacing: 16)
            ], spacing: 16) {
                // Current Performance Card
                currentPerformanceCard
                
                // Performance Grade Card
                performanceGradeCard
                
                // Memory Usage Card
                memoryUsageCard
                
                // CPU Usage Card
                cpuUsageCard
                
                // UI Performance Card
                uiPerformanceCard
                
                // Energy Impact Card
                energyImpactCard
            }
            .padding()
        }
    }
    
    private var currentPerformanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Performance")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\\(String(format: \"%.1f\", profiler.currentMetrics.memoryUsageMB)) MB")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Memory Usage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\\(String(format: \"%.1f\", profiler.currentMetrics.cpuUsagePercent))%")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("CPU Usage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: profiler.currentMetrics.memoryUsageMB / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: memoryUsageColor))
                .scaleEffect(y: 2.0)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var performanceGradeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Grade")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text(profiler.currentMetrics.performanceGrade.rawValue)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color(profiler.currentMetrics.performanceGrade.color))
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\\(Int(profiler.currentMetrics.performanceGrade.calculatePerformanceScore()))")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(profiler.currentMetrics.performanceGrade.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var memoryUsageCard: some View {
        MetricsCard(
            title: "Memory Usage",
            value: "\\(String(format: \"%.1f\", profiler.currentMetrics.memoryUsageMB)) MB",
            subtitle: "Target: <50MB",
            progress: profiler.currentMetrics.memoryUsageMB / 100.0,
            progressColor: memoryUsageColor,
            isTargetMet: profiler.currentMetrics.memoryUsageMB < 50.0
        )
    }
    
    private var cpuUsageCard: some View {
        MetricsCard(
            title: "CPU Usage",
            value: "\\(String(format: \"%.1f\", profiler.currentMetrics.cpuUsagePercent))%",
            subtitle: "Target: <1%",
            progress: profiler.currentMetrics.cpuUsagePercent / 10.0,
            progressColor: cpuUsageColor,
            isTargetMet: profiler.currentMetrics.cpuUsagePercent < 1.0
        )
    }
    
    private var uiPerformanceCard: some View {
        MetricsCard(
            title: "Animation FPS",
            value: "\\(String(format: \"%.0f\", profiler.currentMetrics.animationFramerate))",
            subtitle: "Target: ≥58fps",
            progress: profiler.currentMetrics.animationFramerate / 60.0,
            progressColor: uiPerformanceColor,
            isTargetMet: profiler.currentMetrics.animationFramerate >= 58.0
        )
    }
    
    private var energyImpactCard: some View {
        MetricsCard(
            title: "Energy Impact",
            value: profiler.currentMetrics.energyImpact.rawValue,
            subtitle: "Target: Low",
            progress: profiler.currentMetrics.energyImpact.energyImpact,
            progressColor: energyImpactColor,
            isTargetMet: profiler.currentMetrics.energyImpact.energyImpact <= 0.3
        )
    }
    
    // Color helpers
    private var memoryUsageColor: Color {
        profiler.currentMetrics.memoryUsageMB < 50.0 ? .green : .red
    }
    
    private var cpuUsageColor: Color {
        profiler.currentMetrics.cpuUsagePercent < 1.0 ? .green : .red
    }
    
    private var uiPerformanceColor: Color {
        profiler.currentMetrics.animationFramerate >= 58.0 ? .green : .red
    }
    
    private var energyImpactColor: Color {
        profiler.currentMetrics.energyImpact.energyImpact <= 0.3 ? .green : .red
    }
}

// MARK: - Metrics Card Component

struct MetricsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    let progressColor: Color
    let isTargetMet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: isTargetMet ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(isTargetMet ? .green : .orange)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(progressColor)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: min(1.0, progress))
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .scaleEffect(y: 2.0)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Real-time Monitoring View

struct RealTimeMonitoringView: View {
    @ObservedObject var profiler: PerformanceProfiler
    
    var body: some View {
        VStack(spacing: 20) {
            // Real-time charts would go here
            Text("Real-time Performance Monitoring")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Memory Chart
            GroupBox("Memory Usage Over Time") {
                RealTimeChart(
                    data: profiler.performanceHistory.suffix(50).map { $0.memoryUsageMB },
                    color: .blue,
                    target: 50.0
                )
                .frame(height: 200)
            }
            
            // CPU Chart
            GroupBox("CPU Usage Over Time") {
                RealTimeChart(
                    data: profiler.performanceHistory.suffix(50).map { $0.cpuUsagePercent },
                    color: .green,
                    target: 1.0
                )
                .frame(height: 200)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Real-time Chart Component

struct RealTimeChart: View {
    let data: [Double]
    let color: Color
    let target: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Target line
                Path { path in
                    let maxValue = max(data.max() ?? 0, target * 1.2)
                    let y = geometry.size.height - (target / maxValue) * geometry.size.height
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
                .stroke(Color.red.opacity(0.5), lineWidth: 2)
                .overlay(
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.red)
                        .background(Color.white.opacity(0.8))
                        .position(x: geometry.size.width - 30, y: geometry.size.height - (target / (data.max() ?? 1)) * geometry.size.height)
                )
                
                // Data line
                Path { path in
                    guard !data.isEmpty else { return }
                    
                    let maxValue = max(data.max() ?? 0, target * 1.2)
                    let stepX = geometry.size.width / CGFloat(data.count - 1)
                    
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height - (value / maxValue) * geometry.size.height
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: 2)
            }
        }
    }
}

// MARK: - Benchmark View

struct BenchmarkView: View {
    @ObservedObject var benchmark: PerformanceBenchmark
    @State private var selectedSuite: PerformanceBenchmark.BenchmarkSuite?
    
    var body: some View {
        VStack(spacing: 20) {
            // Benchmark Controls
            HStack {
                Text("Performance Benchmarks")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Run Complete Suite") {
                    runCompleteBenchmark()
                }
                .buttonStyle(.borderedProminent)
                .disabled(benchmark.isRunning)
            }
            
            // Current Benchmark Status
            if benchmark.isRunning {
                VStack(spacing: 12) {
                    ProgressView(value: benchmark.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text(benchmark.currentPhase)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if benchmark.estimatedTimeRemaining > 0 {
                        Text("Estimated time remaining: \\(formatTimeInterval(benchmark.estimatedTimeRemaining))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Individual Benchmark Suites
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 200), spacing: 16)
            ], spacing: 16) {
                ForEach(PerformanceBenchmark.BenchmarkSuite.allCases, id: \.self) { suite in
                    BenchmarkSuiteCard(
                        suite: suite,
                        onRun: { runSuite(suite) },
                        isRunning: benchmark.isRunning && benchmark.currentSuite == suite
                    )
                }
            }
            
            // Results
            if !benchmark.results.isEmpty {
                BenchmarkResultsView(results: benchmark.results)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func runCompleteBenchmark() {
        Task {
            _ = await benchmark.runCompleteBenchmark()
        }
    }
    
    private func runSuite(_ suite: PerformanceBenchmark.BenchmarkSuite) {
        Task {
            _ = await benchmark.runSuite(suite)
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return "\\(minutes)m \\(seconds)s"
    }
}

// MARK: - Benchmark Suite Card

struct BenchmarkSuiteCard: View {
    let suite: PerformanceBenchmark.BenchmarkSuite
    let onRun: () -> Void
    let isRunning: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(suite.rawValue)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(suite.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            Text("Est. \\(formatDuration(suite.estimatedDuration))")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(isRunning ? "Running..." : "Run Test") {
                onRun()
            }
            .buttonStyle(.bordered)
            .disabled(isRunning)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isRunning ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return "\\(Int(duration))s"
        } else if duration < 3600 {
            return "\\(Int(duration / 60))m"
        } else {
            return "\\(Int(duration / 3600))h"
        }
    }
}

// MARK: - Benchmark Results View

struct BenchmarkResultsView: View {
    let results: [PerformanceBenchmark.BenchmarkResult]
    
    var body: some View {
        GroupBox("Benchmark Results") {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(results) { result in
                        BenchmarkResultRow(result: result)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }
}

// MARK: - Benchmark Result Row

struct BenchmarkResultRow: View {
    let result: PerformanceBenchmark.BenchmarkResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.suite)
                    .font(.headline)
                
                Text("Duration: \\(formatDuration(result.duration))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(result.grade.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(result.grade.color))
                
                Text("\\(Int(result.score))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.passed ? .green : .red)
                .font(.title2)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\\(minutes)m \\(seconds)s"
    }
}

// MARK: - Optimization View

struct OptimizationView: View {
    @ObservedObject var optimizer: PerformanceOptimizer
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Performance Optimization")
                .font(.title2)
                .fontWeight(.semibold)
            
            // TODO: Implement optimization interface
            Text("Optimization controls will be implemented here")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Reports View

struct ReportsView: View {
    @ObservedObject var profiler: PerformanceProfiler
    @ObservedObject var benchmark: PerformanceBenchmark
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Performance Reports")
                .font(.title2)
                .fontWeight(.semibold)
            
            // TODO: Implement reports interface
            Text("Detailed reports will be implemented here")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Optimization Settings View

struct OptimizationSettingsView: View {
    @ObservedObject var optimizer: PerformanceOptimizer
    @Environment(\\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Optimization Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            // TODO: Implement optimization settings
            Text("Optimization settings will be implemented here")
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Apply") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

// MARK: - Extensions

extension PerformanceProfiler.DetailedMetrics.PerformanceGrade {
    func calculatePerformanceScore() -> Double {
        switch self {
        case .excellent: return 95.0
        case .good: return 85.0
        case .acceptable: return 75.0
        case .poor: return 60.0
        case .critical: return 40.0
        }
    }
}