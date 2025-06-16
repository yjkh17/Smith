//
//  CPUMonitor.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import Foundation
import SwiftUI
import Combine
import Darwin
import Darwin.Mach

@MainActor
class CPUMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0.0
    @Published var processes: [ProcessInfo] = []
    @Published var isMonitoring = false
    
    nonisolated(unsafe) private var timer: Timer?
    private var isUpdating = false
    
    // Store previous CPU info for accurate delta calculations
    nonisolated(unsafe) private var previousCPUInfo: host_cpu_load_info_data_t?
    nonisolated(unsafe) private var previousTimestamp: Date?
    
    init() {
        // Don't start monitoring immediately to prevent freeze
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // Reset previous data
        previousCPUInfo = nil
        previousTimestamp = nil
        
        // Start with a longer interval to prevent blocking
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                await self.updateDataSafely()
            }
        }
        
        // Initial update after a short delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await updateDataSafely()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        previousCPUInfo = nil
        previousTimestamp = nil
    }
    
    private func updateDataSafely() async {
        guard !isUpdating else { return }
        isUpdating = true
        
        // Move the actual work to nonisolated methods
        let newCPUUsage = await getRealCPUUsageBackground()
        let newProcesses = await getRealProcessesBackground()
        
        self.cpuUsage = newCPUUsage
        self.processes = newProcesses
        
        isUpdating = false
    }
    
    nonisolated private func getRealCPUUsageBackground() async -> Double {
        return await Task.detached {
            return self.getAccurateCPUUsage()
        }.value
    }
    
    nonisolated private func getRealProcessesBackground() async -> [ProcessInfo] {
        return await Task.detached {
            // Try top command first (more like Activity Monitor)
            let topProcesses = self.getProcessesUsingTop()
            if !topProcesses.isEmpty {
                return topProcesses
            }
            
            // Fallback to ps command
            let psProcesses = self.getAccurateProcesses()
            if !psProcesses.isEmpty {
                return psProcesses
            }
            
            // Final fallback
            return self.getFallbackProcesses()
        }.value
    }
    
    nonisolated private func getAccurateCPUUsage() -> Double {
        var cpuInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            print("Failed to get CPU info")
            return 0.0
        }
        
        let currentTime = Date()
        
        // If we have previous data, calculate the delta
        if let previousInfo = previousCPUInfo,
           let _ = previousTimestamp {
            
            let userDelta = cpuInfo.cpu_ticks.0 - previousInfo.cpu_ticks.0
            let systemDelta = cpuInfo.cpu_ticks.1 - previousInfo.cpu_ticks.1
            let idleDelta = cpuInfo.cpu_ticks.2 - previousInfo.cpu_ticks.2
            let niceDelta = cpuInfo.cpu_ticks.3 - previousInfo.cpu_ticks.3
            
            let totalDelta = userDelta + systemDelta + idleDelta + niceDelta
            
            if totalDelta > 0 {
                let usedDelta = userDelta + systemDelta + niceDelta
                let usage = (Double(usedDelta) / Double(totalDelta)) * 100.0
                
                // Store current values for next calculation
                previousCPUInfo = cpuInfo
                previousTimestamp = currentTime
                
                return max(0, min(100, usage))
            }
        }
        
        // Store initial values
        previousCPUInfo = cpuInfo
        previousTimestamp = currentTime
        
        return 0.0 // Return 0 for first measurement
    }
    
    nonisolated private func getAccurateProcesses() -> [ProcessInfo] {
        let task = Process()
        task.launchPath = "/bin/ps"
        // Use the same arguments as Activity Monitor for accurate CPU measurement
        task.arguments = ["-Ao", "pid,%cpu,command"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            
            // Set timeout
            let deadline = Date().addingTimeInterval(3.0)
            while task.isRunning && Date() < deadline {
                usleep(50000) // 0.05 seconds
            }
            
            if task.isRunning {
                task.terminate()
                return getFallbackProcesses()
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return parseRealProcessOutput(output)
            
        } catch {
            print("Error running ps command: \(error)")
            return getFallbackProcesses()
        }
    }
    
    nonisolated private func parseRealProcessOutput(_ output: String) -> [ProcessInfo] {
        let lines = output.components(separatedBy: .newlines)
        var processes: [ProcessInfo] = []
        
        // Skip header line (PID %CPU COMMAND)
        for line in lines.dropFirst() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else { continue }
            
            // Split by whitespace but be careful with the command field
            let components = trimmedLine.components(separatedBy: .whitespaces)
            guard components.count >= 3 else { continue }
            
            guard let pid = Int(components[0]) else { continue }
            
            // Parse CPU usage - it might have decimal points
            guard let cpuUsage = Double(components[1]) else { continue }
            
            // The command is everything after the second column
            let commandStartIndex = trimmedLine.firstIndex(of: " ") // Find first space (after PID)
            guard let firstSpaceIndex = commandStartIndex else { continue }
            
            let afterPID = String(trimmedLine[trimmedLine.index(after: firstSpaceIndex)...])
            let secondSpaceIndex = afterPID.firstIndex(of: " ") // Find second space (after %CPU)
            guard let secondSpace = secondSpaceIndex else { continue }
            
            let command = String(afterPID[afterPID.index(after: secondSpace)...]).trimmingCharacters(in: .whitespaces)
            guard !command.isEmpty else { continue }
            
            let cleanName = cleanProcessName(command)
            
            let processInfo = ProcessInfo(
                pid: pid,
                name: cleanName,
                cpuUsage: cpuUsage
            )
            
            processes.append(processInfo)
        }
        
        return processes
            .filter { $0.cpuUsage > 0.0 } // Only show processes with actual CPU usage
            .sorted { $0.cpuUsage > $1.cpuUsage }
            .prefix(25)
            .map { $0 }
    }
    
    nonisolated private func cleanProcessName(_ command: String) -> String {
        var cleanName = command
        
        // Remove path if it starts with /
        if cleanName.hasPrefix("/") {
            cleanName = URL(fileURLWithPath: cleanName).lastPathComponent
        }
        
        // DON'T group Xcode processes - show each individually for accuracy
        // This was causing the aggregation issue
        
        // Remove arguments (everything after first space with a dash)
        if let spaceIndex = cleanName.firstIndex(of: " ") {
            let afterSpace = String(cleanName[cleanName.index(after: spaceIndex)...])
            if afterSpace.hasPrefix("-") {
                cleanName = String(cleanName[..<spaceIndex])
            }
        }
        
        // Handle .app bundles
        if cleanName.hasSuffix(".app") {
            cleanName = String(cleanName.dropLast(4))
        }
        
        // Keep the full process name for accuracy
        // Remove common prefixes only
        let prefixesToRemove = ["/usr/bin/", "/usr/sbin/", "/bin/", "/sbin/"]
        for prefix in prefixesToRemove {
            if cleanName.hasPrefix(prefix) {
                cleanName = String(cleanName.dropFirst(prefix.count))
            }
        }
        
        return cleanName.isEmpty ? "Unknown" : cleanName
    }
    
    nonisolated private func getFallbackProcesses() -> [ProcessInfo] {
        // Fallback using NSWorkspace but with zero CPU usage since we can't get real data
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        var processes: [ProcessInfo] = []
        
        for app in runningApps.prefix(10) {
            let name = app.localizedName ?? app.bundleIdentifier ?? "Unknown"
            let pid = Int(app.processIdentifier)
            
            let processInfo = ProcessInfo(
                pid: pid,
                name: name,
                cpuUsage: 0.0 // No fake data
            )
            
            processes.append(processInfo)
        }
        
        return processes
    }
    
    nonisolated private func debugPSOutput() {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-Ao", "pid,%cpu,command"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            print("=== PS COMMAND OUTPUT ===")
            print(output.prefix(1000)) // Print first 1000 characters
            print("=== END PS OUTPUT ===")
            
        } catch {
            print("Debug PS failed: \(error)")
        }
    }
    
    nonisolated private func getProcessesUsingTop() -> [ProcessInfo] {
        let task = Process()
        task.launchPath = "/usr/bin/top"
        task.arguments = ["-l", "1", "-o", "cpu", "-n", "20", "-stats", "pid,cpu,command"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            
            let deadline = Date().addingTimeInterval(3.0)
            while task.isRunning && Date() < deadline {
                usleep(50000)
            }
            
            if task.isRunning {
                task.terminate()
                return []
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return parseTopProcessOutput(output)
            
        } catch {
            print("Error running top command: \(error)")
            return []
        }
    }
    
    nonisolated private func parseTopProcessOutput(_ output: String) -> [ProcessInfo] {
        let lines = output.components(separatedBy: .newlines)
        var processes: [ProcessInfo] = []
        var inProcessSection = false
        
        for line in lines {
            // Look for the processes section
            if line.contains("PID") && line.contains("CPU") && line.contains("COMMAND") {
                inProcessSection = true
                continue
            }
            
            guard inProcessSection else { continue }
            
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else { continue }
            
            let components = trimmedLine.components(separatedBy: .whitespaces)
            guard components.count >= 3 else { continue }
            
            guard let pid = Int(components[0]) else { continue }
            
            // Parse CPU usage (might be like "12.3" or "0.0")
            let cpuString = components[1].replacingOccurrences(of: "%", with: "")
            guard let cpuUsage = Double(cpuString) else { continue }
            
            // Command is the rest
            let command = components.dropFirst(2).joined(separator: " ")
            let cleanName = cleanProcessName(command)
            
            let processInfo = ProcessInfo(
                pid: pid,
                name: cleanName,
                cpuUsage: cpuUsage
            )
            
            processes.append(processInfo)
        }
        
        return processes
            .filter { $0.cpuUsage > 0.0 }
            .sorted { $0.cpuUsage > $1.cpuUsage }
            .prefix(25)
            .map { $0 }
    }
    
    func analyzeHighCPUUsage() -> String {
        let highCPUProcesses = processes.filter { $0.cpuUsage > 5 }
        
        guard !highCPUProcesses.isEmpty else {
            return "✅ CPU usage is normal. No processes are consuming excessive CPU resources."
        }
        
        var analysis = "🔥 High CPU Usage Detected:\n\n"
        
        for process in highCPUProcesses.prefix(5) {
            analysis += "• \(process.name) (PID: \(process.pid)): \(String(format: "%.1f", process.cpuUsage))%\n"
            
            switch process.name.lowercased() {
            case let name where name.contains("kernel"):
                analysis += "  → System kernel process - usually normal but monitor if consistently high\n"
            case let name where name.contains("windowserver"):
                analysis += "  → Window Server - handles graphics, high usage may indicate graphics issues\n"
            case let name where name.contains("xcode"):
                analysis += "  → Xcode development environment - normal during compilation/indexing\n"
            case let name where name.contains("chrome"), let name where name.contains("firefox"), let name where name.contains("safari"):
                analysis += "  → Web browser - check for resource-heavy websites or too many tabs\n"
            case let name where name.contains("spotlight"), let name where name.contains("mds"):
                analysis += "  → Spotlight indexing - should decrease once indexing completes\n"
            case let name where name.contains("backup"), let name where name.contains("time machine"):
                analysis += "  → Backup process - normal during backup operations\n"
            case let name where name.contains("photos"):
                analysis += "  → Photos app - likely processing/syncing images\n"
            default:
                analysis += "  → Monitor this process and consider restarting if persistently high\n"
            }
            analysis += "\n"
        }
        
        analysis += "💡 Recommendations:\n"
        analysis += "• Close unnecessary applications\n"
        analysis += "• Check Activity Monitor for detailed information\n"
        analysis += "• Restart high-usage applications if they seem stuck\n"
        analysis += "• Check for runaway processes or malware\n"
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
        if name.isEmpty {
            return "Unknown Process"
        }
        
        // Clean up common process names for better display
        switch name.lowercased() {
        case "windowserver":
            return "Window Server"
        case "kernel_task":
            return "Kernel Task"
        case "mds", "mds_stores":
            return "Spotlight"
        case "coreaudiod":
            return "Core Audio"
        case "backupd":
            return "Time Machine"
        default:
            return name
        }
    }
    
    var statusColor: Color {
        switch cpuUsage {
        case 0..<3:
            return .green
        case 3..<10:
            return .yellow
        case 10..<20:
            return .orange
        default:
            return .red
        }
    }
}
