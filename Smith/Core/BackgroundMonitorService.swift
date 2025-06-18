//
//  BackgroundMonitorService.swift
//  Smith - Background System Monitoring Service
//
//  Phase 3: Deep System Integration
//  Created by AI Assistant on 17/06/2025.
//

import Foundation
import Combine
import os.log
import AppKit
import UserNotifications

/// Background service that performs system monitoring when app is not actively used
@MainActor
final class BackgroundMonitorService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var isRunning = false
    @Published var lastUpdateTime: Date?
    @Published var backgroundStats: BackgroundSystemStats?

    private let logger = Logger(subsystem: "com.motherofbrand.Smith", category: "BackgroundMonitor")
    private var monitoringTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // Location to store the most recent stats on disk
    private let statsFileURL: URL = {
        let supportDir = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Smith", isDirectory: true)
        return supportDir.appendingPathComponent("background_stats.json")
    }()
    
    // Core monitors
    private let cpuMonitor: CPUMonitor
    private let memoryMonitor: MemoryMonitor
    private let batteryMonitor: BatteryMonitor
    
    // Background monitoring settings
    private var intensity: BackgroundIntensity = .balanced
    private var monitoringInterval: TimeInterval = 60
    
    // MARK: - Initialization
    
    init() {
        self.cpuMonitor = CPUMonitor()
        self.memoryMonitor = MemoryMonitor()
        self.batteryMonitor = BatteryMonitor()

        createStatsDirectory()
        loadSavedStats()

        setupNotificationObservers()
        checkBackgroundModeArguments()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring(intensity: BackgroundIntensity = .balanced) {
        guard !isRunning else { return }
        
        self.intensity = intensity
        self.monitoringInterval = intensity.updateInterval
        
        logger.info("Starting background monitoring with \(intensity.displayName) intensity")
        
        isRunning = true
        scheduleMonitoring()
        
        // Immediate monitoring run
        Task {
            await performMonitoringCycle()
        }
    }
    
    func stopMonitoring() async {
        guard isRunning else { return }
        
        logger.info("Stopping background monitoring")
        
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isRunning = false
    }
    
    func performManualCheck() {
        logger.info("Performing manual background check")
        Task {
            await performMonitoringCycle()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        // Listen for app termination
        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleAppTermination()
                }
            }
            .store(in: &cancellables)
        
        // Listen for system sleep/wake
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleSystemSleep()
                }
            }
            .store(in: &cancellables)
        
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleSystemWake()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkBackgroundModeArguments() {
        let arguments = CommandLine.arguments
        
        if arguments.contains("--background-monitor") {
            logger.info("App launched in background monitor mode")
            
            // Parse intensity argument
            if let intensityArg = arguments.first(where: { $0.hasPrefix("--intensity=") }),
               let intensityValue = intensityArg.split(separator: "=").last,
               let intensity = BackgroundIntensity(rawValue: String(intensityValue)) {
                startMonitoring(intensity: intensity)
            } else {
                startMonitoring(intensity: .balanced)
            }
            
            // Set up auto-termination after monitoring cycle in background mode
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                // Simple environment check without complex ProcessInfo usage
                if let envValue = getenv("SMITH_BACKGROUND_MODE"), String(cString: envValue) == "1" {
                    self.logger.info("Background monitoring cycle complete, terminating")
                    exit(0)
                }
            }
        }
    }

    private func createStatsDirectory() {
        let directory = statsFileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create stats directory: \(error.localizedDescription)")
        }
    }

    private func loadSavedStats() {
        guard FileManager.default.fileExists(atPath: statsFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: statsFileURL)
            let stats = try JSONDecoder().decode(BackgroundSystemStats.self, from: data)
            backgroundStats = stats
            lastUpdateTime = stats.timestamp
        } catch {
            logger.error("Failed to load saved stats: \(error.localizedDescription)")
        }
    }
    
    private func scheduleMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performMonitoringCycle()
            }
        }
    }
    
    private func performMonitoringCycle() async {
        let startTime = Date()
        logger.info("Starting monitoring cycle")
        
        do {
            let stats = try await collectSystemStats()
            
            self.backgroundStats = stats
            self.lastUpdateTime = Date()
            
            try await saveStatsToFile(stats)
            try await checkForAnomalies(stats)
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Monitoring cycle completed in \(String(format: "%.2f", duration))s")
            
        } catch {
            logger.error("Error during monitoring cycle: \(error.localizedDescription)")
        }
    }
    
    private func collectSystemStats() async throws -> BackgroundSystemStats {
        let cpuUsage = cpuMonitor.cpuUsage
        let cpuTemp = cpuMonitor.temperature
        let memoryUsage = (Double(memoryMonitor.usedMemory) / Double(memoryMonitor.totalMemory)) * 100.0
        let memoryPressure = memoryMonitor.memoryPressure.description
        let batteryLevel = batteryMonitor.batteryLevel
        let batteryHealth = batteryMonitor.getBatteryHealthRating().0 == "Excellent" ? 100.0 : 
                           batteryMonitor.getBatteryHealthRating().0 == "Good" ? 80.0 :
                           batteryMonitor.getBatteryHealthRating().0 == "Fair" ? 60.0 : 40.0
        let isPluggedIn = batteryMonitor.isCharging
        
        return BackgroundSystemStats(
            timestamp: Date(),
            cpuUsage: cpuUsage,
            cpuTemperature: cpuTemp,
            memoryUsage: memoryUsage,
            memoryPressure: memoryPressure,
            batteryLevel: batteryLevel,
            batteryHealth: batteryHealth,
            isPluggedIn: isPluggedIn,
            intensity: intensity
        )
    }
    
    private func saveStatsToFile(_ stats: BackgroundSystemStats) async throws {
        logger.info("Background stats: CPU: \(String(format: "%.1f", stats.cpuUsage))%, Memory: \(String(format: "%.1f", stats.memoryUsage))%, Battery: \(String(format: "%.0f", stats.batteryLevel))%")
        do {
            let data = try JSONEncoder().encode(stats)
            try data.write(to: statsFileURL, options: [.atomic])
        } catch {
            logger.error("Failed to save stats: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func checkForAnomalies(_ stats: BackgroundSystemStats) async throws {
        var alerts: [String] = []
        
        // Check for high CPU usage
        if stats.cpuUsage > 80 {
            alerts.append("High CPU usage detected: \(String(format: "%.1f", stats.cpuUsage))%")
        }
        
        // Check for high memory usage
        if stats.memoryUsage > 85 {
            alerts.append("High memory usage detected: \(String(format: "%.1f", stats.memoryUsage))%")
        }
        
        // Check for critical battery level
        if !stats.isPluggedIn && stats.batteryLevel < 20 {
            alerts.append("Low battery: \(String(format: "%.0f", stats.batteryLevel))%")
        }
        
        // Check for high temperature (if available)
        if let temp = stats.cpuTemperature, temp > 80 {
            alerts.append("High CPU temperature: \(String(format: "%.1f", temp))°C")
        }
        
        // Send notifications for critical issues
        if !alerts.isEmpty {
            await sendBackgroundNotifications(alerts)
        }
    }
    
    private func sendBackgroundNotifications(_ alerts: [String]) async {
        for alert in alerts {
            let notification = UNMutableNotificationContent()
            notification.title = "Smith System Alert"
            notification.body = alert
            notification.sound = .default
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: notification,
                trigger: nil
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                logger.info("Sent background notification: \(alert)")
            } catch {
                logger.error("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleAppTermination() async {
        logger.info("App terminating, stopping background monitoring")
        await stopMonitoring()
    }
    
    private func handleSystemSleep() async {
        logger.info("System going to sleep, pausing monitoring")
        monitoringTimer?.invalidate()
    }
    
    private func handleSystemWake() async {
        logger.info("System woke up, resuming monitoring")
        if isRunning {
            scheduleMonitoring()
            await performMonitoringCycle()
        }
    }
}

// MARK: - Background System Stats Model

struct BackgroundSystemStats: Codable, Sendable {
    let timestamp: Date
    let cpuUsage: Double
    let cpuTemperature: Double?
    let memoryUsage: Double
    let memoryPressure: String
    let batteryLevel: Double
    let batteryHealth: Double
    let isPluggedIn: Bool
    let intensityRawValue: String
    
    var intensity: BackgroundIntensity {
        return BackgroundIntensity(rawValue: intensityRawValue) ?? .balanced
    }
    
    init(timestamp: Date, cpuUsage: Double, cpuTemperature: Double?, 
         memoryUsage: Double, memoryPressure: String, batteryLevel: Double, 
         batteryHealth: Double, isPluggedIn: Bool, 
         intensity: BackgroundIntensity) {
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.cpuTemperature = cpuTemperature
        self.memoryUsage = memoryUsage
        self.memoryPressure = memoryPressure
        self.batteryLevel = batteryLevel
        self.batteryHealth = batteryHealth
        self.isPluggedIn = isPluggedIn
        self.intensityRawValue = intensity.rawValue
    }
}
