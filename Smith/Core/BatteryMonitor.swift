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
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
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
                
                // Update main battery info if this is the main battery
                if source.type == "InternalBattery" {
                    batteryLevel = Double(source.currentCapacity)
                    isCharging = source.isCharging
                    batteryState = source.batteryState
                }
            }
        }
        
        self.powerSources = sources
    }
    
    func analyzeBatteryHealth() -> String {
        guard let mainBattery = powerSources.first(where: { $0.type == "InternalBattery" }) else {
            return "No internal battery found. This Mac may be a desktop model."
        }
        
        var analysis = "🔋 Battery Health Analysis:\n\n"
        
        // Battery level analysis
        switch batteryLevel {
        case 80...100:
            analysis += "✅ Battery level is excellent (\(Int(batteryLevel))%)\n"
        case 50...79:
            analysis += "⚠️ Battery level is moderate (\(Int(batteryLevel))%)\n"
        case 20...49:
            analysis += "🟡 Battery level is low (\(Int(batteryLevel))%)\n"
        case 0...19:
            analysis += "🔴 Battery level is critically low (\(Int(batteryLevel))%)\n"
        default:
            analysis += "❓ Battery level unknown\n"
        }
        
        // Charging status
        if isCharging {
            analysis += "🔌 Currently charging\n"
        } else {
            analysis += "🔋 Running on battery power\n"
        }
        
        // Battery health
        let healthPercentage = mainBattery.maxCapacity > 0 ? 
            Double(mainBattery.currentCapacity) / Double(mainBattery.maxCapacity) * 100 : 0
        
        switch healthPercentage {
        case 90...100:
            analysis += "💚 Battery health is excellent (\(String(format: "%.1f", healthPercentage))%)\n"
        case 80...89:
            analysis += "💛 Battery health is good (\(String(format: "%.1f", healthPercentage))%)\n"
        case 70...79:
            analysis += "🧡 Battery health is fair (\(String(format: "%.1f", healthPercentage))%)\n"
        default:
            analysis += "❤️ Battery health needs attention (\(String(format: "%.1f", healthPercentage))%)\n"
        }
        
        analysis += "\n💡 Battery Optimization Tips:\n"
        
        if batteryLevel < 20 {
            analysis += "• Connect to power immediately\n"
        }
        
        if !isCharging && batteryLevel < 50 {
            analysis += "• Consider enabling Low Power Mode\n"
        }
        
        analysis += "• Close unnecessary applications\n"
        analysis += "• Reduce screen brightness\n"
        analysis += "• Disable Bluetooth/WiFi if not needed\n"
        analysis += "• Check Activity Monitor for high-energy apps\n"
        
        if healthPercentage < 80 {
            analysis += "• Consider battery replacement\n"
            analysis += "• Avoid extreme temperatures\n"
            analysis += "• Don't let battery drain completely\n"
        }
        
        return analysis
    }
    
    func analyzeHighEnergyApps() -> String {
        var analysis = "⚡ High Energy App Analysis:\n\n"
        
        // Get running applications (simplified version)
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        var energyIntensiveApps: [String] = []
        
        for app in runningApps {
            let name = app.localizedName ?? app.bundleIdentifier ?? "Unknown"
            
            // Common energy-intensive applications
            switch name.lowercased() {
            case let appName where appName.contains("chrome"):
                energyIntensiveApps.append("Google Chrome - Multiple tabs can drain battery quickly")
            case let appName where appName.contains("firefox"):
                energyIntensiveApps.append("Firefox - Video streaming increases power usage")
            case let appName where appName.contains("zoom"):
                energyIntensiveApps.append("Zoom - Video calls are battery intensive")
            case let appName where appName.contains("teams"):
                energyIntensiveApps.append("Microsoft Teams - Video conferencing drains battery")
            case let appName where appName.contains("photoshop"):
                energyIntensiveApps.append("Adobe Photoshop - Graphics processing uses significant power")
            case let appName where appName.contains("final cut"):
                energyIntensiveApps.append("Final Cut Pro - Video editing is very power hungry")
            case let appName where appName.contains("xcode"):
                energyIntensiveApps.append("Xcode - Code compilation uses CPU intensively")
            case let appName where appName.contains("spotify"):
                energyIntensiveApps.append("Spotify - Audio streaming and background processes")
            default:
                continue
            }
        }
        
        if energyIntensiveApps.isEmpty {
            analysis += "✅ No known high-energy applications are currently running.\n"
        } else {
            analysis += "The following energy-intensive applications are running:\n\n"
            for app in energyIntensiveApps {
                analysis += "• \(app)\n"
            }
        }
        
        analysis += "\n💡 Energy Saving Recommendations:\n"
        analysis += "• Close unused browser tabs\n"
        analysis += "• Pause video streaming when not actively watching\n"
        analysis += "• Use Safari instead of Chrome for better battery life\n"
        analysis += "• Enable automatic graphics switching\n"
        analysis += "• Turn off background app refresh\n"
        analysis += "• Use wired headphones instead of Bluetooth\n"
        
        return analysis
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
        case .discharging: return "Discharging"
        case .full: return "Full"
        case .unknown: return "Unknown"
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
        self.isCharging = powerSourceState == "AC Power"
        
        if isCharging {
            self.batteryState = .charging
        } else if currentCapacity >= maxCapacity {
            self.batteryState = .full
        } else if currentCapacity > 0 {
            self.batteryState = .discharging
        } else {
            self.batteryState = .unknown
        }
    }
}