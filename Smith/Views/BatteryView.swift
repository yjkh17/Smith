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
        VStack(spacing: 0) {
            // Header with battery overview
            VStack(spacing: 16) {
                HStack {
                    Text("Battery Monitor")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(batteryMonitor.isMonitoring ? "Stop" : "Start") {
                        if batteryMonitor.isMonitoring {
                            batteryMonitor.stopMonitoring()
                        } else {
                            batteryMonitor.startMonitoring()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Battery Level Display
                HStack(spacing: 30) {
                    // Battery Gauge
                    VStack {
                        ZStack {
                            // Battery outline
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.gray, lineWidth: 3)
                                .frame(width: 100, height: 60)
                            
                            // Battery level fill
                            RoundedRectangle(cornerRadius: 6)
                                .fill(batteryLevelColor)
                                .frame(
                                    width: 94 * (batteryMonitor.batteryLevel / 100),
                                    height: 54
                                )
                                .animation(.easeInOut, value: batteryMonitor.batteryLevel)
                                .clipped()
                            
                            // Battery percentage text
                            Text("\(Int(batteryMonitor.batteryLevel))%")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            // Battery tip
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.gray)
                                .frame(width: 4, height: 20)
                                .offset(x: 54)
                        }
                        
                        Text("Battery Level")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Battery Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: batteryMonitor.isCharging ? "bolt.fill" : "battery")
                                .foregroundColor(batteryMonitor.isCharging ? .yellow : batteryLevelColor)
                            Text("Status: \(batteryMonitor.batteryState.description)")
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Image(systemName: "poweron")
                                .foregroundColor(.green)
                            Text("Charging: \(batteryMonitor.isCharging ? "Yes" : "No")")
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Sources: \(batteryMonitor.powerSources.count)")
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Button("Analyze Battery Health") {
                                analyzeBatteryHealth()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            
                            Button("Check High Energy Apps") {
                                analyzeHighEnergyApps()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding()
            .background(.gray.opacity(0.1))
            
            Divider()
            
            // Power Sources and Tips
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Power Sources
                    if !batteryMonitor.powerSources.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Power Sources")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ForEach(batteryMonitor.powerSources, id: \.name) { source in
                                PowerSourceRowView(source: source)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    // Battery Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Battery Optimization Tips")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRowView(
                                icon: "lightbulb",
                                title: "Reduce Screen Brightness",
                                description: "Lower brightness to extend battery life"
                            )
                            
                            TipRowView(
                                icon: "wifi.slash",
                                title: "Disable Unused Connections",
                                description: "Turn off WiFi/Bluetooth when not needed"
                            )
                            
                            TipRowView(
                                icon: "app.badge.minus",
                                title: "Close Background Apps",
                                description: "Quit applications you're not using"
                            )
                            
                            TipRowView(
                                icon: "moon",
                                title: "Use Dark Mode",
                                description: "Dark mode can save battery on some displays"
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .background(.black)
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
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                
                Text(source.type)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                if source.maxCapacity > 0 {
                    Text("\(source.currentCapacity)/\(source.maxCapacity)")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                
                Text(source.batteryState.description)
                    .font(.caption2)
                    .foregroundColor(source.isCharging ? .green : .gray)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(.gray.opacity(0.1))
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
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BatteryView()
        .environmentObject(SmithAgent())
}