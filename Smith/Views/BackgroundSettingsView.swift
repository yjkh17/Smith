//
//  BackgroundSettingsView.swift
//  Smith - Background Monitoring Settings
//
//  Phase 3: Deep System Integration
//  Created by AI Assistant on 17/06/2025.
//

import SwiftUI

struct BackgroundSettingsView: View {
    @StateObject private var launchAgent = LaunchAgentManager()
    @StateObject private var backgroundService = BackgroundMonitorService()
    @State private var showingInstallConfirmation = false
    @State private var showingUninstallConfirmation = false
    @State private var lastStatsLoadTime: Date?
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "gear.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text("Background Monitoring")
                                .font(.headline)
                            Text("Keep Smith monitoring your system even when the app is closed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        StatusIndicator(isActive: launchAgent.backgroundMonitoringEnabled)
                    }
                    
                    if !launchAgent.isLaunchAgentInstalled {
                        InstallBackgroundMonitoringCard(launchAgent: launchAgent,
                                                      showingConfirmation: $showingInstallConfirmation)
                    } else {
                        BackgroundMonitoringControls(launchAgent: launchAgent,
                                                   backgroundService: backgroundService,
                                                   showingUninstallConfirmation: $showingUninstallConfirmation)
                    }
                }
                .padding(.vertical, Spacing.small)
            }
            
            if launchAgent.isLaunchAgentInstalled {
                Section("Monitoring Intensity") {
                    IntensitySelector(launchAgent: launchAgent)
                }
                
                Section("Background Statistics") {
                    BackgroundStatsView(backgroundService: backgroundService,
                                      lastStatsLoadTime: $lastStatsLoadTime)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Background Monitoring")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh") {
                    backgroundService.performManualCheck()
                    lastStatsLoadTime = Date()
                }
                .disabled(!launchAgent.backgroundMonitoringEnabled)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatusIndicator: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(isActive ? "Active" : "Inactive")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct InstallBackgroundMonitoringCard: View {
    @ObservedObject var launchAgent: LaunchAgentManager
    @Binding var showingConfirmation: Bool
    @State private var isInstalling = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                
                Text("Background monitoring is not installed")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Text("Install a LaunchAgent to enable continuous system monitoring even when Smith is not running.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Install Background Monitoring") {
                    showingConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(isInstalling)
                
                if isInstalling {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        .confirmationDialog("Install Background Monitoring",
                          isPresented: $showingConfirmation,
                          titleVisibility: .visible) {
            Button("Install") {
                installBackgroundMonitoring()
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will install a LaunchAgent that allows Smith to monitor your system in the background. You can uninstall it at any time.")
        }
    }
    
    private func installBackgroundMonitoring() {
        isInstalling = true
        
        Task {
            let success = await launchAgent.installLaunchAgent()
            
            await MainActor.run {
                isInstalling = false
                
                if success {
                    // Automatically enable background monitoring after installation
                    Task {
                        await launchAgent.toggleBackgroundMonitoring()
                    }
                }
            }
        }
    }
}

struct BackgroundMonitoringControls: View {
    @ObservedObject var launchAgent: LaunchAgentManager
    @ObservedObject var backgroundService: BackgroundMonitorService
    @Binding var showingUninstallConfirmation: Bool
    @State private var isToggling = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Enable Background Monitoring", isOn: .constant(launchAgent.backgroundMonitoringEnabled))
                    .disabled(isToggling)
                    .onChange(of: launchAgent.backgroundMonitoringEnabled) { oldValue, newValue in
                        if oldValue != newValue {
                            toggleBackgroundMonitoring()
                        }
                    }
                
                if isToggling {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if launchAgent.backgroundMonitoringEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        if let lastUpdate = backgroundService.lastUpdateTime {
                            Text("Last update: \(lastUpdate, style: .relative) ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Monitoring active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Updates every \(formattedInterval(launchAgent.backgroundIntensity.updateInterval))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Button("Uninstall") {
                    showingUninstallConfirmation = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                Spacer()
            }
        }
        .confirmationDialog("Uninstall Background Monitoring",
                          isPresented: $showingUninstallConfirmation,
                          titleVisibility: .visible) {
            Button("Uninstall", role: .destructive) {
                uninstallBackgroundMonitoring()
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove the LaunchAgent and stop all background monitoring. You can reinstall it later if needed.")
        }
    }
    
    private func toggleBackgroundMonitoring() {
        isToggling = true
        
        Task {
            await launchAgent.toggleBackgroundMonitoring()
            
            await MainActor.run {
                isToggling = false
            }
        }
    }
    
    private func uninstallBackgroundMonitoring() {
        isToggling = true
        
        Task {
            _ = await launchAgent.uninstallLaunchAgent()
            
            await MainActor.run {
                isToggling = false
            }
        }
    }
    
    private func formattedInterval(_ interval: TimeInterval) -> String {
        if interval < 60 {
            return "\(Int(interval)) seconds"
        } else if interval < 3600 {
            return "\(Int(interval / 60)) minutes"
        } else {
            return "\(Int(interval / 3600)) hours"
        }
    }
}

struct IntensitySelector: View {
    @ObservedObject var launchAgent: LaunchAgentManager
    @State private var isChanging = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(BackgroundIntensity.allCases, id: \.rawValue) { intensity in
                HStack {
                    Button {
                        changeIntensity(to: intensity)
                    } label: {
                        HStack {
                            Image(systemName: launchAgent.backgroundIntensity == intensity ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(launchAgent.backgroundIntensity == intensity ? .blue : .gray)
                            
                            VStack(alignment: .leading) {
                                Text(intensity.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(intensity.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isChanging)
                    
                    if isChanging && launchAgent.backgroundIntensity == intensity {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.vertical, Spacing.xsmall)
            }
        }
    }
    
    private func changeIntensity(to intensity: BackgroundIntensity) {
        guard intensity != launchAgent.backgroundIntensity else { return }
        
        isChanging = true
        
        Task {
            await launchAgent.setBackgroundIntensity(intensity)
            
            await MainActor.run {
                isChanging = false
            }
        }
    }
}

struct BackgroundStatsView: View {
    @ObservedObject var backgroundService: BackgroundMonitorService
    @Binding var lastStatsLoadTime: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let stats = backgroundService.backgroundStats {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Latest System Snapshot")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(stats.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        StatCard(title: "CPU", value: "\(String(format: "%.1f", stats.cpuUsage))%", 
                                icon: "cpu", color: stats.cpuUsage > 80 ? .red : .blue)
                        
                        StatCard(title: "Memory", value: "\(String(format: "%.1f", stats.memoryUsage))%", 
                                icon: "memorychip", color: stats.memoryUsage > 85 ? .red : .green)
                        
                        StatCard(title: "Battery", value: "\(String(format: "%.0f", stats.batteryLevel))%", 
                                icon: "battery.100", color: stats.batteryLevel < 20 ? .red : .green)
                        
                        if let temp = stats.cpuTemperature {
                            StatCard(title: "Temp", value: "\(String(format: "%.0f", temp))°C", 
                                    icon: "thermometer", color: temp > 80 ? .red : .blue)
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.gray)
                    
                    Text("No background statistics available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
                .background(Color.panelBackground)
                .cornerRadius(8)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Spacer()
            }
        }
        .padding(Spacing.small)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

#Preview {
    NavigationView {
        BackgroundSettingsView()
    }
    .frame(width: 600, height: 800)
}