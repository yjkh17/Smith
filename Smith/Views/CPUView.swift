//
//  CPUView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import SwiftUI

struct CPUView: View {
    @StateObject private var cpuMonitor = CPUMonitor()
    @EnvironmentObject private var smithAgent: SmithAgent
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with CPU overview
            VStack(spacing: 16) {
                HStack {
                    Text("CPU Monitor")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(cpuMonitor.isMonitoring ? "Stop" : "Start") {
                        if cpuMonitor.isMonitoring {
                            cpuMonitor.stopMonitoring()
                        } else {
                            cpuMonitor.startMonitoring()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // CPU Usage Gauge
                HStack(spacing: 20) {
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: cpuMonitor.cpuUsage / 100)
                                .stroke(cpuUsageColor, lineWidth: 8)
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: cpuMonitor.cpuUsage)
                            
                            VStack {
                                Text("\(Int(cpuMonitor.cpuUsage))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("CPU")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text("Overall Usage")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(cpuUsageColor)
                                .frame(width: 8, height: 8)
                            Text("CPU Usage: \(String(format: "%.1f", cpuMonitor.cpuUsage))%")
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Circle()
                                .fill(cpuMonitor.isMonitoring ? .green : .red)
                                .frame(width: 8, height: 8)
                            Text("Status: \(cpuMonitor.isMonitoring ? "Monitoring" : "Stopped")")
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                            Text("Processes: \(cpuMonitor.processes.count)")
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button("Analyze High CPU Usage") {
                            analyzeHighCPU()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }
            }
            .padding()
            .background(.gray.opacity(0.1))
            
            Divider()
            
            // Process List
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Top Processes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    Spacer()
                    
                    Button("Ask about processes") {
                        askAboutProcesses()
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                List(cpuMonitor.processes) { process in
                    ProcessRowView(process: process) {
                        askAboutSpecificProcess(process)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(.black)
        .onAppear {
            // Start monitoring when view appears
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                cpuMonitor.startMonitoring()
            }
        }
        .onDisappear {
            // Stop monitoring when view disappears to save resources
            cpuMonitor.stopMonitoring()
        }
    }
    
    private var cpuUsageColor: Color {
        switch cpuMonitor.cpuUsage {
        case 0..<30:
            return .green
        case 30..<60:
            return .yellow
        case 60..<80:
            return .orange
        default:
            return .red
        }
    }
    
    private func analyzeHighCPU() {
        let analysis = cpuMonitor.analyzeHighCPUUsage()
        
        Task {
            await smithAgent.sendMessage("Analyze my current CPU usage:\n\n\(analysis)")
        }
    }
    
    private func askAboutProcesses() {
        let processesInfo = cpuMonitor.processes.prefix(10).map { process in
            "\(process.name): \(String(format: "%.1f", process.cpuUsage))%"
        }.joined(separator: "\n")
        
        let question = "Why are my CPU usage levels at \(String(format: "%.1f", cpuMonitor.cpuUsage))%? Here are my top processes:\n\n\(processesInfo)\n\nWhat should I do to optimize performance?"
        
        Task {
            await smithAgent.sendMessage(question)
        }
    }
    
    private func askAboutSpecificProcess(_ process: ProcessInfo) {
        let question = "Why is \(process.name) using \(String(format: "%.1f", process.cpuUsage))% CPU? Is this normal and what can I do about it?"
        
        Task {
            await smithAgent.sendMessage(question)
        }
    }
}

struct ProcessRowView: View {
    let process: ProcessInfo
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(process.displayName)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("PID: \(process.pid)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(String(format: "%.1f", process.cpuUsage))%")
                    .foregroundColor(process.statusColor)
                    .fontWeight(.semibold)
                
                // CPU usage bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(process.statusColor)
                            .frame(width: geometry.size.width * (process.cpuUsage / 100), height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(width: 80)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    CPUView()
        .environmentObject(SmithAgent())
}
