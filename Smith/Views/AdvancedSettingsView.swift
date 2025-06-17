//
//  AdvancedSettingsView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 17/06/2025.
//

import SwiftUI

struct AdvancedSettingsView: View {
    @AppStorage("smith.debugMode") private var debugMode = false
    @AppStorage("smith.verboseLogging") private var verboseLogging = false
    @AppStorage("smith.maxLogSize") private var maxLogSize = 100.0
    @AppStorage("smith.cpuThreshold") private var cpuThreshold = 80.0
    @AppStorage("smith.memoryThreshold") private var memoryThreshold = 85.0
    @AppStorage("smith.batteryThreshold") private var batteryThreshold = 20.0
    @AppStorage("smith.enableExperimentalFeatures") private var enableExperimentalFeatures = false
    
    var body: some View {
        Form {
            Section("Debug & Logging") {
                Toggle("Debug Mode", isOn: $debugMode)
                    .help("Enable detailed debugging information")
                
                Toggle("Verbose Logging", isOn: $verboseLogging)
                    .help("Log detailed system monitoring information")
                
                HStack {
                    Text("Max Log Size")
                    Spacer()
                    Slider(value: $maxLogSize, in: 10...500, step: 10) {
                        Text("Max Log Size")
                    }
                    Text("\(Int(maxLogSize)) MB")
                        .frame(width: 60)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("System Thresholds") {
                HStack {
                    Text("CPU Alert Threshold")
                    Spacer()
                    Slider(value: $cpuThreshold, in: 50...95, step: 5) {
                        Text("CPU Threshold")
                    }
                    Text("\(Int(cpuThreshold))%")
                        .frame(width: 40)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Memory Alert Threshold")
                    Spacer()
                    Slider(value: $memoryThreshold, in: 60...95, step: 5) {
                        Text("Memory Threshold")
                    }
                    Text("\(Int(memoryThreshold))%")
                        .frame(width: 40)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Battery Alert Threshold")
                    Spacer()
                    Slider(value: $batteryThreshold, in: 5...50, step: 5) {
                        Text("Battery Threshold")
                    }
                    Text("\(Int(batteryThreshold))%")
                        .frame(width: 40)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Experimental Features") {
                Toggle("Enable Experimental Features", isOn: $enableExperimentalFeatures)
                    .help("Enable cutting-edge features that may be unstable")
                
                if enableExperimentalFeatures {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("⚠️ Warning")
                            .foregroundColor(.orange)
                            .fontWeight(.bold)
                        
                        Text("Experimental features may cause instability or unexpected behavior. Use at your own risk.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(Spacing.small)
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            
            Section("Data Management") {
                Button("Clear All Logs") {
                    clearAllLogs()
                }
                .foregroundColor(.orange)
                
                Button("Reset All Settings") {
                    resetAllSettings()
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Advanced")
    }
    
    private func clearAllLogs() {
        // Clear all log files
        print("Clearing all logs...")
    }
    
    private func resetAllSettings() {
        // Reset all settings to defaults
        debugMode = false
        verboseLogging = false
        maxLogSize = 100.0
        cpuThreshold = 80.0
        memoryThreshold = 85.0
        batteryThreshold = 20.0
        enableExperimentalFeatures = false
    }
}

#Preview {
    AdvancedSettingsView()
        .frame(width: 500, height: 400)
}