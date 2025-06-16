//
//  CPUMonitor.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import Foundation
import SwiftUI

@MainActor
class CPUMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0.0
    @Published var processes: [ProcessInfo] = []
    @Published var isMonitoring = false
    
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateCPUUsage()
                self.updateProcessList()
            }
        }
        
        // Initial update
        updateCPUUsage()
        updateProcessList()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    private func updateCPUUsage() {
        cpuUsage = getCurrentCPUUsage()
    }
    
    private func updateProcessList() {
        processes = getTopProcesses()
    }
    
    private func getCurrentCPUUsage() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        let userTime = Double(info.cpu_ticks.0)
        let systemTime = Double(info.cpu_ticks.1)
        let idleTime = Double(info.cpu_ticks.2)
        let niceTime = Double(info.cpu_ticks.3)
        
        let totalTime = userTime + systemTime + idleTime + niceTime
        let usedTime = userTime + systemTime + niceTime
        
        return totalTime > 0 ? (usedTime / totalTime) * 100.0 : 0.0
    }
    
    private func getTopProcesses() -> [ProcessInfo] {
        var processes: [ProcessInfo] = []
        
        // Get process list using BSD system calls
        var processCount: size_t = 0
        
        // First call to get the number of processes
        if sysctl([CTL_KERN, KERN_PROC, KERN_PROC_ALL], 3, nil, &processCount, nil, 0) == 0 {
            let processCountInt = processCount / MemoryLayout<kinfo_proc>.size
            var processBuffer = Array<kinfo_proc>(repeating: kinfo_proc(), count: processCountInt)
            
            // Second call to get the actual process data
            if sysctl([CTL_KERN, KERN_PROC, KERN_PROC_ALL], 3, &processBuffer, &processCount, nil, 0) == 0 {
                let actualProcessCount = processCount / MemoryLayout<kinfo_proc>.size
                
                for i in 0..<actualProcessCount {
                    let process = processBuffer[i]
                    let pid = process.kp_proc.p_pid
                    let name = withUnsafePointer(to: process.kp_proc.p_comm) {
                        String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
                    }
                    
                    // Estimate CPU usage (simplified)
                    let cpuUsage = estimateCPUUsage(for: process)
                    
                    let processInfo = ProcessInfo(
                        pid: Int(pid),
                        name: name,
                        cpuUsage: cpuUsage
                    )
                    
                    processes.append(processInfo)
                }
            }
        }
        
        // Sort by CPU usage and return top 20
        return processes
            .sorted { $0.cpuUsage > $1.cpuUsage }
            .prefix(20)
            .map { $0 }
    }
    
    private func estimateCPUUsage(for process: kinfo_proc) -> Double {
        // This is a simplified estimation
        // Real CPU usage calculation would require more complex system calls
        let priority = Double(process.kp_proc.p_priority)
        let nice = Double(process.kp_proc.p_nice)
        
        // Rough estimation based on priority and nice values
        return max(0, min(100, (20 - priority - nice) * 2))
    }
    
    func analyzeHighCPUUsage() -> String {
        let highCPUProcesses = processes.filter { $0.cpuUsage > 20 }
        
        guard !highCPUProcesses.isEmpty else {
            return "✅ CPU usage is normal. No processes are consuming excessive CPU resources."
        }
        
        var analysis = "🔥 High CPU Usage Detected:\n\n"
        
        for process in highCPUProcesses.prefix(5) {
            analysis += "• \(process.name) (PID: \(process.pid)): \(String(format: "%.1f", process.cpuUsage))%\n"
            
            // Provide insights based on process name
            switch process.name.lowercased() {
            case let name where name.contains("kernel"):
                analysis += "  System kernel process - usually normal but check for hardware issues\n"
            case let name where name.contains("spotlight"):
                analysis += "  Spotlight indexing - should decrease once indexing completes\n"
            case let name where name.contains("chrome"), let name where name.contains("firefox"), let name where name.contains("safari"):
                analysis += "  Web browser - check for resource-heavy websites or extensions\n"
            case let name where name.contains("backup"), let name where name.contains("time machine"):
                analysis += "  Backup process - normal during backup operations\n"
            case let name where name.contains("photos"):
                analysis += "  Photos app - likely processing/syncing images\n"
            case let name where name.contains("xcode"):
                analysis += "  Xcode development environment - normal during compilation\n"
            default:
                analysis += "  Check if this application is necessary and consider restarting it\n"
            }
            analysis += "\n"
        }
        
        analysis += "💡 Recommendations:\n"
        analysis += "• Close unnecessary applications\n"
        analysis += "• Check Activity Monitor for detailed process information\n"
        analysis += "• Restart high-usage applications if they seem stuck\n"
        analysis += "• Consider upgrading hardware if consistently high usage\n"
        
        return analysis
    }
}

struct ProcessInfo: Identifiable {
    let id = UUID()
    let pid: Int
    let name: String
    let cpuUsage: Double
    
    var displayName: String {
        // Clean up process names
        if name.isEmpty {
            return "Unknown Process"
        }
        
        // Remove path prefixes for system processes
        let cleanName = name.components(separatedBy: "/").last ?? name
        return cleanName.isEmpty ? "System Process" : cleanName
    }
    
    var statusColor: Color {
        switch cpuUsage {
        case 0..<10:
            return .green
        case 10..<30:
            return .yellow
        case 30..<60:
            return .orange
        default:
            return .red
        }
    }
}