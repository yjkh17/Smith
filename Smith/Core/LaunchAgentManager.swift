//
//  LaunchAgentManager.swift
//  Smith - Background Launch Agent Management
//
//  Phase 3: Deep System Integration
//  Created by AI Assistant on 17/06/2025.
//

import Foundation
import ServiceManagement
import os.log
import Combine
import AppKit

/// Manages LaunchAgent installation and background operation
@MainActor
final class LaunchAgentManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published var isLaunchAgentInstalled = false
    @Published var backgroundMonitoringEnabled = false
    @Published var isEnabled = false
    @Published var backgroundIntensity: BackgroundIntensity = .medium
    @Published var lastLaunchAgentUpdate: Date?
    @Published var backgroundMonitoringStatus = "Not configured"
    @Published var isLoading = false
    
    private let logger = Logger(subsystem: "com.motherofbrand.Smith", category: "LaunchAgent")
    private let launchAgentIdentifier = "com.motherofbrand.Smith.BackgroundMonitor"
    private let appName = "Smith"
    
    // MARK: - Background Intensity Levels
    // The BackgroundIntensity enum is defined in BackgroundIntensity.swift

    // MARK: - Initialization
    
    init() {
        checkLaunchAgentStatus()
        loadUserPreferences()
    }
    
    // MARK: - Launch Agent Management
    
    func installLaunchAgent() async -> Bool {
        logger.info("Installing LaunchAgent for background monitoring")
        
        do {
            let plistPath = try createLaunchAgentPlist()
            let success = try await installPlistFile(at: plistPath)
            
            if success {
                isLaunchAgentInstalled = true
                saveUserPreferences()
                logger.info("LaunchAgent installed successfully")
                return true
            } else {
                logger.error("Failed to install LaunchAgent")
                return false
            }
        } catch {
            logger.error("Error installing LaunchAgent: \(error.localizedDescription)")
            return false
        }
    }
    
    func uninstallLaunchAgent() async -> Bool {
        logger.info("Uninstalling LaunchAgent")
        
        do {
            let success = try await unloadLaunchAgent()
            
            if success {
                isLaunchAgentInstalled = false
                backgroundMonitoringEnabled = false
                saveUserPreferences()
                logger.info("LaunchAgent uninstalled successfully")
                return true
            } else {
                logger.error("Failed to uninstall LaunchAgent")
                return false
            }
        } catch {
            logger.error("Error uninstalling LaunchAgent: \(error.localizedDescription)")
            return false
        }
    }
    
    func toggleBackgroundMonitoring() async {
        if backgroundMonitoringEnabled {
            backgroundMonitoringEnabled = false
            _ = try? await unloadLaunchAgent()
        } else {
            backgroundMonitoringEnabled = true
            if !isLaunchAgentInstalled {
                _ = await installLaunchAgent()
            } else {
                _ = await loadLaunchAgent()
            }
        }
        saveUserPreferences()
    }
    
    // MARK: - Private Methods
    
    private func checkLaunchAgentStatus() {
        let launchAgentsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
            .appendingPathComponent("\(launchAgentIdentifier).plist")
        
        isLaunchAgentInstalled = FileManager.default.fileExists(atPath: launchAgentsPath.path)
        
        if isLaunchAgentInstalled {
            // Check if it's actually loaded
            checkIfAgentIsLoaded()
        }
    }
    
    private func checkIfAgentIsLoaded() {
        // Check with launchctl if the agent is loaded
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["list", launchAgentIdentifier]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            backgroundMonitoringEnabled = task.terminationStatus == 0
        } catch {
            backgroundMonitoringEnabled = false
            logger.error("Failed to check agent status: \(error.localizedDescription)")
        }
    }
    
    private func createLaunchAgentPlist() throws -> URL {
        let launchAgentsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        
        // Ensure LaunchAgents directory exists
        try FileManager.default.createDirectory(at: launchAgentsPath, 
                                               withIntermediateDirectories: true)
        
        let plistPath = launchAgentsPath.appendingPathComponent("\(launchAgentIdentifier).plist")
        
        // Get the main app bundle path
        let appPath = Bundle.main.bundlePath
        
        let executablePath = URL(fileURLWithPath: appPath)
            .appendingPathComponent("Contents/MacOS/Smith")
        
        let plistContent = createPlistContent(executablePath: executablePath.path)
        
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)
        
        return plistPath
    }
    
    private func createPlistContent(executablePath: String) -> String {
        let intervalSeconds = Int(backgroundIntensity.updateInterval)
        
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(launchAgentIdentifier)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(executablePath)</string>
                <string>--background-monitor</string>
                <string>--intensity=\(backgroundIntensity.rawValue)</string>
            </array>
            <key>StartInterval</key>
            <integer>\(intervalSeconds)</integer>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
            <key>StandardOutPath</key>
            <string>/tmp/smith-background-monitor.log</string>
            <key>StandardErrorPath</key>
            <string>/tmp/smith-background-monitor-error.log</string>
            <key>EnvironmentVariables</key>
            <dict>
                <key>SMITH_BACKGROUND_MODE</key>
                <string>1</string>
            </dict>
        </dict>
        </plist>
        """
    }
    
    private func installPlistFile(at path: URL) async throws -> Bool {
        // Use launchctl to load the plist
        return try await withCheckedThrowingContinuation { continuation in
            let task = Process()
            task.launchPath = "/bin/launchctl"
            task.arguments = ["load", path.path]
            
            task.terminationHandler = { process in
                continuation.resume(returning: process.terminationStatus == 0)
            }
            
            do {
                try task.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func loadLaunchAgent() async -> Bool {
        let launchAgentsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
            .appendingPathComponent("\(launchAgentIdentifier).plist")
        
        guard FileManager.default.fileExists(atPath: launchAgentsPath.path) else {
            return false
        }
        
        do {
            return try await installPlistFile(at: launchAgentsPath)
        } catch {
            logger.error("Failed to load LaunchAgent: \(error.localizedDescription)")
            return false
        }
    }
    
    private func unloadLaunchAgent() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            let task = Process()
            task.launchPath = "/bin/launchctl"
            task.arguments = ["unload", launchAgentIdentifier]
            
            task.terminationHandler = { process in
                continuation.resume(returning: process.terminationStatus == 0)
            }
            
            do {
                try task.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - User Preferences
    
    private func loadUserPreferences() {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: "smith.background.intensity") != nil,
           let intensityRaw = defaults.string(forKey: "smith.background.intensity"),
           let intensity = BackgroundIntensity(rawValue: intensityRaw) {
            backgroundIntensity = intensity
        }
        
        backgroundMonitoringEnabled = defaults.bool(forKey: "smith.background.enabled")
    }
    
    private func saveUserPreferences() {
        let defaults = UserDefaults.standard
        defaults.set(backgroundIntensity.rawValue, forKey: "smith.background.intensity")
        defaults.set(backgroundMonitoringEnabled, forKey: "smith.background.enabled")
        defaults.set(isLaunchAgentInstalled, forKey: "smith.launchagent.installed")
        defaults.synchronize()
    }
    
    // MARK: - Intensity Management
    
    func setBackgroundIntensity(_ intensity: BackgroundIntensity) async {
        backgroundIntensity = intensity
        await updateLaunchAgent()
    }
    
    private func updateLaunchAgent() async {
        if isLaunchAgentInstalled && backgroundMonitoringEnabled {
            // Recreate the launch agent with new intensity
            _ = await uninstallLaunchAgent()
            _ = await installLaunchAgent()
        }
    }
    
    private func updateIntensityFromPlist() {
        // Read intensity from plist if available
        backgroundIntensity = .medium // Default fallback
    }
    
    var isBackgroundMonitoringEnabled: Bool {
        return isEnabled
    }
}

// MARK: - Errors

nonisolated enum LaunchAgentError: LocalizedError, Sendable {
    case bundlePathNotFound
    case plistCreationFailed
    case installationFailed
    
    var errorDescription: String? {
        switch self {
        case .bundlePathNotFound:
            return "Could not find application bundle path"
        case .plistCreationFailed:
            return "Failed to create LaunchAgent plist file"
        case .installationFailed:
            return "Failed to install LaunchAgent"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let smithLaunchAgentStatusChanged = Notification.Name("smithLaunchAgentStatusChanged")
    static let smithBackgroundMonitoringToggled = Notification.Name("smithBackgroundMonitoringToggled")
}
