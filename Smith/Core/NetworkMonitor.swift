//
//  NetworkMonitor.swift
//  Smith - Your AI System Assistant
//
//  Created by AI Assistant on 17/06/2025.
//

import Foundation
import SwiftUI
import Combine
import Network

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = false
    @Published var connectionType: ConnectionType = .unknown
    @Published var networkQuality: NetworkQuality = .unknown
    @Published var downloadSpeed: Double = 0.0
    @Published var uploadSpeed: Double = 0.0
    @Published var latency: Double = 0.0
    @Published var isMonitoring = false
    
    private var pathMonitor: NWPathMonitor?
    private var monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var timer: Timer?
    
    enum ConnectionType: String, CaseIterable {
        case wifi = "WiFi"
        case ethernet = "Ethernet"
        case cellular = "Cellular"
        case unknown = "Unknown"
        
        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .ethernet: return "cable.connector"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .unknown: return "network"
            }
        }
    }
    
    enum NetworkQuality: String, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        case unknown = "Unknown"
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            case .unknown: return .gray
            }
        }
    }
    
    init() {
        setupPathMonitor()
    }

    private func setupPathMonitor() {
        pathMonitor = NWPathMonitor()
        
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path: path)
            }
        }
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // Start path monitoring
        pathMonitor?.start(queue: monitorQueue)
        
        // Start periodic speed tests
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                await self.performNetworkSpeedTest()
            }
        }
        
        // Initial status update
        if let path = pathMonitor?.currentPath {
            updateNetworkStatus(path: path)
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        pathMonitor?.cancel()
        timer?.invalidate()
        timer = nil
    }
    
    private func updateNetworkStatus(path: NWPath) {
        isConnected = path.status == .satisfied
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else {
            connectionType = .unknown
        }
        
        // Update network quality based on path properties
        updateNetworkQuality(path: path)
    }
    
    private func updateNetworkQuality(path: NWPath) {
        if !isConnected {
            networkQuality = .unknown
            return
        }
        
        // Analyze path characteristics
        var qualityScore = 100
        
        if path.isExpensive {
            qualityScore -= 20
        }
        
        if path.isConstrained {
            qualityScore -= 30
        }
        
        // Map score to quality
        switch qualityScore {
        case 90...100:
            networkQuality = .excellent
        case 70..<90:
            networkQuality = .good
        case 50..<70:
            networkQuality = .fair
        case 0..<50:
            networkQuality = .poor
        default:
            networkQuality = .unknown
        }
    }
    
    
    private func performNetworkSpeedTest() async {
        guard isConnected else { return }
        
        let testURL = URL(string: "https://httpbin.org/bytes/1048576")! // 1MB test file
        
        do {
            let startTime = Date()
            let (data, _) = try await URLSession.shared.data(from: testURL)
            let endTime = Date()
            
            let duration = endTime.timeIntervalSince(startTime)
            let bytesDownloaded = Double(data.count)
            let mbps = (bytesDownloaded * 8) / (duration * 1_000_000) // Convert to Mbps
            
            await MainActor.run {
                self.downloadSpeed = mbps
                self.updateLatency()
            }
            
        } catch {
            print("Network speed test failed: \(error)")
        }
    }
    
    private func updateLatency() {
        // Simple ping test to measure latency
        let pingURL = URL(string: "https://8.8.8.8")!
        let startTime = Date()
        
        URLSession.shared.dataTask(with: pingURL) { _, _, _ in
            let endTime = Date()
            let latencyMs = endTime.timeIntervalSince(startTime) * 1000
            
            DispatchQueue.main.async {
                self.latency = latencyMs
            }
        }.resume()
    }
    
    func getNetworkAnalysis() -> String {
        var analysis = "🌐 Network Analysis:\n\n"
        
        analysis += "📊 Connection Status: \(isConnected ? "Connected" : "Disconnected")\n"
        analysis += "🔗 Connection Type: \(connectionType.rawValue)\n"
        analysis += "⭐ Network Quality: \(networkQuality.rawValue)\n"
        
        if isConnected {
            analysis += "⬇️ Download Speed: \(String(format: "%.1f", downloadSpeed)) Mbps\n"
            analysis += "📶 Latency: \(String(format: "%.0f", latency)) ms\n"
            
            analysis += "\n💡 Recommendations:\n"
            
            switch networkQuality {
            case .excellent:
                analysis += "• Network performance is optimal\n"
            case .good:
                analysis += "• Good network performance for most tasks\n"
            case .fair:
                analysis += "• Consider moving closer to WiFi router\n"
                analysis += "• Close bandwidth-heavy applications\n"
            case .poor:
                analysis += "• Poor network performance detected\n"
                analysis += "• Check WiFi signal strength\n"
                analysis += "• Consider ethernet connection\n"
                analysis += "• Contact ISP if issues persist\n"
            case .unknown:
                analysis += "• Unable to determine network quality\n"
            }
            
            if latency > 100 {
                analysis += "• High latency detected - check network congestion\n"
            }
            
            if downloadSpeed < 10 {
                analysis += "• Slow download speed - check internet plan\n"
            }
        } else {
            analysis += "\n❌ No network connection available\n"
            analysis += "• Check WiFi or ethernet connection\n"
            analysis += "• Verify network credentials\n"
            analysis += "• Try restarting network adapter\n"
        }
        
        return analysis
    }
}
