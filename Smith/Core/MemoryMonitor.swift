//
//  MemoryMonitor.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import Foundation
import SwiftUI
import Combine
import Darwin.Mach

@MainActor
class MemoryMonitor: ObservableObject {
    @Published var totalMemory: UInt64 = 0
    @Published var usedMemory: UInt64 = 0
    @Published var freeMemory: UInt64 = 0
    @Published var appMemory: UInt64 = 0
    @Published var wiredMemory: UInt64 = 0
    @Published var compressedMemory: UInt64 = 0
    @Published var cachedFiles: UInt64 = 0
    @Published var swapUsed: UInt64 = 0
    @Published var memoryPressure: MemoryPressure = .normal
    @Published var isMonitoring = false
    @Published var topMemoryProcesses: [MemoryProcessInfo] = []
    
    nonisolated(unsafe) private var timer: Timer?
    private var isUpdating = false
    
    // Memory pressure source for monitoring system memory pressure
    nonisolated(unsafe) private var memoryPressureSource: DispatchSourceMemoryPressure?
    
    // Store total memory for nonisolated access
    nonisolated(unsafe) private var internalTotalMemory: UInt64 = 0
    
    init() {
        setupMemoryPressureMonitoring()
        let totalMem = getTotalMemory()
        internalTotalMemory = totalMem
        totalMemory = totalMem
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
        memoryPressureSource?.cancel()
        memoryPressureSource = nil
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                await self.updateMemoryInfo()
            }
        }
        
        // Initial update
        Task {
            await updateMemoryInfo()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    nonisolated private func getTotalMemory() -> UInt64 {
        var size = MemoryLayout<UInt64>.size
        var totalMemory: UInt64 = 0
        
        let result = sysctlbyname("hw.memsize", &totalMemory, &size, nil, 0)
        if result == 0 {
            return totalMemory
        }
        
        return 0
    }
    
    private func setupMemoryPressureMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: DispatchQueue.main
        )
        
        memoryPressureSource?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                let event = self.memoryPressureSource?.mask
                if event?.contains(.critical) == true {
                    self.memoryPressure = .critical
                } else if event?.contains(.warning) == true {
                    self.memoryPressure = .warning
                } else {
                    self.memoryPressure = .normal
                }
            }
        }
        
        memoryPressureSource?.resume()
    }
    
    private func updateMemoryInfo() async {
        guard !isUpdating else { return }
        isUpdating = true
        
        let memoryStats = await getMemoryStatisticsBackground()
        let processInfo = await getMemoryProcessesBackground()
        
        self.usedMemory = memoryStats.used
        self.freeMemory = memoryStats.free
        self.appMemory = memoryStats.app
        self.wiredMemory = memoryStats.wired
        self.compressedMemory = memoryStats.compressed
        self.cachedFiles = memoryStats.cached
        self.swapUsed = memoryStats.swap
        self.topMemoryProcesses = processInfo
        
        // Update memory pressure if not already set by system events
        if memoryPressure == .normal {
            let usagePercentage = Double(usedMemory) / Double(totalMemory) * 100
            if usagePercentage > 95 {
                memoryPressure = .critical
            } else if usagePercentage > 85 {
                memoryPressure = .warning
            }
        }
        
        isUpdating = false
    }
    
    nonisolated private func getMemoryStatisticsBackground() async -> MemoryStats {
        return await Task.detached {
            return self.getVMStatistics()
        }.value
    }
    
    nonisolated private func getMemoryProcessesBackground() async -> [MemoryProcessInfo] {
        return await Task.detached {
            return self.getProcessMemoryUsage()
        }.value
    }
    
    nonisolated private func getVMStatistics() -> MemoryStats {
        var vmStats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return MemoryStats(used: 0, free: 0, app: 0, wired: 0, compressed: 0, cached: 0, swap: 0)
        }
        
        // Determine the system page size dynamically for accurate calculations
        var hostPageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &hostPageSize)
        let pageSize = UInt64(hostPageSize)
        
        let freePages = UInt64(vmStats.free_count)
        let inactivePages = UInt64(vmStats.inactive_count)
        let activePages = UInt64(vmStats.active_count)
        let wiredPages = UInt64(vmStats.wire_count)
        let speculativePages = UInt64(vmStats.speculative_count)
        let compressedPages = UInt64(vmStats.compressor_page_count)
        let purgeablePages = UInt64(vmStats.purgeable_count)
        let externalPages = UInt64(vmStats.external_page_count)
        
        let freeMemory = freePages * pageSize
        let activeMemory = activePages * pageSize
        let inactiveMemory = inactivePages * pageSize
        let wiredMemory = wiredPages * pageSize
        let compressedMemory = compressedPages * pageSize
        let speculativeMemory = speculativePages * pageSize
        let purgeableMemory = purgeablePages * pageSize
        let externalMemory = externalPages * pageSize
        
        // App memory is active + inactive + speculative + external
        let appMemory = activeMemory + inactiveMemory + speculativeMemory + externalMemory
        
        // Cached files are purgeable and some inactive memory
        let cachedFiles = purgeableMemory + (inactiveMemory / 2) // Approximation
        
        // Used memory is everything except free
        let usedMemory = internalTotalMemory - freeMemory
        
        // Get swap usage
        let swapUsed = getSwapUsage()
        
        return MemoryStats(
            used: usedMemory,
            free: freeMemory,
            app: appMemory,
            wired: wiredMemory,
            compressed: compressedMemory,
            cached: cachedFiles,
            swap: swapUsed
        )
    }
    
    nonisolated private func getSwapUsage() -> UInt64 {
        var xswUsage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        
        let result = sysctlbyname("vm.swapusage", &xswUsage, &size, nil, 0)
        if result == 0 {
            return xswUsage.xsu_used
        }
        
        return 0
    }
    
    nonisolated private func getProcessMemoryUsage() -> [MemoryProcessInfo] {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-Ao", "pid,rss,comm", "-m"] // Sort by memory usage
        
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
            
            return parseMemoryProcessOutput(output)
            
        } catch {
            return []
        }
    }
    
    nonisolated private func parseMemoryProcessOutput(_ output: String) -> [MemoryProcessInfo] {
        let lines = output.components(separatedBy: .newlines)
        var processes: [MemoryProcessInfo] = []
        
        for line in lines.dropFirst() { // Skip header
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else { continue }
            
            let components = trimmedLine.components(separatedBy: .whitespaces)
            guard components.count >= 3 else { continue }
            
            guard let pid = Int(components[0]) else { continue }
            guard let rssKB = Int(components[1]) else { continue }
            
            let command = components.dropFirst(2).joined(separator: " ")
            let cleanName = cleanProcessName(command)
            
            // Convert RSS from KB to bytes
            let memoryBytes = UInt64(rssKB * 1024)
            
            // Only include processes using significant memory (> 10MB)
            guard memoryBytes > 10 * 1024 * 1024 else { continue }
            
            let processInfo = MemoryProcessInfo(
                pid: pid,
                name: cleanName,
                memoryUsage: memoryBytes
            )
            
            processes.append(processInfo)
        }
        
        return processes
            .sorted { $0.memoryUsage > $1.memoryUsage }
            .prefix(15)
            .map { $0 }
    }
    
    nonisolated private func cleanProcessName(_ command: String) -> String {
        var cleanName = command
        
        if cleanName.hasPrefix("/") {
            cleanName = URL(fileURLWithPath: cleanName).lastPathComponent
        }
        
        if let spaceIndex = cleanName.firstIndex(of: " ") {
            cleanName = String(cleanName[..<spaceIndex])
        }
        
        if cleanName.hasSuffix(".app") {
            cleanName = String(cleanName.dropLast(4))
        }
        
        let prefixesToRemove = ["/usr/bin/", "/usr/sbin/", "/bin/", "/sbin/"]
        for prefix in prefixesToRemove {
            if cleanName.hasPrefix(prefix) {
                cleanName = String(cleanName.dropFirst(prefix.count))
            }
        }
        
        return cleanName.isEmpty ? "Unknown" : cleanName
    }
    
    func analyzeMemoryUsage() -> String {
        var analysis = "🧠 Memory Usage Analysis:\n\n"
        
        let usedGB = Double(usedMemory) / (1024.0 * 1024.0 * 1024.0)
        let totalGB = Double(totalMemory) / (1024.0 * 1024.0 * 1024.0)
        let usagePercentage = (Double(usedMemory) / Double(totalMemory)) * 100
        
        analysis += "📊 Memory Overview:\n"
        analysis += "• Total Memory: \(String(format: "%.1f", totalGB)) GB\n"
        analysis += "• Used Memory: \(String(format: "%.1f", usedGB)) GB (\(String(format: "%.1f", usagePercentage))%)\n"
        analysis += "• Free Memory: \(formatBytes(freeMemory))\n"
        analysis += "• Memory Pressure: \(memoryPressure.description)\n\n"
        
        analysis += "🔍 Memory Breakdown:\n"
        analysis += "• App Memory: \(formatBytes(appMemory))\n"
        analysis += "• Wired Memory: \(formatBytes(wiredMemory))\n"
        analysis += "• Cached Files: \(formatBytes(cachedFiles))\n"
        analysis += "• Compressed: \(formatBytes(compressedMemory))\n"
        
        if swapUsed > 0 {
            analysis += "• Swap Used: \(formatBytes(swapUsed)) ⚠️\n"
        }
        
        // Memory pressure analysis
        analysis += "\n💡 Performance Analysis:\n"
        switch memoryPressure {
        case .normal:
            analysis += "✅ Memory pressure is normal\n"
        case .warning:
            analysis += "⚠️ Memory pressure is elevated - consider closing some apps\n"
        case .critical:
            analysis += "🚨 Critical memory pressure - immediate action needed!\n"
        }
        
        // Usage recommendations
        switch usagePercentage {
        case 0...60:
            analysis += "✅ Memory usage is optimal\n"
        case 61...75:
            analysis += "📝 Memory usage is moderate - monitor for efficiency\n"
        case 76...85:
            analysis += "⚠️ Memory usage is high - consider closing unused apps\n"
        case 86...95:
            analysis += "🟡 Memory usage is very high - free up memory soon\n"
        default:
            analysis += "🔴 Memory usage is critical - immediate action required!\n"
        }
        
        // Top memory consumers
        if !topMemoryProcesses.isEmpty {
            analysis += "\n🏆 Top Memory Consumers:\n"
            for process in topMemoryProcesses.prefix(5) {
                let memoryMB = Double(process.memoryUsage) / (1024.0 * 1024.0)
                analysis += "• \(process.displayName): \(String(format: "%.0f", memoryMB)) MB\n"
            }
        }
        
        // Recommendations
        analysis += "\n💡 Optimization Recommendations:\n"
        
        if swapUsed > 0 {
            analysis += "• Reduce memory usage - swap is being used\n"
        }
        
        if memoryPressure != .normal {
            analysis += "• Close unnecessary applications immediately\n"
            analysis += "• Restart memory-intensive apps that may have leaks\n"
            analysis += "• Consider upgrading RAM if this is frequent\n"
        }
        
        analysis += "• Use Activity Monitor to identify memory leaks\n"
        analysis += "• Close unused browser tabs (each tab uses memory)\n"
        analysis += "• Restart applications that have been running for days\n"
        analysis += "• Consider adding more RAM if consistently above 80%\n"
        
        if cachedFiles > (totalMemory / 4) {
            analysis += "• Large amount of cached files - this is normal and beneficial\n"
        }
        
        return analysis
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    func getMemoryUsageColor() -> Color {
        let usagePercentage = (Double(usedMemory) / Double(totalMemory)) * 100
        
        switch usagePercentage {
        case 0...60:
            return .green
        case 61...75:
            return .yellow
        case 76...85:
            return .orange
        default:
            return .red
        }
    }
}

enum MemoryPressure {
    case normal
    case warning
    case critical
    
    var description: String {
        switch self {
        case .normal: return "Normal"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

struct MemoryStats {
    let used: UInt64
    let free: UInt64
    let app: UInt64
    let wired: UInt64
    let compressed: UInt64
    let cached: UInt64
    let swap: UInt64
}

struct MemoryProcessInfo: Identifiable {
    let id = UUID()
    let pid: Int
    let name: String
    let memoryUsage: UInt64 // in bytes
    
    var displayName: String {
        switch name.lowercased() {
        case "kernel_task":
            return "Kernel Task"
        case "windowserver":
            return "Window Server"
        case "mds", "mds_stores":
            return "Spotlight"
        case "coreaudiod":
            return "Core Audio"
        case "backupd":
            return "Time Machine"
        case "findmydevice-user-agent":
            return "Find My"
        case "controlcenter":
            return "Control Center"
        default:
            return name
        }
    }
    
    var memoryMB: Double {
        return Double(memoryUsage) / (1024.0 * 1024.0)
    }
    
    var statusColor: Color {
        let memoryMB = self.memoryMB
        
        switch memoryMB {
        case 0..<100:
            return .green
        case 100..<500:
            return .yellow
        case 500..<1000:
            return .orange
        default:
            return .red
        }
    }
}
