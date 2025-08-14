import Foundation
import ServiceManagement
import Cocoa

/// Service responsible for managing launch at login functionality
/// Provides secure auto-start implementation with proper system integration
class LaunchAtLoginService: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var isAvailable: Bool = true
    @Published private(set) var lastError: LaunchError?
    
    // Bundle identifier for the login helper
    private let loginHelperBundleIdentifier: String
    
    // MARK: - Types
    
    enum LaunchError: LocalizedError {
        case serviceUnavailable
        case authorizationDenied
        case helperNotFound
        case systemError(Error)
        
        var errorDescription: String? {
            switch self {
            case .serviceUnavailable:
                return "Launch at login service is not available"
            case .authorizationDenied:
                return "Authorization denied for launch at login"
            case .helperNotFound:
                return "Login helper not found in application bundle"
            case .systemError(let error):
                return "System error: \(error.localizedDescription)"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .serviceUnavailable:
                return "This feature requires macOS 13.0 or later"
            case .authorizationDenied:
                return "Check system preferences and security settings"
            case .helperNotFound:
                return "Reinstall the application to restore login helper"
            case .systemError:
                return "Try restarting your Mac or contact support"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Set up bundle identifier for login helper
        let mainBundleId = Bundle.main.bundleIdentifier ?? "com.anthropic.claudescheduler"
        self.loginHelperBundleIdentifier = "\(mainBundleId).loginhelper"
        
        // Check initial status
        updateStatus()
        
        print("🚀 LaunchAtLoginService initialized with helper ID: \(loginHelperBundleIdentifier)")
    }
    
    // MARK: - Public API
    
    /// Enables or disables launch at login
    /// - Parameter enabled: Whether to enable launch at login
    /// - Returns: Success status
    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool {
        guard isAvailable else {
            lastError = .serviceUnavailable
            return false
        }
        
        do {
            if #available(macOS 13.0, *) {
                // Use modern Service Management API
                try await setEnabledModern(enabled)
            } else {
                // Use legacy Service Management API
                try setEnabledLegacy(enabled)
            }
            
            // Update status and clear errors
            await MainActor.run {
                self.isEnabled = enabled
                self.lastError = nil
            }
            
            print("✅ Launch at login \(enabled ? "enabled" : "disabled") successfully")
            return true
            
        } catch {
            await MainActor.run {
                self.lastError = .systemError(error)
            }
            print("❌ Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            return false
        }
    }
    
    /// Refreshes the current launch at login status
    func updateStatus() {
        if #available(macOS 13.0, *) {
            updateStatusModern()
        } else {
            updateStatusLegacy()
        }
    }
    
    /// Checks if launch at login is supported on this system
    var isSupported: Bool {
        if #available(macOS 13.0, *) {
            return true
        } else {
            // Check if legacy service management is available
            return Bundle.main.bundleIdentifier != nil
        }
    }
    
    // MARK: - Modern API (macOS 13.0+)
    
    @available(macOS 13.0, *)
    private func setEnabledModern(_ enabled: Bool) async throws {
        if enabled {
            // Register login item
            try await SMAppService.mainApp.register()
        } else {
            // Unregister login item
            try await SMAppService.mainApp.unregister()
        }
    }
    
    @available(macOS 13.0, *)
    private func updateStatusModern() {
        isEnabled = SMAppService.mainApp.status == .enabled
        isAvailable = true
    }
    
    // MARK: - Legacy API (macOS 12.x and earlier)
    
    private func setEnabledLegacy(_ enabled: Bool) throws {
        if enabled {
            // Enable launch at login using legacy API
            if !SMLoginItemSetEnabled(loginHelperBundleIdentifier as CFString, enabled) {
                throw LaunchError.authorizationDenied
            }
        } else {
            // Disable launch at login
            if !SMLoginItemSetEnabled(loginHelperBundleIdentifier as CFString, enabled) {
                throw LaunchError.authorizationDenied
            }
        }
    }
    
    private func updateStatusLegacy() {
        // Check current status using legacy API
        isEnabled = isLoginItemEnabled()
        isAvailable = true
    }
    
    /// Checks if the login item is currently enabled (legacy)
    private func isLoginItemEnabled() -> Bool {
        guard let jobDicts = SMCopyAllJobDictionaries(kSMDomainUserLaunchd)?.takeRetainedValue() as? [[String: Any]] else {
            return false
        }
        
        return jobDicts.contains { dict in
            if let label = dict["Label"] as? String {
                return label == loginHelperBundleIdentifier
            }
            return false
        }
    }
    
    // MARK: - Helper App Management
    
    /// Creates or updates the login helper application
    func createLoginHelper() -> Bool {
        guard let mainBundle = Bundle.main,
              let helperPath = mainBundle.bundlePath.appending("/Contents/Library/LoginItems") else {
            lastError = .helperNotFound
            return false
        }
        
        do {
            // Create login helper directory if needed
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: helperPath) {
                try fileManager.createDirectory(atPath: helperPath, 
                                                withIntermediateDirectories: true, 
                                                attributes: nil)
            }
            
            // Copy main app as login helper (simplified approach)
            let helperAppPath = helperPath.appending("/ClaudeScheduler Login Helper.app")
            
            if fileManager.fileExists(atPath: helperAppPath) {
                try fileManager.removeItem(atPath: helperAppPath)
            }
            
            // Create minimal login helper bundle
            try createMinimalLoginHelper(at: helperAppPath)
            
            print("✅ Login helper created at: \(helperAppPath)")
            return true
            
        } catch {
            lastError = .systemError(error)
            print("❌ Failed to create login helper: \(error)")
            return false
        }
    }
    
    /// Creates a minimal login helper application
    private func createMinimalLoginHelper(at path: String) throws {
        let fileManager = FileManager.default
        
        // Create app bundle structure
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(atPath: path.appending("/Contents"), withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(atPath: path.appending("/Contents/MacOS"), withIntermediateDirectories: true, attributes: nil)
        
        // Create Info.plist
        let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleDisplayName</key>
            <string>ClaudeScheduler Login Helper</string>
            <key>CFBundleExecutable</key>
            <string>ClaudeScheduler Login Helper</string>
            <key>CFBundleIdentifier</key>
            <string>\(loginHelperBundleIdentifier)</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundleName</key>
            <string>ClaudeScheduler Login Helper</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0.0</string>
            <key>CFBundleVersion</key>
            <string>1</string>
            <key>LSBackgroundOnly</key>
            <true/>
            <key>LSMinimumSystemVersion</key>
            <string>12.0</string>
            <key>NSMainNibFile</key>
            <string>MainMenu</string>
            <key>NSPrincipalClass</key>
            <string>NSApplication</string>
            <key>SMAuthorizedClients</key>
            <array>
                <string>\(Bundle.main.bundleIdentifier ?? "com.anthropic.claudescheduler")</string>
            </array>
        </dict>
        </plist>
        """
        
        let infoPlistPath = path.appending("/Contents/Info.plist")
        try infoPlist.write(toFile: infoPlistPath, atomically: true, encoding: .utf8)
        
        // Create executable (simple shell script that launches main app)
        let executableScript = """
        #!/bin/bash
        # ClaudeScheduler Login Helper
        # Launches the main ClaudeScheduler application
        
        MAIN_APP_PATH="/Applications/ClaudeScheduler.app"
        
        if [ -d "$MAIN_APP_PATH" ]; then
            open "$MAIN_APP_PATH"
        else
            # Try to find app in common locations
            for path in "/Applications/ClaudeScheduler.app" "~/Applications/ClaudeScheduler.app"; do
                if [ -d "$path" ]; then
                    open "$path"
                    exit 0
                fi
            done
            
            # Show error if app not found
            osascript -e 'display notification "ClaudeScheduler not found in Applications folder" with title "ClaudeScheduler Login Helper"'
        fi
        """
        
        let executablePath = path.appending("/Contents/MacOS/ClaudeScheduler Login Helper")
        try executableScript.write(toFile: executablePath, atomically: true, encoding: .utf8)
        
        // Make executable
        let attributes = [FileAttributeKey.posixPermissions: 0o755]
        try fileManager.setAttributes(attributes, ofItemAtPath: executablePath)
    }
    
    // MARK: - System Integration
    
    /// Removes launch at login completely (for uninstall)
    func removeCompletely() async -> Bool {
        // Disable first
        let disabled = await setEnabled(false)
        
        // Remove helper app
        guard let mainBundle = Bundle.main else { return disabled }
        
        let helperPath = mainBundle.bundlePath.appending("/Contents/Library/LoginItems")
        let helperAppPath = helperPath.appending("/ClaudeScheduler Login Helper.app")
        
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: helperAppPath) {
                try fileManager.removeItem(atPath: helperAppPath)
                print("✅ Login helper removed")
            }
            return true
        } catch {
            print("⚠️ Failed to remove login helper: \(error)")
            return disabled
        }
    }
    
    /// Validates launch at login setup
    func validateSetup() -> ValidationResult {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Check system compatibility
        if !isSupported {
            issues.append("Launch at login not supported on this macOS version")
        }
        
        // Check bundle identifier
        if Bundle.main.bundleIdentifier == nil {
            issues.append("Application bundle identifier not found")
        }
        
        // Check if running from Applications folder (recommended)
        if let bundlePath = Bundle.main.bundlePath,
           !bundlePath.hasPrefix("/Applications/") && !bundlePath.hasPrefix("/Users/") {
            warnings.append("App should be installed in Applications folder for reliable launch at login")
        }
        
        // Check permissions
        if isEnabled && !isLoginItemEnabled() {
            warnings.append("Launch at login enabled but not detected by system")
        }
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings
        )
    }
    
    struct ValidationResult {
        let isValid: Bool
        let issues: [String]
        let warnings: [String]
        
        var hasWarnings: Bool { !warnings.isEmpty }
        var summary: String {
            if !isValid {
                return "Setup has \(issues.count) issue(s)"
            } else if hasWarnings {
                return "Setup valid with \(warnings.count) warning(s)"
            } else {
                return "Setup is valid"
            }
        }
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

extension LaunchAtLoginService {
    
    /// SwiftUI View for launch at login settings
    struct SettingsView: View {
        @ObservedObject var service: LaunchAtLoginService
        @State private var isToggling = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Toggle("Launch at login", isOn: .init(
                        get: { service.isEnabled },
                        set: { newValue in
                            isToggling = true
                            Task {
                                await service.setEnabled(newValue)
                                await MainActor.run {
                                    isToggling = false
                                }
                            }
                        }
                    ))
                    .disabled(!service.isAvailable || isToggling)
                    
                    if isToggling {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 16, height: 16)
                    }
                }
                
                Text("Automatically start ClaudeScheduler when you log in")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Show error if any
                if let error = service.lastError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            if let suggestion = error.recoverySuggestion {
                                Text(suggestion)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Show validation warnings
                let validation = service.validateSetup()
                if validation.hasWarnings {
                    ForEach(validation.warnings, id: \.self) { warning in
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            
                            Text(warning)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
    }
}