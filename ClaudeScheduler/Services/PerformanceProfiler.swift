import Foundation
import OSLog
import AppKit
import Combine

// MARK: - Performance Profiler for ClaudeScheduler

/// Comprehensive performance monitoring and profiling system
/// Tracks memory, CPU, UI performance, and provides optimization recommendations
class PerformanceProfiler: ObservableObject {
    
    // MARK: - Performance Metrics Structure
    
    struct DetailedMetrics: Codable {
        var timestamp: Date
        var memoryUsageMB: Double
        var cpuUsagePercent: Double
        var energyImpact: EnergyImpactLevel
        var animationFramerate: Double
        var uiResponseTime: Double
        var timerAccuracy: Double
        var backgroundTaskCount: Int
        var networkLatency: Double?
        
        var isWithinTargets: Bool {
            return memoryUsageMB < 50.0 && 
                   cpuUsagePercent < 1.0 && 
                   animationFramerate >= 58.0 &&
                   uiResponseTime < 100.0 &&
                   abs(timerAccuracy) < 2.0
        }
        
        var performanceGrade: PerformanceGrade {
            let score = calculatePerformanceScore()
            switch score {
            case 90...100: return .excellent
            case 75...89: return .good
            case 60...74: return .acceptable
            case 40...59: return .poor
            default: return .critical
            }
        }
        
        private func calculatePerformanceScore() -> Double {
            var score = 100.0
            
            // Memory penalty
            if memoryUsageMB > 50.0 {
                score -= min(30.0, (memoryUsageMB - 50.0) * 2.0)
            }
            
            // CPU penalty
            if cpuUsagePercent > 1.0 {
                score -= min(25.0, (cpuUsagePercent - 1.0) * 5.0)
            }
            
            // Animation penalty
            if animationFramerate < 60.0 {
                score -= min(20.0, (60.0 - animationFramerate) * 2.0)
            }
            
            // Response time penalty
            if uiResponseTime > 100.0 {
                score -= min(15.0, (uiResponseTime - 100.0) * 0.1)
            }
            
            // Timer accuracy penalty
            if abs(timerAccuracy) > 2.0 {
                score -= min(10.0, abs(timerAccuracy) * 2.0)
            }
            
            return max(0.0, score)
        }
    }
    
    enum PerformanceGrade: String, CaseIterable {
        case excellent = "A+"
        case good = "A"
        case acceptable = "B"
        case poor = "C"
        case critical = "F"
        
        var color: NSColor {
            switch self {
            case .excellent: return .systemGreen
            case .good: return .systemBlue
            case .acceptable: return .systemYellow
            case .poor: return .systemOrange
            case .critical: return .systemRed
            }
        }
        
        var description: String {
            switch self {
            case .excellent: return "Excellent - All targets exceeded"
            case .good: return "Good - Meeting all performance targets"
            case .acceptable: return "Acceptable - Some minor optimizations needed"
            case .poor: return "Poor - Performance issues detected"
            case .critical: return "Critical - Immediate optimization required"
            }
        }
    }
    
    enum EnergyImpactLevel: String, Codable, CaseIterable {
        case minimal = "Minimal"
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case veryHigh = "Very High"
        
        var energyImpact: Double {
            switch self {
            case .minimal: return 0.1
            case .low: return 0.3
            case .medium: return 0.6
            case .high: return 0.8
            case .veryHigh: return 1.0
            }
        }
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var currentMetrics = DetailedMetrics(
        timestamp: Date(),
        memoryUsageMB: 0.0,
        cpuUsagePercent: 0.0,
        energyImpact: .low,
        animationFramerate: 60.0,
        uiResponseTime: 50.0,
        timerAccuracy: 0.0,
        backgroundTaskCount: 0,
        networkLatency: nil
    )
    
    @Published private(set) var performanceHistory: [DetailedMetrics] = []
    @Published private(set) var isProfilerActive = false
    @Published private(set) var lastAuditReport: PerformanceAuditReport?
    @Published private(set) var optimizationRecommendations: [OptimizationRecommendation] = []
    
    // MARK: - Private Properties
    
    private var profilingTimer: Timer?
    private var frameTimeMonitor: CADisplayLink?
    private var memoryMonitor = MemoryMonitor()
    private var cpuMonitor = CPUMonitor()
    private var batteryMonitor = BatteryMonitor()
    private var uiResponseMonitor = UIResponseTimeMonitor()
    
    private let logger = Logger(subsystem: "com.claudescheduler.app", category: "PerformanceProfiler")
    private let maxHistoryCount = 1000 // Keep last 1000 measurements
    private let profilingInterval: TimeInterval = 5.0 // Measure every 5 seconds
    
    // MARK: - Performance Audit Report
    
    struct PerformanceAuditReport: Codable {
        let auditDate: Date
        let durationMinutes: Double
        let samplesCollected: Int
        
        // Memory Analysis
        let memoryStats: MemoryStatistics
        
        // CPU Analysis
        let cpuStats: CPUStatistics
        
        // UI Performance Analysis
        let uiStats: UIPerformanceStatistics
        
        // Energy Analysis
        let energyStats: EnergyStatistics
        
        // Overall Assessment
        let overallGrade: PerformanceGrade
        let targetComplianceRate: Double
        let criticalIssues: [String]
        let recommendations: [String]
        
        struct MemoryStatistics: Codable {
            let averageUsageMB: Double
            let peakUsageMB: Double
            let minimumUsageMB: Double
            let leaksDetected: Int
            let targetCompliance: Bool
            let trend: TrendDirection
        }
        
        struct CPUStatistics: Codable {
            let averageUsagePercent: Double
            let peakUsagePercent: Double
            let idleUsagePercent: Double
            let targetCompliance: Bool
            let energyEfficiency: Double
            let trend: TrendDirection
        }
        
        struct UIPerformanceStatistics: Codable {
            let averageFramerate: Double
            let droppedFramesPercent: Double
            let averageResponseTimeMS: Double
            let slowInteractions: Int
            let animationEfficiency: Double
            let targetCompliance: Bool
        }
        
        struct EnergyStatistics: Codable {
            let averageImpactLevel: EnergyImpactLevel
            let batteryDrainRate: Double
            let thermalPressureEvents: Int
            let backgroundTaskEfficiency: Double
            let targetCompliance: Bool
        }
        
        enum TrendDirection: String, Codable {
            case improving = "Improving"
            case stable = "Stable"
            case degrading = "Degrading"
        }
    }
    
    // MARK: - Optimization Recommendations
    
    struct OptimizationRecommendation: Identifiable, Codable {
        let id = UUID()
        let priority: Priority
        let category: Category
        let title: String
        let description: String
        let implementation: String
        let expectedImpact: String
        let estimatedEffort: String
        
        enum Priority: String, Codable, CaseIterable {
            case critical = "Critical"
            case high = "High"
            case medium = "Medium"
            case low = "Low"
            
            var color: NSColor {
                switch self {
                case .critical: return .systemRed
                case .high: return .systemOrange
                case .medium: return .systemYellow
                case .low: return .systemBlue
                }
            }
        }
        
        enum Category: String, Codable, CaseIterable {
            case memory = "Memory"
            case cpu = "CPU"
            case ui = "UI/Animation"
            case energy = "Energy"
            case timer = "Timer Precision"
            case architecture = "Architecture"
        }
    }
    
    // MARK: - Initialization
    
    init() {
        logger.info("Performance Profiler initialized")
    }
    
    deinit {
        stopProfiling()
    }
    
    // MARK: - Public API
    
    /// Start continuous performance profiling
    func startProfiling() {
        guard !isProfilerActive else { return }
        
        isProfilerActive = true
        
        // Start profiling timer
        profilingTimer = Timer.scheduledTimer(withTimeInterval: profilingInterval, repeats: true) { [weak self] _ in
            self?.collectMetrics()
        }
        
        // Start frame rate monitoring
        startFrameRateMonitoring()
        
        logger.info("Performance profiling started")
        print("📊 Performance profiling started")
    }
    
    /// Stop performance profiling
    func stopProfiling() {
        guard isProfilerActive else { return }
        
        isProfilerActive = false
        profilingTimer?.invalidate()
        profilingTimer = nil
        
        frameTimeMonitor?.invalidate()
        frameTimeMonitor = nil
        
        logger.info("Performance profiling stopped")
        print("📊 Performance profiling stopped")
    }
    
    /// Generate comprehensive performance audit report
    func generateAuditReport() -> PerformanceAuditReport {
        let endDate = Date()
        let startDate = performanceHistory.first?.timestamp ?? endDate
        let duration = endDate.timeIntervalSince(startDate) / 60.0 // In minutes
        
        guard !performanceHistory.isEmpty else {
            logger.warning("No performance data available for audit")
            return createEmptyAuditReport()
        }
        
        let memoryStats = analyzeMemoryPerformance()
        let cpuStats = analyzeCPUPerformance()
        let uiStats = analyzeUIPerformance()
        let energyStats = analyzeEnergyPerformance()
        
        let overallGrade = calculateOverallGrade(memoryStats, cpuStats, uiStats, energyStats)
        let targetComplianceRate = calculateTargetCompliance()
        let criticalIssues = identifyCriticalIssues()
        let recommendations = generateRecommendations()
        
        let report = PerformanceAuditReport(
            auditDate: endDate,
            durationMinutes: duration,
            samplesCollected: performanceHistory.count,
            memoryStats: memoryStats,
            cpuStats: cpuStats,
            uiStats: uiStats,
            energyStats: energyStats,
            overallGrade: overallGrade,
            targetComplianceRate: targetComplianceRate,
            criticalIssues: criticalIssues,
            recommendations: recommendations
        )
        
        lastAuditReport = report
        logger.info("Performance audit report generated with grade: \\(overallGrade.rawValue)")
        
        return report
    }
    
    /// Run stress test for specified duration
    func runStressTest(durationMinutes: Int) async -> PerformanceAuditReport {
        logger.info("Starting stress test for \\(durationMinutes) minutes")
        
        // Clear existing data
        performanceHistory.removeAll()
        
        // Start intensive profiling
        let stressInterval: TimeInterval = 1.0 // Sample every second during stress test
        let originalInterval = profilingInterval
        
        startProfiling()
        
        // Simulate high-load scenarios
        await simulateHighLoadScenarios(duration: TimeInterval(durationMinutes * 60))
        
        stopProfiling()
        
        let report = generateAuditReport()
        logger.info("Stress test completed with grade: \\(report.overallGrade.rawValue)")
        
        return report
    }
    
    /// Export performance data for external analysis
    func exportPerformanceData() -> Data? {
        let exportData = PerformanceExportData(
            exportDate: Date(),
            metrics: performanceHistory,
            auditReport: lastAuditReport,
            recommendations: optimizationRecommendations
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    // MARK: - Private Methods
    
    private func collectMetrics() {
        let memoryUsage = memoryMonitor.getCurrentUsage()
        let cpuUsage = cpuMonitor.getCurrentUsage()
        let energyImpact = batteryMonitor.getBatteryImpact()
        let responseTime = uiResponseMonitor.getAverageResponseTime()
        
        let metrics = DetailedMetrics(
            timestamp: Date(),
            memoryUsageMB: memoryUsage,
            cpuUsagePercent: cpuUsage,
            energyImpact: energyImpact,
            animationFramerate: currentMetrics.animationFramerate,
            uiResponseTime: responseTime,
            timerAccuracy: 0.0, // Will be updated by SchedulerEngine
            backgroundTaskCount: getActiveBackgroundTaskCount(),
            networkLatency: measureNetworkLatency()
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.currentMetrics = metrics
            self?.performanceHistory.append(metrics)
            
            // Trim history if needed
            if let history = self?.performanceHistory, history.count > self?.maxHistoryCount ?? 1000 {
                self?.performanceHistory.removeFirst()
            }
            
            // Update recommendations if metrics are concerning
            if !metrics.isWithinTargets {
                self?.updateOptimizationRecommendations(based: metrics)
            }
        }
        
        logger.debug("Metrics collected: Memory=\\(String(format: \"%.1f\", memoryUsage))MB, CPU=\\(String(format: \"%.1f\", cpuUsage))%")
    }
    
    private func startFrameRateMonitoring() {
        frameTimeMonitor = CADisplayLink(target: self, selector: #selector(updateFrameRate))
        frameTimeMonitor?.add(to: .main, forMode: .default)
    }
    
    @objc private func updateFrameRate() {
        guard let displayLink = frameTimeMonitor else { return }
        
        let framerate = 1.0 / displayLink.targetTimestamp
        
        DispatchQueue.main.async { [weak self] in
            self?.currentMetrics.animationFramerate = framerate
        }
    }
    
    // MARK: - Analysis Methods
    
    private func analyzeMemoryPerformance() -> PerformanceAuditReport.MemoryStatistics {
        let memoryValues = performanceHistory.map { $0.memoryUsageMB }
        
        return PerformanceAuditReport.MemoryStatistics(
            averageUsageMB: memoryValues.average(),
            peakUsageMB: memoryValues.max() ?? 0.0,
            minimumUsageMB: memoryValues.min() ?? 0.0,
            leaksDetected: 0, // TODO: Implement leak detection
            targetCompliance: memoryValues.allSatisfy { $0 < 50.0 },
            trend: calculateTrend(for: memoryValues)
        )
    }
    
    private func analyzeCPUPerformance() -> PerformanceAuditReport.CPUStatistics {
        let cpuValues = performanceHistory.map { $0.cpuUsagePercent }
        
        return PerformanceAuditReport.CPUStatistics(
            averageUsagePercent: cpuValues.average(),
            peakUsagePercent: cpuValues.max() ?? 0.0,
            idleUsagePercent: cpuValues.filter { $0 < 0.5 }.average(),
            targetCompliance: cpuValues.allSatisfy { $0 < 1.0 },
            energyEfficiency: calculateEnergyEfficiency(),
            trend: calculateTrend(for: cpuValues)
        )
    }
    
    private func analyzeUIPerformance() -> PerformanceAuditReport.UIPerformanceStatistics {
        let framerateValues = performanceHistory.map { $0.animationFramerate }
        let responseTimeValues = performanceHistory.map { $0.uiResponseTime }
        
        return PerformanceAuditReport.UIPerformanceStatistics(
            averageFramerate: framerateValues.average(),
            droppedFramesPercent: Double(framerateValues.filter { $0 < 58.0 }.count) / Double(framerateValues.count) * 100.0,
            averageResponseTimeMS: responseTimeValues.average(),
            slowInteractions: responseTimeValues.filter { $0 > 100.0 }.count,
            animationEfficiency: calculateAnimationEfficiency(),
            targetCompliance: framerateValues.allSatisfy { $0 >= 58.0 } && responseTimeValues.allSatisfy { $0 < 100.0 }
        )
    }
    
    private func analyzeEnergyPerformance() -> PerformanceAuditReport.EnergyStatistics {
        let energyValues = performanceHistory.map { $0.energyImpact.energyImpact }
        
        return PerformanceAuditReport.EnergyStatistics(
            averageImpactLevel: calculateAverageEnergyImpact(),
            batteryDrainRate: energyValues.average(),
            thermalPressureEvents: 0, // TODO: Implement thermal monitoring
            backgroundTaskEfficiency: calculateBackgroundTaskEfficiency(),
            targetCompliance: energyValues.allSatisfy { $0 <= 0.3 } // Low energy impact
        )
    }
    
    // MARK: - Utility Methods
    
    private func calculateOverallGrade(
        _ memory: PerformanceAuditReport.MemoryStatistics,
        _ cpu: PerformanceAuditReport.CPUStatistics,
        _ ui: PerformanceAuditReport.UIPerformanceStatistics,
        _ energy: PerformanceAuditReport.EnergyStatistics
    ) -> PerformanceGrade {
        var score = 100.0
        
        if !memory.targetCompliance { score -= 25.0 }
        if !cpu.targetCompliance { score -= 25.0 }
        if !ui.targetCompliance { score -= 25.0 }
        if !energy.targetCompliance { score -= 25.0 }
        
        switch score {
        case 90...100: return .excellent
        case 75...89: return .good
        case 60...74: return .acceptable
        case 40...59: return .poor
        default: return .critical
        }
    }
    
    private func calculateTargetCompliance() -> Double {
        let compliantCount = performanceHistory.filter { $0.isWithinTargets }.count
        return Double(compliantCount) / Double(performanceHistory.count) * 100.0
    }
    
    private func identifyCriticalIssues() -> [String] {
        var issues: [String] = []
        
        let avgMemory = performanceHistory.map { $0.memoryUsageMB }.average()
        let avgCPU = performanceHistory.map { $0.cpuUsagePercent }.average()
        let avgFramerate = performanceHistory.map { $0.animationFramerate }.average()
        let avgResponseTime = performanceHistory.map { $0.uiResponseTime }.average()
        
        if avgMemory > 50.0 {
            issues.append("Memory usage exceeds 50MB target (\\(String(format: \"%.1f\", avgMemory))MB)")
        }
        
        if avgCPU > 1.0 {
            issues.append("CPU usage exceeds 1% target (\\(String(format: \"%.1f\", avgCPU))%)")
        }
        
        if avgFramerate < 58.0 {
            issues.append("Animation framerate below 58fps target (\\(String(format: \"%.1f\", avgFramerate))fps)")
        }
        
        if avgResponseTime > 100.0 {
            issues.append("UI response time exceeds 100ms target (\\(String(format: \"%.1f\", avgResponseTime))ms)")
        }
        
        return issues
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let avgMemory = performanceHistory.map { $0.memoryUsageMB }.average()
        let avgCPU = performanceHistory.map { $0.cpuUsagePercent }.average()
        
        if avgMemory > 40.0 {
            recommendations.append("Implement memory pooling for frequently allocated objects")
            recommendations.append("Review and optimize Combine subscription lifecycle")
            recommendations.append("Consider lazy loading for non-critical UI components")
        }
        
        if avgCPU > 0.8 {
            recommendations.append("Reduce timer frequency during idle periods")
            recommendations.append("Optimize background queue usage")
            recommendations.append("Implement CPU-aware task scheduling")
        }
        
        return recommendations
    }
    
    private func updateOptimizationRecommendations(based metrics: DetailedMetrics) {
        // Generate specific recommendations based on current metrics
        var newRecommendations: [OptimizationRecommendation] = []
        
        if metrics.memoryUsageMB > 50.0 {
            newRecommendations.append(OptimizationRecommendation(
                priority: .critical,
                category: .memory,
                title: "High Memory Usage Detected",
                description: "Memory usage (\\(String(format: \"%.1f\", metrics.memoryUsageMB))MB) exceeds 50MB target",
                implementation: "Review object lifecycle, implement memory pooling, optimize Combine subscriptions",
                expectedImpact: "30-50% memory reduction",
                estimatedEffort: "Medium (2-3 days)"
            ))
        }
        
        if metrics.cpuUsagePercent > 2.0 {
            newRecommendations.append(OptimizationRecommendation(
                priority: .high,
                category: .cpu,
                title: "High CPU Usage",
                description: "CPU usage (\\(String(format: \"%.1f\", metrics.cpuUsagePercent))%) exceeds targets",
                implementation: "Optimize timer intervals, reduce background processing",
                expectedImpact: "50-70% CPU reduction",
                estimatedEffort: "Low (1 day)"
            ))
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.optimizationRecommendations = newRecommendations
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateTrend(for values: [Double]) -> PerformanceAuditReport.TrendDirection {
        guard values.count > 1 else { return .stable }
        
        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))
        
        let firstAvg = firstHalf.average()
        let secondAvg = secondHalf.average()
        let changePercent = ((secondAvg - firstAvg) / firstAvg) * 100.0
        
        if changePercent > 5.0 {
            return .degrading
        } else if changePercent < -5.0 {
            return .improving
        } else {
            return .stable
        }
    }
    
    private func calculateEnergyEfficiency() -> Double {
        let energyValues = performanceHistory.map { $0.energyImpact.energyImpact }
        return 1.0 - energyValues.average() // Higher efficiency = lower energy impact
    }
    
    private func calculateAnimationEfficiency() -> Double {
        let framerateValues = performanceHistory.map { $0.animationFramerate }
        return framerateValues.average() / 60.0 // Perfect efficiency = 1.0 (60fps)
    }
    
    private func calculateAverageEnergyImpact() -> EnergyImpactLevel {
        let avgImpact = performanceHistory.map { $0.energyImpact.energyImpact }.average()
        
        switch avgImpact {
        case 0.0..<0.2: return .minimal
        case 0.2..<0.4: return .low
        case 0.4..<0.7: return .medium
        case 0.7..<0.9: return .high
        default: return .veryHigh
        }
    }
    
    private func calculateBackgroundTaskEfficiency() -> Double {
        // Simplified calculation - in practice, this would measure actual background task performance
        return 0.85 // 85% efficiency placeholder
    }
    
    private func getActiveBackgroundTaskCount() -> Int {
        // TODO: Implement actual background task counting
        return 0
    }
    
    private func measureNetworkLatency() -> Double? {
        // TODO: Implement network latency measurement for Claude CLI calls
        return nil
    }
    
    private func createEmptyAuditReport() -> PerformanceAuditReport {
        return PerformanceAuditReport(
            auditDate: Date(),
            durationMinutes: 0,
            samplesCollected: 0,
            memoryStats: PerformanceAuditReport.MemoryStatistics(
                averageUsageMB: 0, peakUsageMB: 0, minimumUsageMB: 0,
                leaksDetected: 0, targetCompliance: false, trend: .stable
            ),
            cpuStats: PerformanceAuditReport.CPUStatistics(
                averageUsagePercent: 0, peakUsagePercent: 0, idleUsagePercent: 0,
                targetCompliance: false, energyEfficiency: 0, trend: .stable
            ),
            uiStats: PerformanceAuditReport.UIPerformanceStatistics(
                averageFramerate: 0, droppedFramesPercent: 0, averageResponseTimeMS: 0,
                slowInteractions: 0, animationEfficiency: 0, targetCompliance: false
            ),
            energyStats: PerformanceAuditReport.EnergyStatistics(
                averageImpactLevel: .low, batteryDrainRate: 0, thermalPressureEvents: 0,
                backgroundTaskEfficiency: 0, targetCompliance: false
            ),
            overallGrade: .critical,
            targetComplianceRate: 0,
            criticalIssues: ["No data available"],
            recommendations: ["Collect performance data first"]
        )
    }
    
    private func simulateHighLoadScenarios(duration: TimeInterval) async {
        // TODO: Implement stress test scenarios
        // - High frequency timer updates
        // - Memory allocation stress
        // - CPU intensive operations
        // - UI animation stress test
        await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }
}

// MARK: - Supporting Classes

/// UI Response Time Monitor
class UIResponseTimeMonitor {
    private var responseTimes: [Double] = []
    private let maxSamples = 100
    
    func recordResponseTime(_ time: Double) {
        responseTimes.append(time)
        if responseTimes.count > maxSamples {
            responseTimes.removeFirst()
        }
    }
    
    func getAverageResponseTime() -> Double {
        return responseTimes.isEmpty ? 50.0 : responseTimes.average()
    }
}

/// Performance Export Data Structure
struct PerformanceExportData: Codable {
    let exportDate: Date
    let metrics: [PerformanceProfiler.DetailedMetrics]
    let auditReport: PerformanceProfiler.PerformanceAuditReport?
    let recommendations: [PerformanceProfiler.OptimizationRecommendation]
}

// MARK: - Array Extensions

extension Array where Element == Double {
    func average() -> Double {
        return isEmpty ? 0.0 : reduce(0, +) / Double(count)
    }
}