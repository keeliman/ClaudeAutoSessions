import XCTest
import Combine
@testable import ClaudeScheduler

/// Comprehensive unit tests for the high-precision SchedulerEngine
/// Tests timing accuracy, state transitions, recovery, and performance
final class SchedulerEngineTests: XCTestCase {
    
    var schedulerEngine: SchedulerEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        schedulerEngine = SchedulerEngine()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        schedulerEngine?.cleanup()
        schedulerEngine = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testInitialState() {
        XCTAssertEqual(schedulerEngine.currentState, .idle)
        XCTAssertNil(schedulerEngine.currentSession)
        XCTAssertEqual(schedulerEngine.progress, 0.0)
        XCTAssertEqual(schedulerEngine.progressPercentage, 0.0)
        XCTAssertEqual(schedulerEngine.timeRemaining, 0.0)
    }
    
    func testSessionStart() {
        let expectation = XCTestExpectation(description: "Session starts")
        
        schedulerEngine.$currentState
            .sink { state in
                if state == .running {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        schedulerEngine.startSession()
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertEqual(schedulerEngine.currentState, .running)
        XCTAssertNotNil(schedulerEngine.currentSession)
        XCTAssertEqual(schedulerEngine.currentSession?.plannedDuration, 18000.0) // 5 hours
    }
    
    func testSessionPause() {
        schedulerEngine.startSession()
        XCTAssertEqual(schedulerEngine.currentState, .running)
        
        schedulerEngine.pauseSession()
        XCTAssertEqual(schedulerEngine.currentState, .paused)
    }
    
    func testSessionResume() {
        schedulerEngine.startSession()
        schedulerEngine.pauseSession()
        XCTAssertEqual(schedulerEngine.currentState, .paused)
        
        schedulerEngine.resumeSession()
        XCTAssertEqual(schedulerEngine.currentState, .running)
    }
    
    func testSessionStop() {
        schedulerEngine.startSession()
        XCTAssertEqual(schedulerEngine.currentState, .running)
        
        schedulerEngine.stopSession()
        XCTAssertEqual(schedulerEngine.currentState, .idle)
        XCTAssertEqual(schedulerEngine.progress, 0.0)
        XCTAssertEqual(schedulerEngine.timeRemaining, 0.0)
    }
    
    func testSessionReset() {
        schedulerEngine.startSession()
        schedulerEngine.resetSession()
        
        XCTAssertEqual(schedulerEngine.currentState, .idle)
        XCTAssertNil(schedulerEngine.currentSession)
        XCTAssertEqual(schedulerEngine.progress, 0.0)
        XCTAssertEqual(schedulerEngine.progressPercentage, 0.0)
    }
    
    // MARK: - State Transition Tests
    
    func testStateTransitionValidation() {
        // Test invalid transitions
        XCTAssertFalse(schedulerEngine.currentState.canPause)
        XCTAssertFalse(schedulerEngine.currentState.canResume)
        XCTAssertFalse(schedulerEngine.currentState.canStop)
        XCTAssertTrue(schedulerEngine.currentState.canStartSession)
        
        schedulerEngine.startSession()
        XCTAssertTrue(schedulerEngine.currentState.canPause)
        XCTAssertFalse(schedulerEngine.currentState.canResume)
        XCTAssertTrue(schedulerEngine.currentState.canStop)
        XCTAssertFalse(schedulerEngine.currentState.canStartSession)
        
        schedulerEngine.pauseSession()
        XCTAssertFalse(schedulerEngine.currentState.canPause)
        XCTAssertTrue(schedulerEngine.currentState.canResume)
        XCTAssertTrue(schedulerEngine.currentState.canStop)
        XCTAssertFalse(schedulerEngine.currentState.canStartSession)
    }
    
    func testMultipleStartSessionCalls() {
        schedulerEngine.startSession()
        let firstSessionId = schedulerEngine.currentSession?.id
        
        // Should not start a new session if already running
        schedulerEngine.startSession()
        let secondSessionId = schedulerEngine.currentSession?.id
        
        XCTAssertEqual(firstSessionId, secondSessionId)
        XCTAssertEqual(schedulerEngine.currentState, .running)
    }
    
    // MARK: - Timing Accuracy Tests
    
    func testHighPrecisionTiming() {
        let expectation = XCTestExpectation(description: "High precision timing")
        
        schedulerEngine.startSession()
        
        // Wait a short time to check timing accuracy
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Should maintain high precision after 1 second
            XCTAssertEqual(self.schedulerEngine.timingAccuracy, .highPrecision)
            XCTAssertTrue(self.schedulerEngine.isHighPrecision)
            XCTAssertLessThan(abs(self.schedulerEngine.currentDriftSeconds), 2.0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testProgressCalculation() {
        schedulerEngine.startSession()
        
        // Progress should start at 0
        XCTAssertEqual(schedulerEngine.progress, 0.0, accuracy: 0.001)
        XCTAssertEqual(schedulerEngine.progressPercentage, 0.0, accuracy: 0.001)
        
        // Time remaining should equal planned duration initially
        XCTAssertEqual(schedulerEngine.timeRemaining, 18000.0, accuracy: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceMetrics() {
        schedulerEngine.startSession()
        
        // Performance metrics should be initialized
        XCTAssertGreaterThanOrEqual(schedulerEngine.currentMemoryUsageMB, 0)
        XCTAssertGreaterThanOrEqual(schedulerEngine.currentCPUUsagePercent, 0)
        
        // Should be within target ranges initially
        XCTAssertLessThan(schedulerEngine.currentMemoryUsageMB, 50.0)
        XCTAssertLessThan(schedulerEngine.currentCPUUsagePercent, 5.0)
    }
    
    func testBatteryOptimization() {
        let batteryDescription = schedulerEngine.batteryImpactDescription
        XCTAssertFalse(batteryDescription.isEmpty)
        
        // Battery impact should be low by default
        XCTAssertTrue(["Minimal", "Low"].contains(batteryDescription))
    }
    
    // MARK: - Recovery Tests
    
    func testRecoveryAttempts() {
        schedulerEngine.startSession()
        
        // Initially no recovery attempts
        XCTAssertEqual(schedulerEngine.recoveryAttemptsCount, 0)
        
        // Simulate error condition that triggers recovery
        let error = SchedulerError.timingPrecisionLost(drift: 5.0)
        schedulerEngine.lastError = error
        
        // Recovery attempts should be tracked
        // Note: This is a simplified test - full recovery testing would require more complex setup
    }
    
    // MARK: - Settings Tests
    
    func testSettingsUpdate() {
        var newSettings = SchedulerSettings()
        newSettings.sessionDuration = 3600.0 // 1 hour
        newSettings.updateInterval = 2.0
        newSettings.autoRestart = true
        
        schedulerEngine.updateSettings(newSettings)
        
        XCTAssertEqual(schedulerEngine.settings.sessionDuration, 3600.0)
        XCTAssertEqual(schedulerEngine.settings.updateInterval, 2.0)
        XCTAssertTrue(schedulerEngine.settings.autoRestart)
    }
    
    func testInvalidSettings() {
        var invalidSettings = SchedulerSettings()
        invalidSettings.sessionDuration = -100 // Invalid
        invalidSettings.claudeCommand = "" // Invalid
        
        XCTAssertFalse(invalidSettings.isValid)
        
        // Should not update with invalid settings
        let originalSettings = schedulerEngine.settings
        schedulerEngine.updateSettings(invalidSettings)
        
        XCTAssertEqual(schedulerEngine.settings.sessionDuration, originalSettings.sessionDuration)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testSystemSleepHandling() {
        schedulerEngine.startSession()
        XCTAssertEqual(schedulerEngine.currentState, .running)
        
        // Simulate system sleep
        NotificationCenter.default.post(name: NSWorkspace.willSleepNotification, object: nil)
        
        // Should pause automatically
        XCTAssertEqual(schedulerEngine.currentState, .paused)
        
        // Simulate system wake
        NotificationCenter.default.post(name: NSWorkspace.didWakeNotification, object: nil)
        
        // Should resume automatically
        XCTAssertEqual(schedulerEngine.currentState, .running)
    }
    
    func testMemoryPressureHandling() {
        schedulerEngine.startSession()
        
        // Simulate memory pressure
        NotificationCenter.default.post(name: NSApplication.didReceiveMemoryWarningNotification, object: nil)
        
        // Should handle gracefully without crashing
        XCTAssertEqual(schedulerEngine.currentState, .running)
        // Error might be set but session should continue
    }
    
    // MARK: - Persistence Tests
    
    func testSessionPersistence() {
        schedulerEngine.startSession()
        
        let sessionId = schedulerEngine.currentSession?.id
        XCTAssertNotNil(sessionId)
        
        // Persistence should work without errors
        // Note: UserDefaults persistence testing would require more setup
    }
    
    // MARK: - Protocol Conformance Tests
    
    func testSchedulerEngineProtocolConformance() {
        // Test that all protocol methods are implemented
        XCTAssertNoThrow(schedulerEngine.startSession())
        XCTAssertNoThrow(schedulerEngine.pauseSession())
        XCTAssertNoThrow(schedulerEngine.resumeSession())
        XCTAssertNoThrow(schedulerEngine.stopSession())
        XCTAssertNoThrow(schedulerEngine.resetSession())
        
        // Test that all protocol properties are accessible
        let _ = schedulerEngine.currentState
        let _ = schedulerEngine.timeRemaining
        let _ = schedulerEngine.progressPercentage
    }
    
    // MARK: - Performance Benchmarks
    
    func testTimerPrecisionBenchmark() {
        measure {
            schedulerEngine.startSession()
            
            // Let it run for a short time
            let expectation = XCTestExpectation(description: "Timer precision")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
            
            schedulerEngine.stopSession()
        }
    }
    
    func testMemoryUsageBenchmark() {
        measureMetrics([.memoryUsage], automaticallyStartMeasuring: false) {
            startMeasuring()
            
            schedulerEngine.startSession()
            
            // Let it run briefly to establish memory usage
            Thread.sleep(forTimeInterval: 0.1)
            
            stopMeasuring()
            
            schedulerEngine.stopSession()
        }
    }
    
    // MARK: - Integration Tests
    
    func testFullSessionLifecycle() {
        let expectation = XCTestExpectation(description: "Full session lifecycle")
        
        var stateChanges: [SchedulerState] = []
        
        schedulerEngine.$currentState
            .sink { state in
                stateChanges.append(state)
                
                // Complete test after we've seen key states
                if stateChanges.contains(.idle) && 
                   stateChanges.contains(.running) && 
                   stateChanges.contains(.paused) &&
                   stateChanges.count >= 4 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start session
        schedulerEngine.startSession()
        
        // Pause after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.schedulerEngine.pauseSession()
        }
        
        // Resume after another delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.schedulerEngine.resumeSession()
        }
        
        // Stop after final delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.schedulerEngine.stopSession()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify final state
        XCTAssertEqual(schedulerEngine.currentState, .idle)
        XCTAssertTrue(stateChanges.contains(.running))
        XCTAssertTrue(stateChanges.contains(.paused))
    }
}

// MARK: - Mock Classes for Testing

class MockProcessManager: ProcessManager {
    var shouldFailExecution = false
    var executionDelay: TimeInterval = 0
    
    override func executeClaude(command: String) async throws {
        if executionDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(executionDelay * 1_000_000_000))
        }
        
        if shouldFailExecution {
            throw ProcessError.executionFailed(details: "Mock execution failure")
        }
    }
}

class MockNotificationManager: NotificationManager {
    var scheduledNotifications: [NotificationType] = []
    
    override func scheduleNotification(_ type: NotificationType) {
        scheduledNotifications.append(type)
    }
}