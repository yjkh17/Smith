//
//  BatteryMonitor.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import Foundation
import SwiftUI
import Combine
import IOKit.ps

@MainActor
class BatteryMonitor: ObservableObject {
    @Published var batteryLevel: Double = 0.0
    @Published var batteryState: BatteryState = .unknown
    @Published var isCharging = false
    @Published var powerSources: [PowerSourceInfo] = []
    @Published var isMonitoring = false
    @Published var cycleCount: Int = 0
    @Published var designCapacity: Int = 0
    @Published var currentMaxCapacity: Int = 0
    @Published var temperature: Double = 0.0
    @Published var voltage: Double = 0.0
    @Published var amperage: Int = 0
    @Published var powerUsage: Double = 0.0
    @Published var timeRemaining: String = ""
    @Published var healthCondition: String = ""
    
    nonisolated(unsafe) private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateBatteryInfo()
            }
        }
        
        // Initial update
        updateBatteryInfo()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    private func updateBatteryInfo() {
        let powerSourceInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let powerSources = IOPSCopyPowerSourcesList(powerSourceInfo)?.takeRetainedValue() as? [CFDictionary] ?? []
        
        var sources: [PowerSourceInfo] = []
        
        for powerSource in powerSources {
            if let info = powerSource as? [String: Any] {
                let source = PowerSourceInfo(from: info)
                sources.append(source)
                
                // Update main battery info if this is the internal battery
                if source.type == "InternalBattery" {
                    batteryLevel = Double(source.currentCapacity)
                    isCharging = source.isCharging
                    batteryState = source.batteryState
                    
                    // Extract additional battery details
                    if let cycleCount = info["CycleCount"] as? Int {
                        self.cycleCount = cycleCount
                    }
                    
                    if let designCapacity = info["DesignCapacity"] as? Int {
                        self.designCapacity = designCapacity
                    }
                    
                    if let maxCapacity = info["MaxCapacity"] as? Int {
                        self.currentMaxCapacity = maxCapacity
                    }
                    
                    if let temperature = info["Temperature"] as? Double {
                        self.temperature = temperature / 100.0 // Convert from centikelvin to Celsius
                    }
                    
                    if let voltage = info["Voltage"] as? Double {
                        self.voltage = voltage / 1000.0 // Convert from mV to V
                    }
                    
                    if let amperage = info["Amperage"] as? Int {
                        self.amperage = amperage
                    }
                    
                    // Calculate power usage (Watts = Volts × Amps)
                    if voltage > 0 && amperage != 0 {
                        powerUsage = abs(voltage * Double(amperage) / 1000.0) // Convert to Watts
                    }
                    
                    // Time remaining calculation
                    if let timeToEmpty = info["TimeToEmpty"] as? Int, timeToEmpty > 0 {
                        timeRemaining = formatTimeRemaining(minutes: timeToEmpty)
                    } else if let timeToFull = info["TimeToFullCharge"] as? Int, timeToFull > 0 {
                        timeRemaining = "Until full: \(formatTimeRemaining(minutes: timeToFull))"
                    } else {
                        timeRemaining = isCharging ? "Calculating..." : "Unknown"
                    }
                    
                    // Health condition
                    if let condition = info["BatteryHealthCondition"] as? String {
                        healthCondition = condition
                    } else {
                        // Calculate health based on capacity
                        let healthPercentage = designCapacity > 0 ? 
                            Double(currentMaxCapacity) / Double(designCapacity) * 100 : 100
                        
                        switch healthPercentage {
                        case 90...100:
                            healthCondition = "Normal"
                        case 80...89:
                            healthCondition = "Good"
                        case 70...79:
                            healthCondition = "Fair"
                        default:
                            healthCondition = "Service Recommended"
                        }
                    }
                }
            }
        }
        
        self.powerSources = sources
    }
    
    private func formatTimeRemaining(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
    
    func analyzeBatteryHealth() -> String {
        guard powerSources.first(where: { $0.type == "InternalBattery" }) != nil else {
            return "💻 No internal battery detected. This appears to be a desktop Mac or an external power source only."
        }
        
        var analysis = "🔋 Comprehensive Battery Analysis:\n\n"
        
        // Current status
        analysis += "📊 Current Status:\n"
        analysis += "• Battery Level: \(Int(batteryLevel))%\n"
        analysis += "• State: \(batteryState.description)\n"
        
        if isCharging {
            analysis += "• Power Input: \(String(format: "%.1f", powerUsage))W\n"
            if !timeRemaining.isEmpty && timeRemaining != "Calculating..." {
                analysis += "• \(timeRemaining)\n"
            }
        } else {
            analysis += "• Power Draw: \(String(format: "%.1f", powerUsage))W\n"
            if !timeRemaining.isEmpty && timeRemaining != "Unknown" {
                analysis += "• Time Remaining: \(timeRemaining)\n"
            }
        }
        
        analysis += "\n🏥 Battery Health:\n"
        analysis += "• Health Condition: \(healthCondition)\n"
        
        if designCapacity > 0 && currentMaxCapacity > 0 {
            let healthPercentage = Double(currentMaxCapacity) / Double(designCapacity) * 100
            analysis += "• Capacity: \(currentMaxCapacity) mAh of \(designCapacity) mAh (\(String(format: "%.1f", healthPercentage))%)\n"
        }
        
        if cycleCount > 0 {
            analysis += "• Cycle Count: \(cycleCount)\n"
            
            // Cycle count analysis
            switch cycleCount {
            case 0...300:
                analysis += "  → Excellent cycle count\n"
            case 301...600:
                analysis += "  → Good cycle count\n"
            case 601...1000:
                analysis += "  → Moderate cycle count - monitor health\n"
            default:
                analysis += "  → High cycle count - consider replacement\n"
            }
        }
        
        if temperature > 0 {
            analysis += "• Temperature: \(String(format: "%.1f", temperature))°C\n"
            if temperature > 35 {
                analysis += "  → Temperature is elevated\n"
            }
        }
        
        if voltage > 0 {
            analysis += "• Voltage: \(String(format: "%.2f", voltage))V\n"
        }
        
        // Battery level recommendations
        analysis += "\n💡 Optimization Recommendations:\n"
        
        switch batteryLevel {
        case 0...15:
            analysis += "🚨 CRITICAL: Connect to power immediately!\n"
            analysis += "• Enable Low Power Mode\n"
            analysis += "• Close all non-essential applications\n"
            analysis += "• Reduce screen brightness to minimum\n"
        case 16...30:
            analysis += "⚠️ LOW: Consider connecting to power soon\n"
            analysis += "• Enable Low Power Mode\n"
            analysis += "• Close resource-intensive applications\n"
        case 31...50:
            analysis += "📱 MODERATE: Plan for charging within next hour\n"
            analysis += "• Monitor power usage\n"
        case 51...80:
            analysis += "✅ GOOD: Battery level is healthy\n"
        case 81...100:
            analysis += "🔋 EXCELLENT: Battery fully charged\n"
            if isCharging {
                analysis += "• Consider unplugging to preserve battery health\n"
            }
        default:
            break
        }
        
        // General battery health tips
        analysis += "\n🔬 Battery Health Tips:\n"
        
        if healthCondition == "Service Recommended" || cycleCount > 1000 {
            analysis += "• Schedule battery service with Apple\n"
        }
        
        analysis += "• Keep battery between 20-80% when possible\n"
        analysis += "• Avoid extreme temperatures (below 0°C or above 35°C)\n"
        analysis += "• Use Optimized Battery Charging feature\n"
        analysis += "• Calibrate battery monthly (drain to 0%, charge to 100%)\n"
        
        if powerUsage > 20 {
            analysis += "• High power draw detected - check for energy-intensive apps\n"
        }
        
        // Energy efficiency recommendations
        analysis += "\n⚡ Energy Efficiency:\n"
        analysis += "• Use Safari instead of Chrome for better efficiency\n"
        analysis += "• Enable automatic graphics switching\n"
        analysis += "• Turn off keyboard backlight when not needed\n"
        analysis += "• Disable Bluetooth and Wi-Fi when not in use\n"
        analysis += "• Close unused browser tabs and applications\n"
        analysis += "• Use Activity Monitor to identify energy-intensive apps\n"
        
        return analysis
    }
    
    func analyzeHighEnergyApps() -> String {
        var analysis = "⚡ Energy Usage Analysis:\n\n"
        
        // Get running applications
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        var energyIntensiveApps: [(String, String, String)] = [] // (name, reason, priority)
        
        for app in runningApps {
            let name = app.localizedName ?? app.bundleIdentifier ?? "Unknown"
            
            // Categorize applications by energy impact
            switch name.lowercased() {
            case let appName where appName.contains("chrome"):
                energyIntensiveApps.append(("Google Chrome", "Multiple tabs and extensions", "High"))
            case let appName where appName.contains("firefox"):
                energyIntensiveApps.append(("Firefox", "Video streaming and web content", "Medium"))
            case let appName where appName.contains("safari"):
                energyIntensiveApps.append(("Safari", "Web browsing (most efficient browser)", "Low"))
            case let appName where appName.contains("zoom"):
                energyIntensiveApps.append(("Zoom", "Video conferencing with camera/mic", "High"))
            case let appName where appName.contains("teams"):
                energyIntensiveApps.append(("Microsoft Teams", "Video calls and background sync", "High"))
            case let appName where appName.contains("slack"):
                energyIntensiveApps.append(("Slack", "Real-time messaging and notifications", "Medium"))
            case let appName where appName.contains("discord"):
                energyIntensiveApps.append(("Discord", "Voice chat and screen sharing", "Medium"))
            case let appName where appName.contains("photoshop"):
                energyIntensiveApps.append(("Adobe Photoshop", "Graphics processing and filters", "Very High"))
            case let appName where appName.contains("final cut"):
                energyIntensiveApps.append(("Final Cut Pro", "Video editing and rendering", "Very High"))
            case let appName where appName.contains("premiere"):
                energyIntensiveApps.append(("Adobe Premiere", "Video editing and effects", "Very High"))
            case let appName where appName.contains("xcode"):
                energyIntensiveApps.append(("Xcode", "Code compilation and indexing", "High"))
            case let appName where appName.contains("spotify"):
                energyIntensiveApps.append(("Spotify", "Audio streaming and downloads", "Low"))
            case let appName where appName.contains("netflix"):
                energyIntensiveApps.append(("Netflix", "Video streaming", "High"))
            case let appName where appName.contains("youtube"):
                energyIntensiveApps.append(("YouTube", "Video streaming", "Medium"))
            case let appName where appName.contains("virtualbox"), let appName where appName.contains("parallels"), let appName where appName.contains("vmware"):
                energyIntensiveApps.append(("Virtual Machine", "Running another OS", "Very High"))
            case let appName where appName.contains("docker"):
                energyIntensiveApps.append(("Docker", "Container virtualization", "Medium"))
            case let appName where appName.contains("mining"), let appName where appName.contains("crypto"):
                energyIntensiveApps.append(("Cryptocurrency", "Mining or trading", "Extreme"))
            default:
                continue
            }
        }
        
        if energyIntensiveApps.isEmpty {
            analysis += "✅ No significant energy-intensive applications detected.\n\n"
        } else {
            analysis += "📱 Energy-Intensive Applications:\n\n"
            
            // Sort by priority
            let priorityOrder = ["Extreme", "Very High", "High", "Medium", "Low"]
            energyIntensiveApps.sort { app1, app2 in
                let index1 = priorityOrder.firstIndex(of: app1.2) ?? priorityOrder.count
                let index2 = priorityOrder.firstIndex(of: app2.2) ?? priorityOrder.count
                return index1 < index2
            }
            
            for (appName, reason, priority) in energyIntensiveApps {
                let priorityEmoji = priority == "Extreme" ? "🔴" : 
                                  priority == "Very High" ? "🟠" : 
                                  priority == "High" ? "🟡" : 
                                  priority == "Medium" ? "🔵" : "🟢"
                
                analysis += "\(priorityEmoji) \(appName) (\(priority) Impact)\n"
                analysis += "   → \(reason)\n\n"
            }
        }
        
        // Power usage recommendations
        analysis += "💡 Energy Optimization Strategies:\n\n"
        
        analysis += "🌐 Web Browsing:\n"
        analysis += "• Use Safari for best battery life\n"
        analysis += "• Close unused tabs (each tab consumes resources)\n"
        analysis += "• Disable auto-playing videos\n"
        analysis += "• Use content blockers to reduce page complexity\n\n"
        
        analysis += "💻 System Settings:\n"
        analysis += "• Enable 'Automatic graphics switching'\n"
        analysis += "• Reduce display brightness\n"
        analysis += "• Turn off keyboard backlight\n"
        analysis += "• Disable unnecessary visual effects\n"
        analysis += "• Use dark mode (saves power on OLED displays)\n\n"
        
        analysis += "📡 Connectivity:\n"
        analysis += "• Turn off Bluetooth when not needed\n"
        analysis += "• Disable Wi-Fi when using ethernet\n"
        analysis += "• Turn off location services for non-essential apps\n"
        analysis += "• Disable background app refresh\n\n"
        
        analysis += "🎬 Media & Content:\n"
        analysis += "• Download content for offline viewing\n"
        analysis += "• Use lower video quality settings\n"
        analysis += "• Pause streaming when not actively watching\n"
        analysis += "• Use wired headphones instead of Bluetooth\n\n"
        
        analysis += "⚙️ Development & Work:\n"
        analysis += "• Close development servers when not needed\n"
        analysis += "• Pause file syncing services temporarily\n"
        analysis += "• Use energy-efficient IDEs\n"
        analysis += "• Batch compile operations\n"
        
        return analysis
    }
    
    func getPowerUsageRating() -> (String, Color) {
        switch powerUsage {
        case 0..<5:
            return ("Excellent", .green)
        case 5..<10:
            return ("Good", .green)
        case 10..<20:
            return ("Moderate", .orange)
        case 20..<40:
            return ("High", .red)
        default:
            return ("Very High", .red)
        }
    }
    
    func getBatteryHealthRating() -> (String, Color) {
        if designCapacity > 0 && currentMaxCapacity > 0 {
            let healthPercentage = Double(currentMaxCapacity) / Double(designCapacity) * 100
            
            switch healthPercentage {
            case 90...100:
                return ("Excellent", .green)
            case 80...89:
                return ("Good", .green)
            case 70...79:
                return ("Fair", .orange)
            default:
                return ("Poor", .red)
            }
        }
        
        switch healthCondition {
        case "Normal":
            return ("Good", .green)
        case "Service Recommended":
            return ("Poor", .red)
        default:
            return ("Unknown", .gray)
        }
    }
}

enum BatteryState {
    case charging
    case discharging
    case full
    case unknown
    
    var description: String {
        switch self {
        case .charging: return "Charging"
        case .discharging: return "On Battery"
        case .full: return "Full"
        case .unknown: return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .charging: return "battery.100.bolt"
        case .discharging: return "battery.75"
        case .full: return "battery.100"
        case .unknown: return "battery.0"
        }
    }
}

struct PowerSourceInfo {
    let name: String
    let type: String
    let currentCapacity: Int
    let maxCapacity: Int
    let isCharging: Bool
    let batteryState: BatteryState
    
    init(from info: [String: Any]) {
        self.name = info["Name"] as? String ?? "Unknown"
        self.type = info["Type"] as? String ?? "Unknown"
        self.currentCapacity = info["CurrentCapacity"] as? Int ?? 0
        self.maxCapacity = info["MaxCapacity"] as? Int ?? 0
        
        let powerSourceState = info["PowerSourceState"] as? String ?? ""
        let isCharging = powerSourceState == "AC Power"
        self.isCharging = isCharging
        
        if isCharging && currentCapacity >= maxCapacity {
            self.batteryState = .full
        } else if isCharging {
            self.batteryState = .charging
        } else if currentCapacity > 0 {
            self.batteryState = .discharging
        } else {
            self.batteryState = .unknown
        }
    }
}
