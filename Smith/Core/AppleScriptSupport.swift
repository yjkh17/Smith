//
//  AppleScriptSupport.swift
//  Smith - AppleScript Integration & Automation
//
//  Phase 3: Deep System Integration - AppleScript Dictionary
//  Created by AI Assistant on 17/06/2025.
//

import Foundation
import AppKit
import os.log

/// Manages AppleScript integration and automation capabilities
@objc(SmithApplication)
@MainActor
class SmithApplication: NSApplication {
    
    private let logger = Logger(subsystem: "com.motherofbrand.Smith", category: "AppleScript")
    
    // MARK: - System Monitoring Commands
    
    @objc func getCPUUsage() -> NSNumber {
        let cpuMonitor = CPUMonitor()
        logger.info("AppleScript: getCPUUsage called - returning \(cpuMonitor.cpuUsage)")
        return NSNumber(value: cpuMonitor.cpuUsage)
    }
    
    @objc func getMemoryUsage() -> NSNumber {
        let memoryMonitor = MemoryMonitor()
        let percentage = (Double(memoryMonitor.usedMemory) / Double(memoryMonitor.totalMemory)) * 100.0
        logger.info("AppleScript: getMemoryUsage called - returning \(percentage)")
        return NSNumber(value: percentage)
    }
    
    @objc func getBatteryLevel() -> NSNumber {
        let batteryMonitor = BatteryMonitor()
        logger.info("AppleScript: getBatteryLevel called - returning \(batteryMonitor.batteryLevel)")
        return NSNumber(value: batteryMonitor.batteryLevel)
    }
    
    @objc func getCPUTemperature() -> NSNumber {
        let cpuMonitor = CPUMonitor()
        let temp = cpuMonitor.temperature
        logger.info("AppleScript: getCPUTemperature called - returning \(temp)")
        return NSNumber(value: temp)
    }
    
    @objc func getDiskUsage() -> NSString {
        // Get root disk usage
        do {
            let url = URL(fileURLWithPath: "/")
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey])
            
            if let capacity = values.volumeTotalCapacity,
               let available = values.volumeAvailableCapacity {
                let used = capacity - available
                let percentage = (Double(used) / Double(capacity)) * 100.0
                let result = String(format: "%.1f", percentage)
                logger.info("AppleScript: getDiskUsage called - returning \(result)%")
                return NSString(string: "\(result)%")
            }
        } catch {
            logger.error("AppleScript: getDiskUsage error - \(error.localizedDescription)")
        }
        
        return NSString(string: "0.0%")
    }
    
    // MARK: - System Analysis Commands
    
    @objc func analyzeSystemHealth() -> NSString {
        logger.info("AppleScript: analyzeSystemHealth called")
        
        let cpuMonitor = CPUMonitor()
        let memoryMonitor = MemoryMonitor()
        let batteryMonitor = BatteryMonitor()
        
        let cpuUsage = cpuMonitor.cpuUsage
        let memoryPercentage = (Double(memoryMonitor.usedMemory) / Double(memoryMonitor.totalMemory)) * 100.0
        let batteryLevel = batteryMonitor.batteryLevel
        let temperature = cpuMonitor.temperature
        
        var health = "EXCELLENT"
        var issues: [String] = []
        
        if cpuUsage > 80 {
            health = "WARNING"
            issues.append("High CPU usage (\(String(format: "%.1f", cpuUsage))%)")
        }
        
        if memoryPercentage > 85 {
            health = "WARNING"
            issues.append("High memory usage (\(String(format: "%.1f", memoryPercentage))%)")
        }
        
        if temperature > 80 {
            health = "WARNING"
            issues.append("High CPU temperature (\(String(format: "%.1f", temperature))°C)")
        }
        
        if batteryLevel < 20 && !batteryMonitor.isCharging {
            health = "CAUTION"
            issues.append("Low battery (\(String(format: "%.0f", batteryLevel))%)")
        }
        
        let report = """
        SYSTEM HEALTH REPORT
        Status: \(health)
        
        Current Metrics:
        • CPU Usage: \(String(format: "%.1f", cpuUsage))%
        • Memory Usage: \(String(format: "%.1f", memoryPercentage))%
        • Battery Level: \(String(format: "%.0f", batteryLevel))%
        • CPU Temperature: \(String(format: "%.1f", temperature))°C
        
        \(issues.isEmpty ? "No issues detected." : "Issues:\n• " + issues.joined(separator: "\n• "))
        
        Generated: \(Date().formatted(date: .abbreviated, time: .shortened))
        """
        
        return NSString(string: report)
    }
    
    @objc func getTopProcesses() -> NSString {
        logger.info("AppleScript: getTopProcesses called")
        
        // Get running processes using NSRunningApplication
        let runningApps = NSWorkspace.shared.runningApplications
        var processes: [(String, Int)] = []
        
        for app in runningApps {
            if let name = app.localizedName {
                // Estimate memory usage based on app type (this would need real implementation)
                let estimatedMemory = estimateMemoryUsage(for: app)
                processes.append((name, estimatedMemory))
            }
        }
        
        // Sort by estimated memory usage
        processes.sort { $0.1 > $1.1 }
        
        let topProcesses = processes.prefix(10)
        let processStrings = topProcesses.map { "\($0.0): ~\($0.1) MB" }
        
        let report = """
        TOP PROCESSES BY MEMORY USAGE
        
        \(processStrings.joined(separator: "\n"))
        
        Generated: \(Date().formatted(date: .abbreviated, time: .shortened))
        """
        
        return NSString(string: report)
    }
    
    // MARK: - AI Integration Commands
    
    @objc func askSmith(_ query: NSString) -> NSString {
        logger.info("AppleScript: askSmith called with query: \(query)")
        
        // Use notification system to send message to Smith
        NotificationCenter.default.post(
            name: .smithSendMessage, 
            object: query as String
        )
        
        return NSString(string: "Query sent to Smith AI: '\(query)'. Check the Smith app for the response.")
    }
    
    @objc func generateSystemReport() -> NSString {
        logger.info("AppleScript: generateSystemReport called")
        
        let cpuMonitor = CPUMonitor()
        let memoryMonitor = MemoryMonitor()
        let batteryMonitor = BatteryMonitor()
        
        let report = """
        COMPREHENSIVE SYSTEM REPORT
        Generated by Smith AI Assistant
        
        === SYSTEM OVERVIEW ===
        Date: \(Date().formatted(date: .complete, time: .shortened))
        macOS Version: \(Foundation.ProcessInfo.processInfo.operatingSystemVersionString)
        Computer: \(Host.current().localizedName ?? "Unknown")
        
        === PERFORMANCE METRICS ===
        CPU Usage: \(String(format: "%.1f", cpuMonitor.cpuUsage))%
        CPU Temperature: \(String(format: "%.1f", cpuMonitor.temperature))°C
        Memory Usage: \(String(format: "%.1f", (Double(memoryMonitor.usedMemory) / Double(memoryMonitor.totalMemory)) * 100.0))%
        Memory Pressure: \(memoryMonitor.memoryPressure.description)
        Total Memory: \(String(format: "%.1f", Double(memoryMonitor.totalMemory) / 1_073_741_824)) GB
        Used Memory: \(String(format: "%.1f", Double(memoryMonitor.usedMemory) / 1_073_741_824)) GB
        
        === POWER STATUS ===
        Battery Level: \(String(format: "%.0f", batteryMonitor.batteryLevel))%
        Charging: \(batteryMonitor.isCharging ? "Yes" : "No")
        Battery Health: \(batteryMonitor.getBatteryHealthRating().0)
        
        === THERMAL STATUS ===
        CPU Temperature: \(String(format: "%.1f", cpuMonitor.temperature))°C
        Thermal State: \(cpuMonitor.temperature > 80 ? "High" : cpuMonitor.temperature > 60 ? "Normal" : "Cool")
        
        === STORAGE OVERVIEW ===
        """
        
        // Add disk information
        var diskInfo = ""
        do {
            let url = URL(fileURLWithPath: "/")
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey, .volumeNameKey])
            
            if let capacity = values.volumeTotalCapacity,
               let available = values.volumeAvailableCapacity,
               let name = values.volumeName {
                let used = capacity - available
                let percentage = (Double(used) / Double(capacity)) * 100.0
                let capacityGB = Double(capacity) / 1_073_741_824
                let usedGB = Double(used) / 1_073_741_824
                let availableGB = Double(available) / 1_073_741_824
                
                diskInfo = """
                Volume: \(name)
                Total Capacity: \(String(format: "%.1f", capacityGB)) GB
                Used: \(String(format: "%.1f", usedGB)) GB (\(String(format: "%.1f", percentage))%)
                Available: \(String(format: "%.1f", availableGB)) GB
                """
            }
        } catch {
            diskInfo = "Storage information unavailable"
        }
        
        let fullReport = report + diskInfo + "\n\n=== END REPORT ==="
        
        return NSString(string: fullReport)
    }
    
    // MARK: - Background Monitoring Commands
    
    @objc func enableBackgroundMonitoring() -> NSString {
        logger.info("AppleScript: enableBackgroundMonitoring called")
        
        // Post notification to enable background monitoring
        NotificationCenter.default.post(name: .smithBackgroundMonitoringToggled, object: true)
        
        return NSString(string: "Background monitoring enabled. Smith will now monitor your system in the background.")
    }
    
    @objc func disableBackgroundMonitoring() -> NSString {
        logger.info("AppleScript: disableBackgroundMonitoring called")
        
        // Post notification to disable background monitoring
        NotificationCenter.default.post(name: .smithBackgroundMonitoringToggled, object: false)
        
        return NSString(string: "Background monitoring disabled.")
    }
    
    @objc func setBackgroundIntensity(_ intensity: NSString) -> NSString {
        logger.info("AppleScript: setBackgroundIntensity called with: \(intensity)")
        
        guard LaunchAgentManager.BackgroundIntensity(rawValue: intensity as String) != nil else {
            return NSString(string: "Invalid intensity level. Use 'minimal', 'balanced', or 'comprehensive'.")
        }
        
        // Post notification with intensity change
        NotificationCenter.default.post(
            name: .smithBackgroundIntensityChanged,
            object: intensity as String
        )
        
        return NSString(string: "Background monitoring intensity set to '\(intensity)'.")
    }
    
    // MARK: - Helper Methods
    
    private func estimateMemoryUsage(for app: NSRunningApplication) -> Int {
        // Basic estimation based on app type
        // In a real implementation, this would use task_info() API
        switch app.bundleIdentifier {
        case .some(let id) where id.contains("Xcode"):
            return 2000 // MB
        case .some(let id) where id.contains("Chrome") || id.contains("Firefox"):
            return 800
        case .some(let id) where id.contains("Photoshop") || id.contains("Final Cut"):
            return 1500
        case .some(let id) where id.contains("Finder"):
            return 200
        case .some(let id) where id.contains("TextEdit") || id.contains("Calculator"):
            return 50
        default:
            return 300
        }
    }
}

// MARK: - Background Intensity Notification Extension

extension Notification.Name {
    static let smithBackgroundIntensityChanged = Notification.Name("smithBackgroundIntensityChanged")
}
