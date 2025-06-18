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
import os.log
import CoreWLAN

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = false
    @Published var connectionType: ConnectionType = .unknown
    @Published var networkName: String = ""
    @Published var networkQuality: NetworkQuality = .unknown
    @Published var downloadSpeed: Double = 0.0
    @Published var uploadSpeed: Double = 0.0
    @Published var latency: Double = 0.0
    @Published var isMonitoring = false
    
    private var pathMonitor: NWPathMonitor?
    private var monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var timer: Timer?
    private let logger = Logger(subsystem: "com.motherofbrand.Smith", category: "NetworkMonitor")

    private let testURLKey = "smith.networktest.url"
    private let pingHostKey = "smith.networktest.pinghost"
    
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

        // Update network name
        networkName = fetchNetworkName(for: path) ?? ""

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
        let defaults = UserDefaults.standard
        let testURLString = defaults.string(forKey: testURLKey) ?? "https://httpbin.org/bytes/1048576"

        guard let testURL = URL(string: testURLString) else {
            logger.error("Invalid network test URL: \(testURLString, privacy: .public)")
            networkQuality = .unknown
            return
        }

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 5
        let session = URLSession(configuration: config)

        do {
            let startTime = Date()
            let (data, _) = try await session.data(from: testURL)
            let endTime = Date()

            let duration = endTime.timeIntervalSince(startTime)
            let bytesDownloaded = Double(data.count)
            let mbps = (bytesDownloaded * 8) / (duration * 1_000_000) // Convert to Mbps

            await MainActor.run {
                self.downloadSpeed = mbps
                self.updateLatency(session: session)
            }

        } catch {
            logger.error("Network speed test failed: \(error.localizedDescription, privacy: .public)")
            await MainActor.run {
                self.networkQuality = .unknown
                self.downloadSpeed = 0
                self.latency = 0
            }
        }
    }

    private func updateLatency(session: URLSession? = nil) {
        let defaults = UserDefaults.standard
        let pingHost = defaults.string(forKey: pingHostKey) ?? "https://8.8.8.8"

        guard let pingURL = URL(string: pingHost) else {
            logger.error("Invalid ping host: \(pingHost, privacy: .public)")
            latency = 0
            return
        }

        let session = session ?? {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 5
            return URLSession(configuration: config)
        }()

        let startTime = Date()

        session.dataTask(with: pingURL) { _, _, error in
            let endTime = Date()
            if error != nil {
                self.logger.error("Ping request failed: \(error!.localizedDescription, privacy: .public)")
                DispatchQueue.main.async {
                    self.latency = 0
                }
                return
            }

            let latencyMs = endTime.timeIntervalSince(startTime) * 1000

            DispatchQueue.main.async {
                self.latency = latencyMs
            }
        }.resume()
    }

    private func fetchNetworkName(for path: NWPath) -> String? {
        if path.usesInterfaceType(.wifi) {
            return CWWiFiClient.shared().interface()?.ssid()
        }

        if let interface = path.availableInterfaces.first(where: { path.usesInterfaceType($0.type) }) {
            return interface.name
        }

        return nil
    }
    
    func getNetworkAnalysis() -> String {
        var analysis = "🌐 Network Analysis:\n\n"
        
        analysis += "📊 Connection Status: \(isConnected ? "Connected" : "Disconnected")\n"
        analysis += "🔗 Connection Type: \(connectionType.rawValue)\n"
        if !networkName.isEmpty {
            analysis += "📶 Network Name: \(networkName)\n"
        }
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
