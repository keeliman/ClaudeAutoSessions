import SwiftUI
import Foundation

/// Comprehensive About panel with version info, credits, and system information
struct AboutPanelView: View {
    @State private var showSystemInfo = false
    @State private var showCredits = false
    @State private var showLicenses = false
    @State private var systemInfo: SystemInfo?
    
    var body: some View {
        VStack(spacing: 20) {
            // App header
            appHeader
            
            // Version and build info
            versionInfo
            
            // Action buttons
            actionButtons
            
            // Additional info sections
            if showSystemInfo {
                systemInfoSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            if showCredits {
                creditsSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            if showLicenses {
                licensesSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Spacer()
            
            // Footer with links
            footerLinks
        }
        .padding(24)
        .frame(width: 480, height: showSystemInfo || showCredits || showLicenses ? 640 : 420)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            loadSystemInfo()
        }
    }
    
    // MARK: - Header Section
    
    private var appHeader: some View {
        VStack(spacing: 12) {
            // App icon
            AppIconView()
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            // App name
            Text("ClaudeScheduler")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // Tagline
            Text("Enterprise-Grade Productivity Scheduler")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Version Information
    
    private var versionInfo: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                InfoRow(title: "Version", value: AppVersion.displayVersion)
                InfoRow(title: "Build", value: AppVersion.buildNumber)
            }
            
            HStack(spacing: 16) {
                InfoRow(title: "Release", value: AppVersion.releaseType.displayName)
                InfoRow(title: "Architecture", value: AppVersion.architecture)
            }
            
            if AppVersion.isDebugBuild {
                Label("Debug Build", systemImage: "ladybug.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: { withAnimation { showSystemInfo.toggle() } }) {
                    Label("System Info", systemImage: "info.circle")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                
                Button(action: { withAnimation { showCredits.toggle() } }) {
                    Label("Credits", systemImage: "person.2")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
            }
            
            HStack(spacing: 12) {
                Button(action: { withAnimation { showLicenses.toggle() } }) {
                    Label("Licenses", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                
                Button(action: copyVersionInfo) {
                    Label("Copy Info", systemImage: "doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
            }
        }
    }
    
    // MARK: - System Information Section
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("System Information")
                .font(.headline)
                .padding(.bottom, 4)
            
            if let info = systemInfo {
                LazyVStack(alignment: .leading, spacing: 6) {
                    SystemInfoRow(title: "macOS Version", value: info.osVersion)
                    SystemInfoRow(title: "Device Model", value: info.deviceModel)
                    SystemInfoRow(title: "Processor", value: info.processorName)
                    SystemInfoRow(title: "Memory", value: info.memoryInfo)
                    SystemInfoRow(title: "Language", value: info.preferredLanguage)
                    SystemInfoRow(title: "Timezone", value: info.timeZone)
                    SystemInfoRow(title: "Uptime", value: info.systemUptime)
                }
            } else {
                ProgressView("Loading system information...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Credits Section
    
    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Credits & Acknowledgments")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                CreditItem(
                    title: "Development",
                    description: "Built with SwiftUI and Combine for native macOS performance",
                    icon: "swift"
                )
                
                CreditItem(
                    title: "Claude AI Integration",
                    description: "Powered by Anthropic's Claude AI assistant",
                    icon: "brain.head.profile"
                )
                
                CreditItem(
                    title: "Design Inspiration",
                    description: "Following Apple Human Interface Guidelines",
                    icon: "paintbrush"
                )
                
                CreditItem(
                    title: "Performance Engineering",
                    description: "Enterprise-grade reliability and optimization",
                    icon: "speedometer"
                )
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Licenses Section
    
    private var licensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Open Source Licenses")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    LicenseItem(
                        name: "SwiftUI",
                        license: "Apple Inc. - Xcode License",
                        description: "Native UI framework for macOS applications"
                    )
                    
                    LicenseItem(
                        name: "Foundation",
                        license: "Apple Inc. - Xcode License",
                        description: "Core system frameworks and utilities"
                    )
                    
                    LicenseItem(
                        name: "Combine",
                        license: "Apple Inc. - Xcode License",
                        description: "Reactive programming framework"
                    )
                    
                    LicenseItem(
                        name: "Service Management",
                        license: "Apple Inc. - macOS SDK",
                        description: "System service integration and launch agents"
                    )
                }
            }
            .frame(maxHeight: 120)
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Footer Links
    
    private var footerLinks: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                Link("GitHub Repository", destination: URL(string: "https://github.com/anthropic-ai/claude-cli")!)
                    .font(.subheadline)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Link("Report Issue", destination: URL(string: "https://github.com/anthropic-ai/claude-cli/issues")!)
                    .font(.subheadline)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Link("Support", destination: URL(string: "https://support.anthropic.com")!)
                    .font(.subheadline)
            }
            
            Text("© 2024 Anthropic. Built with Claude Code.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func loadSystemInfo() {
        Task {
            let info = await SystemInfo.current()
            await MainActor.run {
                self.systemInfo = info
            }
        }
    }
    
    private func copyVersionInfo() {
        let info = """
        ClaudeScheduler \(AppVersion.displayVersion) (\(AppVersion.buildNumber))
        Release: \(AppVersion.releaseType.displayName)
        Architecture: \(AppVersion.architecture)
        macOS: \(systemInfo?.osVersion ?? "Unknown")
        Device: \(systemInfo?.deviceModel ?? "Unknown")
        """
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(info, forType: .string)
        
        // Show brief confirmation
        print("✅ Version information copied to clipboard")
    }
}

// MARK: - Supporting Views

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBlue),
                    Color(.systemPurple)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(16)
            
            // Icon symbol
            Image(systemName: "clock.circle.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SystemInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

struct CreditItem: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct LicenseItem: View {
    let name: String
    let license: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(license)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - App Version Information

struct AppVersion {
    static let displayVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }()
    
    static let buildNumber: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }()
    
    static let bundleIdentifier: String = {
        Bundle.main.bundleIdentifier ?? "com.anthropic.claudescheduler"
    }()
    
    static let architecture: String = {
        #if arch(arm64)
        return "Apple Silicon"
        #elseif arch(x86_64)
        return "Intel"
        #else
        return "Unknown"
        #endif
    }()
    
    static let isDebugBuild: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    static let releaseType: ReleaseType = {
        if isDebugBuild {
            return .debug
        } else if displayVersion.contains("beta") {
            return .beta
        } else if displayVersion.contains("alpha") {
            return .alpha
        } else {
            return .release
        }
    }()
    
    enum ReleaseType {
        case alpha, beta, release, debug
        
        var displayName: String {
            switch self {
            case .alpha: return "Alpha"
            case .beta: return "Beta"
            case .release: return "Release"
            case .debug: return "Debug"
            }
        }
    }
}

// MARK: - System Information

struct SystemInfo {
    let osVersion: String
    let deviceModel: String
    let processorName: String
    let memoryInfo: String
    let preferredLanguage: String
    let timeZone: String
    let systemUptime: String
    
    static func current() async -> SystemInfo {
        let processInfo = ProcessInfo.processInfo
        
        // OS Version
        let osVersion = "\(processInfo.operatingSystemVersionString)"
        
        // Device model
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let deviceModel = String(cString: model)
        
        // Processor info
        var processorSize = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &processorSize, nil, 0)
        var processor = [CChar](repeating: 0, count: processorSize)
        sysctlbyname("machdep.cpu.brand_string", &processor, &processorSize, nil, 0)
        let processorName = String(cString: processor)
        
        // Memory info
        let physicalMemory = processInfo.physicalMemory
        let memoryGB = Double(physicalMemory) / (1024 * 1024 * 1024)
        let memoryInfo = String(format: "%.1f GB", memoryGB)
        
        // Language and locale
        let preferredLanguage = Locale.current.localizedString(forLanguageCode: Locale.preferredLanguages.first ?? "en") ?? "English"
        
        // Timezone
        let timeZone = TimeZone.current.localizedName(for: .standard, locale: Locale.current) ?? TimeZone.current.identifier
        
        // System uptime
        let uptime = processInfo.systemUptime
        let uptimeFormatted = formatUptime(uptime)
        
        return SystemInfo(
            osVersion: osVersion,
            deviceModel: deviceModel,
            processorName: processorName,
            memoryInfo: memoryInfo,
            preferredLanguage: preferredLanguage,
            timeZone: timeZone,
            systemUptime: uptimeFormatted
        )
    }
    
    private static func formatUptime(_ uptime: TimeInterval) -> String {
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("About Panel") {
    AboutPanelView()
        .background(Color(.windowBackgroundColor))
}
#endif