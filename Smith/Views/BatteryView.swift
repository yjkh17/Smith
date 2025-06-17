//
//  BatteryView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import SwiftUI

struct BatteryView: View {
    @StateObject private var batteryMonitor = BatteryMonitor()
    @EnvironmentObject private var smithAgent: SmithAgent
    
    var body: some View {
        VStack(spacing: 4) {
            // Ultra-Compact Header with battery overview
            VStack(spacing: 6) {
                HStack {
                    Text("Battery Monitor")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(batteryMonitor.isMonitoring ? "Stop" : "Start") {
                        if batteryMonitor.isMonitoring {
                            batteryMonitor.stopMonitoring()
                        } else {
                            batteryMonitor.startMonitoring()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
                
                // Ultra-Compact Battery Level Display
                HStack(spacing: 10) {
                    // Ultra-Compact Battery Gauge
                    ZStack {
                        // Battery outline
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(.gray, lineWidth: 1.5)
                            .frame(width: 40, height: 24)
                        
                        // Battery level fill
                        RoundedRectangle(cornerRadius: 2)
                            .fill(batteryLevelColor)
                            .frame(
                                width: 36 * (batteryMonitor.batteryLevel / 100),
                                height: 20
                            )
                            .animation(.easeInOut, value: batteryMonitor.batteryLevel)
                            .clipped()
                        
                        // Battery percentage text
                        Text("\(Int(batteryMonitor.batteryLevel))%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        // Battery tip
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.gray)
                            .frame(width: 2, height: 8)
                            .offset(x: 22)
                    }
                    
                    // Ultra-Compact Battery Info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: batteryMonitor.isCharging ? "bolt.fill" : "battery")
                                .foregroundColor(batteryMonitor.isCharging ? .yellow : batteryLevelColor)
                                .font(.caption2)
                            Text("Status: \(batteryMonitor.batteryState.description)")
                                .font(.caption2)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Button("Health") {
                                analyzeBatteryHealth()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .tint(.green)
                            
                            Button("Energy") {
                                analyzeHighEnergyApps()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            
            // Ultra-Compact Power Sources and Tips
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    // Ultra-Compact Power Sources
                    if !batteryMonitor.powerSources.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Power Sources")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            ForEach(batteryMonitor.powerSources.prefix(2), id: \.name) { source in
                                UltraCompactPowerSourceView(source: source)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    
                    // Ultra-Compact Battery Tips
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Optimization Tips")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            UltraCompactTipView(icon: "lightbulb", title: "Reduce Brightness")
                            UltraCompactTipView(icon: "wifi.slash", title: "Disable Unused Connections")
                            UltraCompactTipView(icon: "app.badge.minus", title: "Close Background Apps")
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .frame(maxHeight: 80)
        }
        .background(Color(.systemBackground))
        .frame(maxHeight: 180)
    }
    
    private var batteryLevelColor: Color {
        switch batteryMonitor.batteryLevel {
        case 80...100:
            return .green
        case 50...79:
            return .yellow
        case 20...49:
            return .orange
        default:
            return .red
        }
    }
    
    private func analyzeBatteryHealth() {
        let analysis = batteryMonitor.analyzeBatteryHealth()
        
        Task {
            await smithAgent.sendMessage("Analyze my battery health and provide recommendations:\n\n\(analysis)")
        }
    }
    
    private func analyzeHighEnergyApps() {
        let analysis = batteryMonitor.analyzeHighEnergyApps()
        
        Task {
            await smithAgent.sendMessage("Which apps are draining my battery?\n\n\(analysis)")
        }
    }
}

struct PowerSourceRowView: View {
    let source: PowerSourceInfo
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(source.name)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                
                Text(source.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                if source.maxCapacity > 0 {
                    Text("\(source.currentCapacity)/\(source.maxCapacity)")
                        .foregroundColor(.primary)
                        .font(.caption)
                }
                
                Text(source.batteryState.description)
                    .font(.caption2)
                    .foregroundColor(source.isCharging ? .green : .gray)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct TipRowView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct CompactPowerSourceView: View {
    let source: PowerSourceInfo
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(source.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                
                Text(source.type)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 1) {
                if source.maxCapacity > 0 {
                    Text("\(source.currentCapacity)/\(source.maxCapacity)")
                        .font(.caption2)
                        .foregroundColor(.primary)
                }
                
                Text(source.batteryState.description)
                    .font(.caption2)
                    .foregroundColor(source.isCharging ? .green : .gray)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(4)
    }
}

struct CompactTipView: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .font(.caption)
                .frame(width: 12)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct UltraCompactPowerSourceView: View {
    let source: PowerSourceInfo
    
    var body: some View {
        HStack {
                Text(source.name)
                    .font(.caption2)
                    .foregroundColor(.primary)
                .fontWeight(.medium)
            
            Spacer()
            
            if source.maxCapacity > 0 {
                Text("\(source.currentCapacity)/\(source.maxCapacity)")
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            
            Text(source.batteryState.description)
                .font(.caption2)
                .foregroundColor(source.isCharging ? .green : .secondary)
        }
        .padding(.vertical, 1)
        .padding(.horizontal, 4)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(3)
    }
}

struct UltraCompactTipView: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .font(.caption2)
                .frame(width: 10)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.primary)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.vertical, 1)
    }
}

#Preview {
    BatteryView()
        .environmentObject(SmithAgent())
}
