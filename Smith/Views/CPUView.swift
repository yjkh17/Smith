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
        VStack(spacing: 4) {
            // Ultra-Compact Header with CPU overview
            VStack(spacing: 6) {
                HStack {
                    Text("CPU Monitor")
                        .font(.callout)
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
                    .controlSize(.mini)
                }
                
                // Ultra-Compact CPU Usage Display
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(.gray.opacity(0.3), lineWidth: 3)
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .trim(from: 0, to: min(cpuMonitor.cpuUsage / 100, 1))
                            .stroke(cpuUsageColor, lineWidth: 3)
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: cpuMonitor.cpuUsage)
                        
                        VStack(spacing: 0) {
                            Text("\(Int(cpuMonitor.cpuUsage))%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Circle()
                                .fill(cpuUsageColor)
                                .frame(width: 4, height: 4)
                            Text("Usage: \(String(format: "%.1f", cpuMonitor.cpuUsage))%")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 4, height: 4)
                            Text("Processes: \(cpuMonitor.processes.count)")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        
                        Button("Analyze CPU") {
                            analyzeHighCPU()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .tint(.orange)
                    }
                    
                    Spacer()
                }
            }
            .padding(Spacing.small)
            .background(.gray.opacity(0.1))
            
            // Ultra-Compact Process List
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Top Processes")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Ask") {
                        askAboutProcesses()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                .padding(.horizontal, Spacing.small)
                .padding(.top, Spacing.xsmall)
                
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(cpuMonitor.processes.prefix(5)) { process in
                            CompactProcessRowView(process: process) {
                                askAboutSpecificProcess(process)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.small)
                }
                .frame(maxHeight: 100)
            }
            .background(.black.opacity(0.02))
        }
        .background(.black)
        .frame(maxHeight: 220)
        .onAppear {
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                cpuMonitor.startMonitoring()
            }
        }
        .onDisappear {
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
        .padding(.vertical, Spacing.xsmall)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct CompactProcessRowView: View {
    let process: ProcessInfo
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(process.displayName)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("PID: \(process.pid)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(String(format: "%.1f", process.cpuUsage))%")
                    .font(.caption2)
                    .foregroundColor(process.statusColor)
                    .fontWeight(.semibold)
                
                // Compact CPU usage bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .frame(height: 2)
                        
                        Rectangle()
                            .fill(process.statusColor)
                            .frame(width: geometry.size.width * (process.cpuUsage / 100), height: 2)
                    }
                }
                .frame(height: 2)
            }
            .frame(width: 60)
        }
        .padding(.vertical, Spacing.xsmall)
        .padding(.horizontal, Spacing.xsmall)
        .background(.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
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
