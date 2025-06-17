//
//  IntelligenceEngine.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 17/06/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class IntelligenceEngine: ObservableObject {
    // MARK: - Published Properties
    @Published var currentInsights: [SystemInsight] = []
    @Published var optimizationSuggestions: [OptimizationSuggestion] = []
    @Published var performanceScore: Double = 0.0
    @Published var currentWorkload: WorkloadType = .unknown
    @Published var systemPersonality: SystemPersonality = .balanced
    @Published var activeAnomalies: [SystemAnomaly] = []
    @Published var sessionMemory: SessionMemory = SessionMemory()
    
    // MARK: - Dependencies
    private weak var cpuMonitor: CPUMonitor?
    private weak var batteryMonitor: BatteryMonitor?
    private weak var memoryMonitor: MemoryMonitor?
    
    // MARK: - Session Intelligence
    private var sessionStartTime: Date = Date()
    private var workloadHistory: [WorkloadDetection] = []
    private var performanceHistory: [PerformanceSnapshot] = []
    private var userInteractions: [UserInteraction] = []
    
    // MARK: - Real-Time Analysis Timer
    nonisolated(unsafe) private var analysisTimer: Timer?
    private let analysisInterval: TimeInterval = 5.0 // Analyze every 5 seconds
    
    init() {
        sessionStartTime = Date()
        startRealTimeAnalysis()
    }
    
    deinit {
        analysisTimer?.invalidate()
        analysisTimer = nil
    }
    
    // MARK: - System Monitor Integration
    func setMonitors(cpu: CPUMonitor, battery: BatteryMonitor, memory: MemoryMonitor) {
        self.cpuMonitor = cpu
        self.batteryMonitor = battery
        self.memoryMonitor = memory
    }
    
    // MARK: - Real-Time Analysis
    private func startRealTimeAnalysis() {
        analysisTimer = Timer.scheduledTimer(withTimeInterval: analysisInterval, repeats: true) { _ in
            Task { @MainActor in
                await self.performRealTimeAnalysis()
            }
        }
        
        // Initial analysis
        Task {
            await performRealTimeAnalysis()
        }
    }
    
    private func performRealTimeAnalysis() async {
        let snapshot = captureCurrentSnapshot()
        
        // Core intelligence operations
        await analyzeWorkload(snapshot)
        await detectAnomalies(snapshot)
        await generateInsights(snapshot)
        await calculatePerformanceScore(snapshot)
        await generateOptimizations(snapshot)
        await updateSessionMemory(snapshot)
        
        // Update system personality
        systemPersonality = determineSystemPersonality(snapshot)
    }
    
    // MARK: - System Snapshot
    private func captureCurrentSnapshot() -> SystemSnapshot {
        let currentTime = Date()
        
        return SystemSnapshot(
            timestamp: currentTime,
            cpuUsage: cpuMonitor?.cpuUsage ?? 0.0,
            cpuCoreUsage: cpuMonitor?.perCoreUsage ?? [],
            cpuTemperature: cpuMonitor?.temperature ?? 0.0,
            cpuProcesses: cpuMonitor?.processes ?? [],
            memoryUsage: memoryMonitor?.usedMemory ?? 0,
            memoryPressure: memoryMonitor?.memoryPressure ?? .normal,
            memoryProcesses: memoryMonitor?.topMemoryProcesses ?? [],
            batteryLevel: batteryMonitor?.batteryLevel ?? 0.0,
            batteryState: batteryMonitor?.batteryState ?? .unknown,
            powerUsage: batteryMonitor?.powerUsage ?? 0.0,
            runningApplications: getRunningApplications()
        )
    }
    
    private func getRunningApplications() -> [RunningApplication] {
        let workspace = NSWorkspace.shared
        return workspace.runningApplications.compactMap { app in
            guard let name = app.localizedName ?? app.bundleIdentifier else { return nil }
            return RunningApplication(
                name: name,
                bundleIdentifier: app.bundleIdentifier ?? "",
                pid: Int(app.processIdentifier),
                isActive: app.isActive,
                isHidden: app.isHidden
            )
        }
    }
    
    // MARK: - Workload Analysis
    private func analyzeWorkload(_ snapshot: SystemSnapshot) async {
        let detectedWorkload = detectWorkloadType(snapshot)
        
        // Add to workload history
        let detection = WorkloadDetection(
            timestamp: snapshot.timestamp,
            workload: detectedWorkload,
            confidence: calculateWorkloadConfidence(detectedWorkload, snapshot)
        )
        workloadHistory.append(detection)
        
        // Keep only recent history (last hour)
        let oneHourAgo = Date().addingTimeInterval(-3600)
        workloadHistory = workloadHistory.filter { $0.timestamp > oneHourAgo }
        
        // Update current workload if confidence is high enough
        if detection.confidence > 0.7 {
            currentWorkload = detectedWorkload
        }
    }
    
    private func detectWorkloadType(_ snapshot: SystemSnapshot) -> WorkloadType {
        let apps = snapshot.runningApplications
        let processes = snapshot.cpuProcesses
        
        // Development workload detection
        if apps.contains(where: { $0.name.lowercased().contains("xcode") }) ||
           apps.contains(where: { $0.name.lowercased().contains("code") }) ||
           processes.contains(where: { $0.name.lowercased().contains("swift") }) {
            return .development
        }
        
        // Design workload detection
        if apps.contains(where: { ["figma", "sketch", "photoshop", "illustrator"].contains($0.name.lowercased()) }) {
            return .design
        }
        
        // Video editing detection
        if apps.contains(where: { ["final cut", "premiere", "davinci"].contains($0.name.lowercased()) }) {
            return .videoEditing
        }
        
        // Gaming detection
        if apps.contains(where: { $0.name.lowercased().contains("steam") }) ||
           snapshot.cpuUsage > 60 && processes.contains(where: { $0.displayName.contains("Unity") }) {
            return .gaming
        }
        
        // Web browsing detection
        if apps.filter({ ["safari", "chrome", "firefox"].contains($0.name.lowercased()) }).count > 0 &&
           snapshot.cpuUsage < 30 {
            return .browsing
        }
        
        // Office work detection
        if apps.contains(where: { ["word", "excel", "powerpoint", "keynote", "pages", "numbers"].contains($0.name.lowercased()) }) {
            return .office
        }
        
        return .unknown
    }
    
    private func calculateWorkloadConfidence(_ workload: WorkloadType, _ snapshot: SystemSnapshot) -> Double {
        // Base confidence on multiple factors
        var confidence: Double = 0.5
        
        switch workload {
        case .development:
            if snapshot.cpuUsage > 40 { confidence += 0.2 }
            if snapshot.memoryUsage > 8_000_000_000 { confidence += 0.2 } // 8GB+
            confidence += 0.1
            
        case .design:
            if snapshot.memoryUsage > 4_000_000_000 { confidence += 0.2 } // 4GB+
            confidence += 0.2
            
        case .videoEditing:
            if snapshot.cpuUsage > 50 { confidence += 0.3 }
            confidence += 0.2
            
        case .gaming:
            if snapshot.cpuUsage > 60 { confidence += 0.2 }
            if snapshot.powerUsage > 20 { confidence += 0.2 }
            confidence += 0.1
            
        case .browsing:
            if snapshot.cpuUsage < 20 { confidence += 0.3 }
            confidence += 0.1
            
        case .office:
            if snapshot.cpuUsage < 30 { confidence += 0.2 }
            confidence += 0.2
            
        case .unknown:
            confidence = 0.1
        }
        
        return min(1.0, confidence)
    }
    
    // MARK: - Anomaly Detection
    private func detectAnomalies(_ snapshot: SystemSnapshot) async {
        var newAnomalies: [SystemAnomaly] = []
        
        // CPU anomalies
        if let cpuAnomaly = detectCPUAnomaly(snapshot) {
            newAnomalies.append(cpuAnomaly)
        }
        
        // Memory anomalies
        if let memoryAnomaly = detectMemoryAnomaly(snapshot) {
            newAnomalies.append(memoryAnomaly)
        }
        
        // Battery anomalies
        if let batteryAnomaly = detectBatteryAnomaly(snapshot) {
            newAnomalies.append(batteryAnomaly)
        }
        
        // Process anomalies
        let processAnomalies = detectProcessAnomalies(snapshot)
        newAnomalies.append(contentsOf: processAnomalies)
        
        // Update active anomalies (keep only recent ones)
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        activeAnomalies = activeAnomalies.filter { $0.timestamp > fiveMinutesAgo }
        activeAnomalies.append(contentsOf: newAnomalies)
    }
    
    private func detectCPUAnomaly(_ snapshot: SystemSnapshot) -> SystemAnomaly? {
        let normalThreshold = getNormalCPUThreshold(for: currentWorkload)
        
        if snapshot.cpuUsage > normalThreshold {
            return SystemAnomaly(
                type: .cpuSpike,
                severity: snapshot.cpuUsage > 90 ? .critical : .warning,
                title: "High CPU Usage",
                description: "CPU usage (\(Int(snapshot.cpuUsage))%) is higher than normal for \(currentWorkload.displayName) workload",
                affectedComponent: "CPU",
                suggestedAction: generateCPUOptimizationAction(snapshot),
                timestamp: snapshot.timestamp
            )
        }
        
        return nil
    }
    
    private func detectMemoryAnomaly(_ snapshot: SystemSnapshot) -> SystemAnomaly? {
        guard let totalMemory = memoryMonitor?.totalMemory else { return nil }
        
        let memoryPercentage = Double(snapshot.memoryUsage) / Double(totalMemory) * 100
        let normalThreshold = getNormalMemoryThreshold(for: currentWorkload)
        
        if memoryPercentage > normalThreshold {
            return SystemAnomaly(
                type: .memoryPressure,
                severity: memoryPercentage > 95 ? .critical : .warning,
                title: "High Memory Usage",
                description: "Memory usage (\(Int(memoryPercentage))%) is higher than normal for \(currentWorkload.displayName) workload",
                affectedComponent: "Memory",
                suggestedAction: generateMemoryOptimizationAction(snapshot),
                timestamp: snapshot.timestamp
            )
        }
        
        return nil
    }
    
    private func detectBatteryAnomaly(_ snapshot: SystemSnapshot) -> SystemAnomaly? {
        let normalPowerUsage = getNormalPowerUsage(for: currentWorkload)
        
        if snapshot.powerUsage > normalPowerUsage * 1.5 {
            return SystemAnomaly(
                type: .unusualPowerDrain,
                severity: .warning,
                title: "High Power Usage",
                description: "Power usage (\(String(format: "%.1f", snapshot.powerUsage))W) is higher than normal for \(currentWorkload.displayName) workload",
                affectedComponent: "Battery",
                suggestedAction: generateBatteryOptimizationAction(snapshot),
                timestamp: snapshot.timestamp
            )
        }
        
        return nil
    }
    
    private func detectProcessAnomalies(_ snapshot: SystemSnapshot) -> [SystemAnomaly] {
        var anomalies: [SystemAnomaly] = []
        
        // Detect runaway processes
        for process in snapshot.cpuProcesses {
            if process.cpuUsage > 80 && !isKnownHighCPUProcess(process.displayName) {
                anomalies.append(SystemAnomaly(
                    type: .runawayProcess,
                    severity: .warning,
                    title: "High CPU Process",
                    description: "\(process.displayName) is using \(String(format: "%.1f", process.cpuUsage))% CPU",
                    affectedComponent: "Process: \(process.displayName)",
                    suggestedAction: "Consider restarting \(process.displayName) if it continues to use high CPU",
                    timestamp: snapshot.timestamp
                ))
            }
        }
        
        return anomalies
    }
    
    // MARK: - Performance Scoring
    private func calculatePerformanceScore(_ snapshot: SystemSnapshot) async {
        var score: Double = 100.0
        
        // CPU score (30% weight)
        let cpuScore = calculateCPUScore(snapshot)
        score -= (100 - cpuScore) * 0.3
        
        // Memory score (30% weight)
        let memoryScore = calculateMemoryScore(snapshot)
        score -= (100 - memoryScore) * 0.3
        
        // Battery score (20% weight)
        let batteryScore = calculateBatteryScore(snapshot)
        score -= (100 - batteryScore) * 0.2
        
        // System responsiveness (20% weight)
        let responsivenessScore = calculateResponsivenessScore(snapshot)
        score -= (100 - responsivenessScore) * 0.2
        
        performanceScore = max(0, min(100, score))
    }
    
    private func calculateCPUScore(_ snapshot: SystemSnapshot) -> Double {
        let normalUsage = getNormalCPUThreshold(for: currentWorkload)
        
        if snapshot.cpuUsage <= normalUsage {
            return 100.0
        } else {
            let excessUsage = snapshot.cpuUsage - normalUsage
            return max(0, 100 - (excessUsage * 2)) // Deduct 2 points per percent above normal
        }
    }
    
    private func calculateMemoryScore(_ snapshot: SystemSnapshot) -> Double {
        guard let totalMemory = memoryMonitor?.totalMemory else { return 100.0 }
        
        let memoryPercentage = Double(snapshot.memoryUsage) / Double(totalMemory) * 100
        let normalUsage = getNormalMemoryThreshold(for: currentWorkload)
        
        if memoryPercentage <= normalUsage {
            return 100.0
        } else {
            let excessUsage = memoryPercentage - normalUsage
            return max(0, 100 - (excessUsage * 3)) // Deduct 3 points per percent above normal
        }
    }
    
    private func calculateBatteryScore(_ snapshot: SystemSnapshot) -> Double {
        if snapshot.batteryState == .charging {
            return 100.0 // Perfect score when charging
        }
        
        let normalPower = getNormalPowerUsage(for: currentWorkload)
        
        if snapshot.powerUsage <= normalPower {
            return 100.0
        } else {
            let excessPower = snapshot.powerUsage - normalPower
            return max(0, 100 - (excessPower * 5)) // Deduct 5 points per excess watt
        }
    }
    
    private func calculateResponsivenessScore(_ snapshot: SystemSnapshot) -> Double {
        // Based on memory pressure and CPU load balance
        switch snapshot.memoryPressure {
        case .normal:
            return snapshot.cpuUsage < 80 ? 100.0 : 80.0
        case .warning:
            return 60.0
        case .critical:
            return 20.0
        }
    }
    
    // MARK: - Insight Generation
    private func generateInsights(_ snapshot: SystemSnapshot) async {
        var insights: [SystemInsight] = []
        
        // Workload insights
        if let workloadInsight = generateWorkloadInsight(snapshot) {
            insights.append(workloadInsight)
        }
        
        // Performance insights
        if let performanceInsight = generatePerformanceInsight(snapshot) {
            insights.append(performanceInsight)
        }
        
        // Battery insights
        if let batteryInsight = generateBatteryInsight(snapshot) {
            insights.append(batteryInsight)
        }
        
        // System health insights
        if let healthInsight = generateSystemHealthInsight(snapshot) {
            insights.append(healthInsight)
        }
        
        currentInsights = insights
    }
    
    private func generateWorkloadInsight(_ snapshot: SystemSnapshot) -> SystemInsight? {
        guard currentWorkload != .unknown else { return nil }
        
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        let hours = Int(sessionDuration / 3600)
        let minutes = Int((sessionDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        return SystemInsight(
            type: .workloadAnalysis,
            title: "Current Workload: \(currentWorkload.displayName)",
            description: "You've been doing \(currentWorkload.displayName.lowercased()) work for \(hours > 0 ? "\(hours)h " : "")\(minutes)m. System performance is \(getPerformanceDescription()) for this type of work.",
            priority: .medium,
            actionable: false
        )
    }
    
    private func getPerformanceDescription() -> String {
        switch performanceScore {
        case 90...100: return "excellent"
        case 80...89: return "very good"
        case 70...79: return "good"
        case 60...69: return "acceptable"
        case 50...59: return "below average"
        default: return "poor"
        }
    }
    
    // MARK: - Helper Methods
    private func getNormalCPUThreshold(for workload: WorkloadType) -> Double {
        switch workload {
        case .development: return 60.0
        case .design: return 45.0
        case .videoEditing: return 80.0
        case .gaming: return 75.0
        case .browsing: return 25.0
        case .office: return 20.0
        case .unknown: return 40.0
        }
    }
    
    private func getNormalMemoryThreshold(for workload: WorkloadType) -> Double {
        switch workload {
        case .development: return 70.0
        case .design: return 65.0
        case .videoEditing: return 80.0
        case .gaming: return 60.0
        case .browsing: return 40.0
        case .office: return 35.0
        case .unknown: return 50.0
        }
    }
    
    private func getNormalPowerUsage(for workload: WorkloadType) -> Double {
        switch workload {
        case .development: return 15.0
        case .design: return 12.0
        case .videoEditing: return 25.0
        case .gaming: return 30.0
        case .browsing: return 8.0
        case .office: return 6.0
        case .unknown: return 10.0
        }
    }
    
    private func isKnownHighCPUProcess(_ name: String) -> Bool {
        let knownHighCPUProcesses = [
            "kernel_task", "Xcode", "Final Cut Pro", "Adobe Premiere",
            "Compressor", "HandBrake", "Cinema 4D", "Blender"
        ]
        return knownHighCPUProcesses.contains { name.contains($0) }
    }
    
    // MARK: - Optimization and Insight Methods
    private func generateOptimizations(_ snapshot: SystemSnapshot) async {
        var suggestions: [OptimizationSuggestion] = []
        
        // CPU optimization suggestions
        if snapshot.cpuUsage > getNormalCPUThreshold(for: currentWorkload) {
            suggestions.append(OptimizationSuggestion(
                title: "High CPU Usage Detected",
                description: "CPU usage is \(String(format: "%.1f", snapshot.cpuUsage))% - consider closing resource-intensive applications",
                impact: .high,
                effort: .easy,
                category: .cpu,
                action: { /* Could implement app closure logic */ }
            ))
        }
        
        // Memory optimization suggestions
        if let totalMemory = memoryMonitor?.totalMemory {
            let memoryPercentage = Double(snapshot.memoryUsage) / Double(totalMemory) * 100
            if memoryPercentage > getNormalMemoryThreshold(for: currentWorkload) {
                suggestions.append(OptimizationSuggestion(
                    title: "High Memory Usage",
                    description: "Memory usage is \(String(format: "%.1f", memoryPercentage))% - restart memory-intensive apps or close browser tabs",
                    impact: .medium,
                    effort: .easy,
                    category: .memory,
                    action: { /* Could implement memory cleanup */ }
                ))
            }
        }
        
        // Battery optimization suggestions
        if snapshot.powerUsage > getNormalPowerUsage(for: currentWorkload) * 1.3 {
            suggestions.append(OptimizationSuggestion(
                title: "High Power Usage",
                description: "Power consumption is \(String(format: "%.1f", snapshot.powerUsage))W - reduce screen brightness or close power-hungry apps",
                impact: .medium,
                effort: .easy,
                category: .battery,
                action: { /* Could implement power optimization */ }
            ))
        }
        
        optimizationSuggestions = suggestions
    }
    
    private func generateCPUOptimizationAction(_ snapshot: SystemSnapshot) -> String {
        return "Close unnecessary applications or check for runaway processes in Activity Monitor"
    }
    
    private func generateMemoryOptimizationAction(_ snapshot: SystemSnapshot) -> String {
        return "Close unused browser tabs or restart memory-intensive applications"
    }
    
    private func generateBatteryOptimizationAction(_ snapshot: SystemSnapshot) -> String {
        return "Reduce screen brightness or close power-intensive applications"
    }
    
    private func generatePerformanceInsight(_ snapshot: SystemSnapshot) -> SystemInsight? {
        // Generate performance insights based on current state
        if performanceScore < 70 {
            return SystemInsight(
                type: .performanceOptimization,
                title: "Performance Below Optimal",
                description: "System performance score is \(Int(performanceScore))/100. Consider optimizing resource usage.",
                priority: .high,
                actionable: true
            )
        } else if performanceScore < 85 {
            return SystemInsight(
                type: .performanceOptimization,
                title: "Performance Could Be Improved", 
                description: "System performance score is \(Int(performanceScore))/100. Some optimization opportunities available.",
                priority: .medium,
                actionable: true
            )
        }
        return nil
    }
    
    private func generateBatteryInsight(_ snapshot: SystemSnapshot) -> SystemInsight? {
        // Generate battery insights
        if snapshot.batteryLevel < 20 && snapshot.batteryState != .charging {
            return SystemInsight(
                type: .batteryHealth,
                title: "Low Battery Warning",
                description: "Battery level is \(Int(snapshot.batteryLevel))%. Consider connecting to power soon.",
                priority: .high,
                actionable: true
            )
        } else if snapshot.powerUsage > getNormalPowerUsage(for: currentWorkload) * 1.5 {
            return SystemInsight(
                type: .batteryHealth,
                title: "High Power Consumption",
                description: "Power usage (\(String(format: "%.1f", snapshot.powerUsage))W) is higher than normal for \(currentWorkload.displayName) workload.",
                priority: .medium,
                actionable: true
            )
        }
        return nil
    }
    
    private func generateSystemHealthInsight(_ snapshot: SystemSnapshot) -> SystemInsight? {
        // Generate overall system health insights
        let anomalyCount = activeAnomalies.count
        if anomalyCount > 2 {
            return SystemInsight(
                type: .systemHealth,
                title: "Multiple System Issues Detected",
                description: "\(anomalyCount) system anomalies are currently active. Review system performance recommendations.",
                priority: .critical,
                actionable: true
            )
        } else if anomalyCount > 0 {
            return SystemInsight(
                type: .systemHealth,
                title: "System Issue Detected",
                description: "\(anomalyCount) system anomaly detected. Monitor system performance.",
                priority: .medium,
                actionable: true
            )
        }
        return nil
    }
    
    private func updateSessionMemory(_ snapshot: SystemSnapshot) async {
        // Update session memory with current snapshot
        sessionMemory.addSnapshot(snapshot)
    }
    
    private func determineSystemPersonality(_ snapshot: SystemSnapshot) -> SystemPersonality {
        // Determine system personality based on hardware and usage patterns
        return .balanced
    }
}

// MARK: - Supporting Types
struct SystemSnapshot {
    let timestamp: Date
    let cpuUsage: Double
    let cpuCoreUsage: [Double]
    let cpuTemperature: Double
    let cpuProcesses: [ProcessInfo]
    let memoryUsage: UInt64
    let memoryPressure: MemoryPressure
    let memoryProcesses: [MemoryProcessInfo]
    let batteryLevel: Double
    let batteryState: BatteryState
    let powerUsage: Double
    let runningApplications: [RunningApplication]
}

struct RunningApplication {
    let name: String
    let bundleIdentifier: String
    let pid: Int
    let isActive: Bool
    let isHidden: Bool
}

enum WorkloadType: String, CaseIterable {
    case development = "Development"
    case design = "Design"
    case videoEditing = "Video Editing"
    case gaming = "Gaming"
    case browsing = "Web Browsing"
    case office = "Office Work"
    case unknown = "Unknown"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .development: return "hammer.fill"
        case .design: return "paintbrush.fill"
        case .videoEditing: return "video.fill"
        case .gaming: return "gamecontroller.fill"
        case .browsing: return "safari.fill"
        case .office: return "doc.text.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .development: return .blue
        case .design: return .purple
        case .videoEditing: return .red
        case .gaming: return .green
        case .browsing: return .orange
        case .office: return .gray
        case .unknown: return .secondary
        }
    }
}

enum SystemPersonality {
    case performanceFirst
    case balanced
    case batteryFirst
    case quiet
    
    var displayName: String {
        switch self {
        case .performanceFirst: return "Performance First"
        case .balanced: return "Balanced"
        case .batteryFirst: return "Battery First"
        case .quiet: return "Quiet & Cool"
        }
    }
}

struct WorkloadDetection {
    let timestamp: Date
    let workload: WorkloadType
    let confidence: Double
}

struct PerformanceSnapshot {
    let timestamp: Date
    let score: Double
    let cpuScore: Double
    let memoryScore: Double
    let batteryScore: Double
    let responsivenessScore: Double
}

struct UserInteraction {
    let timestamp: Date
    let action: String
    let context: String
}

struct SystemInsight {
    let type: InsightType
    let title: String
    let description: String
    let priority: Priority
    let actionable: Bool
    
    enum InsightType {
        case workloadAnalysis
        case performanceOptimization
        case batteryHealth
        case systemHealth
        case userBehavior
    }
    
    enum Priority {
        case low, medium, high, critical
        
        var color: Color {
            switch self {
            case .low: return .secondary
            case .medium: return .blue
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
}

struct OptimizationSuggestion {
    let title: String
    let description: String
    let impact: Impact
    let effort: Effort
    let category: Category
    let action: () -> Void
    
    enum Impact {
        case low, medium, high
        
        var displayText: String {
            switch self {
            case .low: return "Low Impact"
            case .medium: return "Medium Impact"
            case .high: return "High Impact"
            }
        }
        
        var color: Color {
            switch self {
            case .low: return .secondary
            case .medium: return .orange
            case .high: return .green
            }
        }
    }
    
    enum Effort {
        case easy, moderate, complex
        
        var displayText: String {
            switch self {
            case .easy: return "Easy"
            case .moderate: return "Moderate"
            case .complex: return "Complex"
            }
        }
    }
    
    enum Category {
        case cpu, memory, battery, storage, network
        
        var icon: String {
            switch self {
            case .cpu: return "cpu"
            case .memory: return "memorychip"
            case .battery: return "battery.100"
            case .storage: return "internaldrive"
            case .network: return "network"
            }
        }
    }
}

struct SystemAnomaly {
    let type: AnomalyType
    let severity: Severity
    let title: String
    let description: String
    let affectedComponent: String
    let suggestedAction: String
    let timestamp: Date
    
    enum AnomalyType {
        case cpuSpike
        case memoryPressure
        case unusualPowerDrain
        case runawayProcess
        case thermalThrottling
        case diskIOBottleneck
    }
    
    enum Severity {
        case info, warning, critical
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
    }
}

struct SessionMemory {
    private var snapshots: [SystemSnapshot] = []
    private let maxSnapshots = 720 // 1 hour of 5-second intervals
    
    mutating func addSnapshot(_ snapshot: SystemSnapshot) {
        snapshots.append(snapshot)
        
        // Keep only recent snapshots
        if snapshots.count > maxSnapshots {
            snapshots.removeFirst(snapshots.count - maxSnapshots)
        }
    }
    
    func getRecentSnapshots(minutes: Int = 10) -> [SystemSnapshot] {
        let cutoffTime = Date().addingTimeInterval(-Double(minutes * 60))
        return snapshots.filter { $0.timestamp > cutoffTime }
    }
    
    func getAverageCPUUsage(minutes: Int = 10) -> Double {
        let recent = getRecentSnapshots(minutes: minutes)
        guard !recent.isEmpty else { return 0.0 }
        
        let total = recent.reduce(0.0) { $0 + $1.cpuUsage }
        return total / Double(recent.count)
    }
    
    func getAverageMemoryUsage(minutes: Int = 10) -> UInt64 {
        let recent = getRecentSnapshots(minutes: minutes)
        guard !recent.isEmpty else { return 0 }
        
        let total = recent.reduce(UInt64(0)) { $0 + $1.memoryUsage }
        return total / UInt64(recent.count)
    }
    
    func getAveragePowerUsage(minutes: Int = 10) -> Double {
        let recent = getRecentSnapshots(minutes: minutes)
        guard !recent.isEmpty else { return 0.0 }
        
        let total = recent.reduce(0.0) { $0 + $1.powerUsage }
        return total / Double(recent.count)
    }
}
