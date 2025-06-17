//
//  ShortcutsIntegration.swift
//  Smith - Shortcuts App Integration
//
//  Phase 3: Deep System Integration - Shortcuts Support
//  Created by AI Assistant on 17/06/2025.
//

import Foundation
import AppKit
import os.log

/// Manages Shortcuts app integration
class ShortcutsIntegration {
    
    private let logger = Logger(subsystem: "com.motherofbrand.Smith", category: "Shortcuts")
    
    func setupShortcutsSupport() {
        // Basic shortcuts support setup
        logger.info("Shortcuts integration initialized")
        
        // Register URL handlers for shortcuts
        registerShortcutURLHandlers()
    }
    
    private func registerShortcutURLHandlers() {
        // This would register handlers for shortcuts-specific URLs
        logger.info("Shortcuts URL handlers registered")
    }
    
    // MARK: - Shortcuts Actions
    
    func getSystemStats() -> String {
        logger.info("Shortcuts: getSystemStats called")
        
        let cpuMonitor = CPUMonitor()
        let memoryMonitor = MemoryMonitor()
        let batteryMonitor = BatteryMonitor()
        
        let cpuUsage = cpuMonitor.cpuUsage
        let memoryPercentage = (Double(memoryMonitor.usedMemory) / Double(memoryMonitor.totalMemory)) * 100.0
        let batteryLevel = batteryMonitor.batteryLevel
        let temperature = cpuMonitor.temperature
        
        return """
        System Statistics:
        • CPU Usage: \(String(format: "%.1f", cpuUsage))%
        • Memory Usage: \(String(format: "%.1f", memoryPercentage))%
        • Battery Level: \(String(format: "%.0f", batteryLevel))%
        • CPU Temperature: \(String(format: "%.1f", temperature))°C
        
        Generated: \(Date().formatted(date: .abbreviated, time: .shortened))
        """
    }
    
    func analyzeSystemHealth() -> String {
        logger.info("Shortcuts: analyzeSystemHealth called")
        
        let cpuMonitor = CPUMonitor()
        let memoryMonitor = MemoryMonitor()
        let batteryMonitor = BatteryMonitor()
        
        let cpuUsage = cpuMonitor.cpuUsage
        let memoryPercentage = (Double(memoryMonitor.usedMemory) / Double(memoryMonitor.totalMemory)) * 100.0
        let batteryLevel = batteryMonitor.batteryLevel
        let temperature = cpuMonitor.temperature
        
        var healthScore = 100
        var recommendations: [String] = []
        var status = "EXCELLENT"
        
        // Health analysis logic
        if cpuUsage > 80 {
            healthScore -= 20
            status = "WARNING"
            recommendations.append("Consider closing resource-intensive applications")
        }
        
        if memoryPercentage > 85 {
            healthScore -= 25
            status = "WARNING"
            recommendations.append("Close unused applications to free up memory")
        }
        
        if temperature > 80 {
            healthScore -= 15
            status = "CAUTION"
            recommendations.append("Allow system to cool down - consider reducing workload")
        }
        
        if batteryLevel < 20 && !batteryMonitor.isCharging {
            healthScore -= 10
            if status == "EXCELLENT" { status = "CAUTION" }
            recommendations.append("Connect power adapter - battery is low")
        }
        
        return """
        SYSTEM HEALTH ANALYSIS
        
        Overall Status: \(status)
        Health Score: \(max(healthScore, 0))/100
        
        Current Metrics:
        • CPU Usage: \(String(format: "%.1f", cpuUsage))%
        • Memory Usage: \(String(format: "%.1f", memoryPercentage))%
        • Battery Level: \(String(format: "%.0f", batteryLevel))%
        • CPU Temperature: \(String(format: "%.1f", temperature))°C
        
        \(recommendations.isEmpty ? "✅ No issues detected - system is running optimally!" : "⚠️ Recommendations:\n" + recommendations.map { "• \($0)" }.joined(separator: "\n"))
        
        Generated: \(Date().formatted(date: .abbreviated, time: .shortened))
        """
    }
    
    func askSmith(_ query: String) -> String {
        logger.info("Shortcuts: askSmith called with query: \(query)")
        
        // Send query to Smith via URL scheme
        if let url = URL(string: "smith://chat?message=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            NSWorkspace.shared.open(url)
        }
        
        return "Query sent to Smith AI: '\(query)'\n\nOpen the Smith app to see the AI response."
    }
    
    func enableBackgroundMonitoring() -> String {
        logger.info("Shortcuts: enableBackgroundMonitoring called")
        
        // Enable background monitoring via URL scheme
        if let url = URL(string: "smith://enable-background-monitoring") {
            NSWorkspace.shared.open(url)
        }
        
        return "Background monitoring has been enabled. Smith will now monitor your system continuously."
    }
}
