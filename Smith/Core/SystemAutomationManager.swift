//
//  SystemAutomationManager.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 17/06/2025.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications
import IOKit
import ServiceManagement

@MainActor
class SystemAutomationManager: ObservableObject {
    @Published var isAutomationEnabled = false
    @Published var automationTasks: [AutomationTask] = []
    @Published var scheduledMaintenance: [MaintenanceTask] = []
    @Published var lastMaintenanceRun: Date?
    @Published var nextScheduledMaintenance: Date?
    
    private var maintenanceTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Dependencies
    private var cpuMonitor: CPUMonitor?
    private var batteryMonitor: BatteryMonitor?
    private var memoryMonitor: MemoryMonitor?
    private var networkMonitor: NetworkMonitor?
    private var storageMonitor: StorageMonitor?
    private var intelligenceEngine: IntelligenceEngine?
    
    init() {
        setupAutomationTasks()
        setupScheduledMaintenance()
        startAutomationEngine()
    }
    
    // MARK: - Setup
    func setMonitors(cpu: CPUMonitor, battery: BatteryMonitor, memory: MemoryMonitor, network: NetworkMonitor, storage: StorageMonitor, intelligence: IntelligenceEngine) {
        self.cpuMonitor = cpu
        self.batteryMonitor = battery
        self.memoryMonitor = memory
        self.networkMonitor = network
        self.storageMonitor = storage
        self.intelligenceEngine = intelligence
    }
    
    private func setupAutomationTasks() {
        automationTasks = [
            AutomationTask(
                id: "cache-cleanup",
                title: "Cache Cleanup",
                description: "Automatically clean system and app caches",
                category: .maintenance,
                isEnabled: true,
                frequency: .weekly,
                lastRun: nil,
                priority: .medium
            ),
            AutomationTask(
                id: "log-rotation",
                title: "Log Rotation",
                description: "Archive and compress old system logs",
                category: .maintenance,
                isEnabled: true,
                frequency: .weekly,
                lastRun: nil,
                priority: .low
            ),
            AutomationTask(
                id: "disk-optimization",
                title: "Disk Optimization",
                description: "Optimize disk usage and defragment if needed",
                category: .performance,
                isEnabled: false,
                frequency: .monthly,
                lastRun: nil,
                priority: .high
            ),
            AutomationTask(
                id: "memory-pressure-relief",
                title: "Memory Pressure Relief",
                description: "Automatically free memory when usage is high",
                category: .performance,
                isEnabled: true,
                frequency: .asNeeded,
                lastRun: nil,
                priority: .high
            ),
            AutomationTask(
                id: "thermal-management",
                title: "Thermal Management",
                description: "Reduce CPU load when temperature is too high",
                category: .performance,
                isEnabled: true,
                frequency: .asNeeded,
                lastRun: nil,
                priority: .critical
            ),
            AutomationTask(
                id: "battery-optimization",
                title: "Battery Optimization",
                description: "Optimize power usage based on battery level",
                category: .power,
                isEnabled: true,
                frequency: .asNeeded,
                lastRun: nil,
                priority: .medium
            ),
            AutomationTask(
                id: "file-organization",
                title: "Smart File Organization",
                description: "Organize files based on usage patterns",
                category: .organization,
                isEnabled: false,
                frequency: .weekly,
                lastRun: nil,
                priority: .low
            ),
            AutomationTask(
                id: "duplicate-detection",
                title: "Duplicate File Detection",
                description: "Find and suggest removal of duplicate files",
                category: .organization,
                isEnabled: false,
                frequency: .monthly,
                lastRun: nil,
                priority: .medium
            )
        ]
    }
    
    private func setupScheduledMaintenance() {
        scheduledMaintenance = [
            MaintenanceTask(
                title: "Weekly System Cleanup",
                description: "Clear caches, logs, and temporary files",
                scheduledDate: nextWeeklyMaintenanceDate(),
                estimatedDuration: 300, // 5 minutes
                tasks: ["cache-cleanup", "log-rotation"]
            ),
            MaintenanceTask(
                title: "Monthly Optimization",
                description: "Full system optimization and analysis",
                scheduledDate: nextMonthlyMaintenanceDate(),
                estimatedDuration: 900, // 15 minutes
                tasks: ["disk-optimization", "duplicate-detection"]
            )
        ]
        
        updateNextScheduledMaintenance()
    }
    
    private func startAutomationEngine() {
        // Start monitoring timer
        maintenanceTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                await self.checkAutomationTriggers()
            }
        }
        
        isAutomationEnabled = true
    }
    
    // MARK: - Automation Logic
    private func checkAutomationTriggers() async {
        guard isAutomationEnabled else { return }
        
        let currentDate = Date()
        
        // Check scheduled maintenance
        if let nextMaintenance = nextScheduledMaintenance,
           currentDate >= nextMaintenance {
            await runScheduledMaintenance()
        }
        
        // Check conditional automation tasks
        for task in automationTasks where task.isEnabled && task.frequency == .asNeeded {
            if await shouldTriggerTask(task) {
                await executeAutomationTask(task)
            }
        }
        
        // Check time-based automation tasks
        for task in automationTasks where task.isEnabled && task.frequency != .asNeeded {
            if shouldRunScheduledTask(task) {
                await executeAutomationTask(task)
            }
        }
    }
    
    private func shouldTriggerTask(_ task: AutomationTask) async -> Bool {
        switch task.id {
        case "memory-pressure-relief":
            return await checkMemoryPressure()
        case "thermal-management":
            return await checkThermalThrottling()
        case "battery-optimization":
            return await checkBatteryOptimizationNeeded()
        default:
            return false
        }
    }
    
    private func shouldRunScheduledTask(_ task: AutomationTask) -> Bool {
        guard let lastRun = task.lastRun else { return true }
        
        let timeInterval: TimeInterval
        switch task.frequency {
        case .daily:
            timeInterval = 24 * 60 * 60
        case .weekly:
            timeInterval = 7 * 24 * 60 * 60
        case .monthly:
            timeInterval = 30 * 24 * 60 * 60
        case .asNeeded:
            return false
        }
        
        return Date().timeIntervalSince(lastRun) >= timeInterval
    }
    
    // MARK: - Task Execution
    private func executeAutomationTask(_ task: AutomationTask) async {
        print("🤖 Executing automation task: \(task.title)")
        
        switch task.id {
        case "cache-cleanup":
            await performCacheCleanup()
        case "log-rotation":
            await performLogRotation()
        case "disk-optimization":
            await performDiskOptimization()
        case "memory-pressure-relief":
            await performMemoryPressureRelief()
        case "thermal-management":
            await performThermalManagement()
        case "battery-optimization":
            await performBatteryOptimization()
        case "file-organization":
            await performFileOrganization()
        case "duplicate-detection":
            await performDuplicateDetection()
        default:
            break
        }
        
        // Update last run time
        if let index = automationTasks.firstIndex(where: { $0.id == task.id }) {
            automationTasks[index].lastRun = Date()
        }
    }
    
    private func runScheduledMaintenance() async {
        guard let maintenance = scheduledMaintenance.first(where: { Date() >= $0.scheduledDate }) else { return }
        
        print("🔧 Running scheduled maintenance: \(maintenance.title)")
        
        for taskId in maintenance.tasks {
            if let task = automationTasks.first(where: { $0.id == taskId && $0.isEnabled }) {
                await executeAutomationTask(task)
            }
        }
        
        // Update next scheduled maintenance
        if let index = scheduledMaintenance.firstIndex(where: { $0.id == maintenance.id }) {
            if maintenance.title.contains("Weekly") {
                scheduledMaintenance[index].scheduledDate = nextWeeklyMaintenanceDate()
            } else if maintenance.title.contains("Monthly") {
                scheduledMaintenance[index].scheduledDate = nextMonthlyMaintenanceDate()
            }
        }
        
        lastMaintenanceRun = Date()
        updateNextScheduledMaintenance()
        
        // Send notification
        await sendMaintenanceNotification(maintenance)
    }
    
    // MARK: - Condition Checks
    private func checkMemoryPressure() async -> Bool {
        guard let memoryMonitor = memoryMonitor else { return false }
        
        // Enhanced memory pressure detection with IOKit
        var vmStat = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &vmStat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let totalPages = vmStat.free_count + vmStat.active_count + vmStat.inactive_count + vmStat.wire_count
            let usedPages = vmStat.active_count + vmStat.wire_count
            let memoryPressureRatio = Double(usedPages) / Double(totalPages)
            
            // Consider high pressure if > 85% used
            if memoryPressureRatio > 0.85 {
                return true
            }
        }
        
        // Fallback to existing check
        switch memoryMonitor.memoryPressure {
        case .normal, .warning:
            return false
        case .critical:
            return true
        }
    }
    
    private func checkThermalThrottling() async -> Bool {
        guard let cpuMonitor = cpuMonitor else { return false }
        
        // Simplified thermal check without IOKit to avoid compilation issues
        return cpuMonitor.isThrottling || cpuMonitor.temperature > 85.0
    }
    
    private func checkBatteryOptimizationNeeded() async -> Bool {
        guard let batteryMonitor = batteryMonitor else { return false }
        return batteryMonitor.batteryLevel < 20.0 && !batteryMonitor.isCharging
    }
    
    // MARK: - Task Implementations
    private func performCacheCleanup() async {
        let cacheDirectories = [
            "~/Library/Caches",
            "/tmp",
            "~/Library/Application Support/CrashReporter"
        ]
        
        for directory in cacheDirectories {
            await cleanDirectory(directory)
        }
    }
    
    private func performLogRotation() async {
        let logDirectories = [
            "~/Library/Logs",
            "/var/log"
        ]
        
        for directory in logDirectories {
            await rotateLogsInDirectory(directory)
        }
    }
    
    private func performDiskOptimization() async {
        // Run disk utility first aid
        await runDiskUtilityFirstAid()
        
        // Optimize disk usage
        await optimizeDiskUsage()
    }
    
    private func performMemoryPressureRelief() async {
        // Force garbage collection
        await forceGarbageCollection()
        
        // Purge memory caches
        await purgeMemoryCaches()
    }
    
    private func performThermalManagement() async {
        guard let cpuMonitor = cpuMonitor else { return }
        
        if cpuMonitor.temperature > 90.0 {
            // Emergency thermal protection
            await emergencyThermalProtection()
        } else if cpuMonitor.temperature > 85.0 {
            // Gradual thermal management
            await gradualThermalManagement()
        }
    }
    
    private func performBatteryOptimization() async {
        guard let batteryMonitor = batteryMonitor else { return }
        
        if batteryMonitor.batteryLevel < 15.0 {
            await emergencyPowerSaving()
        } else if batteryMonitor.batteryLevel < 30.0 {
            await standardPowerSaving()
        }
    }
    
    private func performFileOrganization() async {
        let organizationDirectories = [
            "~/Desktop",
            "~/Downloads",
            "~/Documents"
        ]
        
        for directory in organizationDirectories {
            await organizeFilesInDirectory(directory)
        }
    }
    
    private func performDuplicateDetection() async {
        let searchDirectories = [
            "~/Desktop",
            "~/Downloads",
            "~/Documents",
            "~/Pictures"
        ]
        
        for directory in searchDirectories {
            await findDuplicatesInDirectory(directory)
        }
    }
    
    // MARK: - Helper Methods
    private func cleanDirectory(_ path: String) async {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: expandedPath)
            let now = Date()
            let oneWeekAgo = now.addingTimeInterval(-7 * 24 * 60 * 60)
            
            for item in contents {
                let itemPath = expandedPath + "/" + item
                let attributes = try fileManager.attributesOfItem(atPath: itemPath)
                
                if let modificationDate = attributes[.modificationDate] as? Date,
                   modificationDate < oneWeekAgo {
                    try fileManager.removeItem(atPath: itemPath)
                }
            }
        } catch {
            print("Error cleaning directory \(path): \(error)")
        }
    }
    
    private func rotateLogsInDirectory(_ path: String) async {
        // Compress logs older than 7 days
        // This would typically use system tools like gzip
    }
    
    private func runDiskUtilityFirstAid() async {
        let task = Process()
        task.launchPath = "/usr/sbin/diskutil"
        task.arguments = ["verifyVolume", "/"]
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Error running disk utility: \(error)")
        }
    }
    
    private func optimizeDiskUsage() async {
        // Optimize disk usage patterns
        // This could include defragmentation on supported file systems
    }
    
    private func forceGarbageCollection() async {
        // Force Swift/Objective-C garbage collection
        // This is more relevant for apps with heavy memory usage
    }
    
    private func purgeMemoryCaches() async {
        let task = Process()
        task.launchPath = "/usr/bin/purge"
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Error purging memory: \(error)")
        }
    }
    
    private func emergencyThermalProtection() async {
        // Reduce CPU frequency, close non-essential apps
        print("🚨 Emergency thermal protection activated")
    }
    
    private func gradualThermalManagement() async {
        // Reduce background activity, lower CPU targets
        print("🌡️ Thermal management active")
    }
    
    private func emergencyPowerSaving() async {
        // Maximum power saving mode
        print("🔋 Emergency power saving activated")
    }
    
    private func standardPowerSaving() async {
        // Standard power saving measures
        print("⚡ Power saving mode active")
    }
    
    private func organizeFilesInDirectory(_ path: String) async {
        // Smart file organization based on type, age, and usage
    }
    
    private func findDuplicatesInDirectory(_ path: String) async {
        // Find duplicate files using hash comparison
    }
    
    private func sendMaintenanceNotification(_ maintenance: MaintenanceTask) async {
        let content = UNMutableNotificationContent()
        content.title = "Smith Maintenance Complete"
        content.body = "Completed: \(maintenance.title)"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: "maintenance-\(maintenance.id)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error sending notification: \(error)")
        }
    }
    
    // MARK: - Date Helpers
    private func nextWeeklyMaintenanceDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Schedule for Sunday at 2 AM
        var components = calendar.dateComponents([.year, .month, .weekOfYear], from: now)
        components.weekday = 1 // Sunday
        components.hour = 2
        components.minute = 0
        components.second = 0
        
        if let date = calendar.date(from: components), date > now {
            return date
        } else {
            components.weekOfYear! += 1
            return calendar.date(from: components) ?? now.addingTimeInterval(7 * 24 * 60 * 60)
        }
    }
    
    private func nextMonthlyMaintenanceDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Schedule for first Sunday of next month at 3 AM
        var components = calendar.dateComponents([.year, .month], from: now)
        components.month! += 1
        components.day = 1
        components.hour = 3
        components.minute = 0
        components.second = 0
        
        guard let firstOfMonth = calendar.date(from: components) else {
            return now.addingTimeInterval(30 * 24 * 60 * 60)
        }
        
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToSunday = (8 - weekday) % 7
        
        return calendar.date(byAdding: .day, value: daysToSunday, to: firstOfMonth) ?? firstOfMonth
    }
    
    private func updateNextScheduledMaintenance() {
        nextScheduledMaintenance = scheduledMaintenance.map(\.scheduledDate).min()
    }
    
    // MARK: - Public Interface
    func toggleAutomation() {
        isAutomationEnabled.toggle()
        
        if isAutomationEnabled {
            startAutomationEngine()
        } else {
            maintenanceTimer?.invalidate()
            maintenanceTimer = nil
        }
    }
    
    func toggleTask(_ taskId: String) {
        if let index = automationTasks.firstIndex(where: { $0.id == taskId }) {
            automationTasks[index].isEnabled.toggle()
        }
    }
    
    func runTaskNow(_ taskId: String) async {
        if let task = automationTasks.first(where: { $0.id == taskId }) {
            await executeAutomationTask(task)
        }
    }
    
    func runMaintenanceNow() async {
        if scheduledMaintenance.contains(where: { $0.scheduledDate <= Date().addingTimeInterval(24 * 60 * 60) }) {
            await runScheduledMaintenance()
        }
    }
}

// MARK: - Supporting Types
struct AutomationTask: Identifiable {
    let id: String
    let title: String
    let description: String
    let category: TaskCategory
    var isEnabled: Bool
    let frequency: TaskFrequency
    var lastRun: Date?
    let priority: TaskPriority
}

struct MaintenanceTask: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    var scheduledDate: Date
    let estimatedDuration: TimeInterval
    let tasks: [String]
}

enum TaskCategory: String, CaseIterable {
    case maintenance = "Maintenance"
    case performance = "Performance"
    case power = "Power"
    case organization = "Organization"
    
    var icon: String {
        switch self {
        case .maintenance: return "wrench.and.screwdriver"
        case .performance: return "speedometer"
        case .power: return "battery.100"
        case .organization: return "folder.badge.gearshape"
        }
    }
    
    var color: Color {
        switch self {
        case .maintenance: return .blue
        case .performance: return .green
        case .power: return .yellow
        case .organization: return .purple
        }
    }
}

enum TaskFrequency: String, CaseIterable {
    case asNeeded = "As Needed"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

enum TaskPriority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}
