//
//  FloatingPanelManager.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 17/06/2025.
//

import Foundation
import SwiftUI
import AppKit
import Combine

@MainActor
class FloatingPanelManager: ObservableObject {
    @Published var panels: [FloatingPanel] = []
    @Published var isQuickStatsVisible = false
    @Published var isCPUMonitorVisible = false
    @Published var isBatteryMonitorVisible = false
    @Published var isAIChatVisible = false
    
    private var windowControllers: [String: NSWindowController] = [:]
    private var windowDelegates: [String: WindowDelegate] = [:]
    
    // Dependencies
    private var smithAgent: SmithAgent?
    private var cpuMonitor: CPUMonitor?
    private var batteryMonitor: BatteryMonitor?
    private var memoryMonitor: MemoryMonitor?
    private let defaults = UserDefaults.standard

    init() {
        setupDefaultPanels()
        loadUserPreferences()
        restoreVisiblePanels()
    }
    
    // MARK: - Setup
    func setDependencies(smithAgent: SmithAgent, cpuMonitor: CPUMonitor, batteryMonitor: BatteryMonitor, memoryMonitor: MemoryMonitor) {
        self.smithAgent = smithAgent
        self.cpuMonitor = cpuMonitor
        self.batteryMonitor = batteryMonitor
        self.memoryMonitor = memoryMonitor
    }
    
    private func setupDefaultPanels() {
        panels = [
            FloatingPanel(
                id: "quick-stats",
                title: "Quick Stats",
                description: "System overview at a glance",
                icon: "chart.bar.fill",
                defaultSize: CGSize(width: 300, height: 200),
                level: .floating,
                isResizable: false
            ),
            FloatingPanel(
                id: "cpu-monitor",
                title: "CPU Monitor",
                description: "Real-time CPU performance",
                icon: "cpu.fill",
                defaultSize: CGSize(width: 400, height: 300),
                level: .floating,
                isResizable: true
            ),
            FloatingPanel(
                id: "battery-monitor",
                title: "Battery Monitor",
                description: "Battery health and power usage",
                icon: "battery.100.circle.fill",
                defaultSize: CGSize(width: 350, height: 250),
                level: .floating,
                isResizable: true
            ),
            FloatingPanel(
                id: "ai-chat",
                title: "Smith AI Chat",
                description: "Quick AI assistant access",
                icon: "brain.head.profile",
                defaultSize: CGSize(width: 500, height: 400),
                level: .floating,
                isResizable: true
            ),
            FloatingPanel(
                id: "system-alerts",
                title: "System Alerts",
                description: "Real-time system notifications",
                icon: "exclamationmark.triangle.fill",
                defaultSize: CGSize(width: 350, height: 200),
                level: .statusBar,
                isResizable: false
            )
        ]
    }

    // MARK: - Preferences
    private func loadUserPreferences() {
        isQuickStatsVisible = defaults.bool(forKey: "smith.panel.quick-stats.visible")
        isCPUMonitorVisible = defaults.bool(forKey: "smith.panel.cpu-monitor.visible")
        isBatteryMonitorVisible = defaults.bool(forKey: "smith.panel.battery-monitor.visible")
        isAIChatVisible = defaults.bool(forKey: "smith.panel.ai-chat.visible")
    }

    private func restoreVisiblePanels() {
        if isQuickStatsVisible { showPanel("quick-stats") }
        if isCPUMonitorVisible { showPanel("cpu-monitor") }
        if isBatteryMonitorVisible { showPanel("battery-monitor") }
        if isAIChatVisible { showPanel("ai-chat") }
    }

    private func saveVisibility(_ panelId: String, isVisible: Bool) {
        defaults.set(isVisible, forKey: "smith.panel.\(panelId).visible")
        defaults.synchronize()
    }

    private func saveWindowFrame(for panelId: String) {
        guard let window = windowControllers[panelId]?.window else { return }
        let frameString = NSStringFromRect(window.frame)
        defaults.set(frameString, forKey: "smith.panel.\(panelId).frame")
    }

    private func loadWindowFrame(for panelId: String) -> NSRect? {
        guard let frameString = defaults.string(forKey: "smith.panel.\(panelId).frame") else {
            return nil
        }
        return NSRectFromString(frameString)
    }
    
    // MARK: - Panel Management
    func showPanel(_ panelId: String) {
        guard let panel = panels.first(where: { $0.id == panelId }) else { return }
        
        if windowControllers[panelId] != nil {
            // Panel already exists, bring to front
            windowControllers[panelId]?.window?.makeKeyAndOrderFront(nil)
            return
        }
        
        let contentView = createContentView(for: panel)
        let window = createWindow(for: panel, with: contentView)
        if let savedFrame = loadWindowFrame(for: panel.id) {
            window.setFrame(savedFrame, display: false)
        }
        let windowController = NSWindowController(window: window)
        
        windowControllers[panelId] = windowController
        windowController.showWindow(nil)

        updatePanelVisibility(panelId, isVisible: true)
        saveWindowFrame(for: panelId)
    }

    func hidePanel(_ panelId: String) {
        if let _ = windowControllers[panelId] {
            saveWindowFrame(for: panelId)
        }
        windowControllers[panelId]?.close()
        windowControllers.removeValue(forKey: panelId)
        windowDelegates.removeValue(forKey: panelId)
        updatePanelVisibility(panelId, isVisible: false)
    }
    
    func togglePanel(_ panelId: String) {
        if windowControllers[panelId] != nil {
            hidePanel(panelId)
        } else {
            showPanel(panelId)
        }
    }
    
    func closeAllPanels() {
        for (panelId, _) in windowControllers {
            hidePanel(panelId)
        }
    }
    
    private func updatePanelVisibility(_ panelId: String, isVisible: Bool) {
        switch panelId {
        case "quick-stats":
            isQuickStatsVisible = isVisible
        case "cpu-monitor":
            isCPUMonitorVisible = isVisible
        case "battery-monitor":
            isBatteryMonitorVisible = isVisible
        case "ai-chat":
            isAIChatVisible = isVisible
        default:
            break
        }
        saveVisibility(panelId, isVisible: isVisible)
    }
    
    // MARK: - Window Creation
    private func createWindow(for panel: FloatingPanel, with contentView: any View) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: panel.defaultSize),
            styleMask: panel.isResizable ? [.titled, .closable, .miniaturizable, .resizable] : [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = panel.title
        window.contentView = NSHostingView(rootView: AnyView(contentView))
        window.level = panel.level
        window.isReleasedWhenClosed = false
        window.center()
        
        // Set window properties
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor.clear
        
        // Create and store delegate for cleanup
        let delegate = WindowDelegate(panelManager: self, panelId: panel.id)
        windowDelegates[panel.id] = delegate
        window.delegate = delegate
        
        return window
    }
    
    @ViewBuilder
    private func createContentView(for panel: FloatingPanel) -> some View {
        switch panel.id {
        case "quick-stats":
            FloatingQuickStatsView()
                .environmentObject(smithAgent ?? SmithAgent())
                .environmentObject(cpuMonitor ?? CPUMonitor())
                .environmentObject(batteryMonitor ?? BatteryMonitor())
        case "cpu-monitor":
            FloatingCPUMonitorView()
                .environmentObject(cpuMonitor ?? CPUMonitor())
        case "battery-monitor":
            FloatingBatteryMonitorView()
                .environmentObject(batteryMonitor ?? BatteryMonitor())
        case "ai-chat":
            FloatingAIChatView()
                .environmentObject(smithAgent ?? SmithAgent())
        case "system-alerts":
            FloatingSystemAlertsView()
                .environmentObject(smithAgent ?? SmithAgent())
        default:
            Text("Panel not found")
                .frame(width: 200, height: 100)
        }
    }
    
    // MARK: - Position Management
    func positionPanel(_ panelId: String, at position: PanelPosition) {
        guard let window = windowControllers[panelId]?.window,
              let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        
        let newOrigin: NSPoint
        
        switch position {
        case .topLeft:
            newOrigin = NSPoint(x: screenFrame.minX + 20, y: screenFrame.maxY - windowFrame.height - 20)
        case .topRight:
            newOrigin = NSPoint(x: screenFrame.maxX - windowFrame.width - 20, y: screenFrame.maxY - windowFrame.height - 20)
        case .bottomLeft:
            newOrigin = NSPoint(x: screenFrame.minX + 20, y: screenFrame.minY + 20)
        case .bottomRight:
            newOrigin = NSPoint(x: screenFrame.maxX - windowFrame.width - 20, y: screenFrame.minY + 20)
        case .center:
            newOrigin = NSPoint(
                x: screenFrame.midX - windowFrame.width / 2,
                y: screenFrame.midY - windowFrame.height / 2
            )
        case .custom(let point):
            newOrigin = point
        }
        
        window.setFrameOrigin(newOrigin)
    }
    
    // MARK: - Quick Access Methods
    func showQuickStats() {
        showPanel("quick-stats")
        positionPanel("quick-stats", at: .topRight)
    }
    
    func showCPUMonitor() {
        showPanel("cpu-monitor")
        positionPanel("cpu-monitor", at: .topLeft)
    }
    
    func showBatteryMonitor() {
        showPanel("battery-monitor")
        positionPanel("battery-monitor", at: .bottomRight)
    }
    
    func showAIChat() {
        showPanel("ai-chat")
        positionPanel("ai-chat", at: .center)
    }
}

// MARK: - Window Delegate
class WindowDelegate: NSObject, NSWindowDelegate {
    weak var panelManager: FloatingPanelManager?
    let panelId: String
    
    init(panelManager: FloatingPanelManager, panelId: String) {
        self.panelManager = panelManager
        self.panelId = panelId
    }

    func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            panelManager?.hidePanel(panelId)
        }
    }

    func windowDidMove(_ notification: Notification) {
        Task { @MainActor in
            panelManager?.saveWindowFrame(for: panelId)
        }
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        Task { @MainActor in
            panelManager?.saveWindowFrame(for: panelId)
        }
    }
}

// MARK: - Floating Panel Views
struct FloatingQuickStatsView: View {
    @EnvironmentObject var smithAgent: SmithAgent
    @EnvironmentObject var cpuMonitor: CPUMonitor
    @EnvironmentObject var batteryMonitor: BatteryMonitor
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.cyan)
                Text("Smith Quick Stats")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                FloatingQuickStatRow(
                    icon: "cpu.fill",
                    title: "CPU",
                    value: "\(Int(cpuMonitor.cpuUsage))%",
                    color: cpuMonitor.cpuUsage > 80 ? .red : cpuMonitor.cpuUsage > 60 ? .orange : .green
                )
                
                FloatingQuickStatRow(
                    icon: "battery.100",
                    title: "Battery",
                    value: "\(Int(batteryMonitor.batteryLevel))%",
                    color: batteryMonitor.batteryLevel < 20 ? .red : batteryMonitor.batteryLevel < 50 ? .orange : .green
                )
                
                FloatingQuickStatRow(
                    icon: "brain",
                    title: "AI Status",
                    value: smithAgent.isFoundationModelsAvailable ? "Ready" : "Offline",
                    color: smithAgent.isFoundationModelsAvailable ? .green : .red
                )
                
                FloatingQuickStatRow(
                    icon: "gearshape.2",
                    title: "Performance",
                    value: "\(Int(smithAgent.getPerformanceScore()))/100",
                    color: smithAgent.getPerformanceScore() > 80 ? .green : smithAgent.getPerformanceScore() > 60 ? .orange : .red
                )
            }
            
            HStack {
                Button("Full Analysis") {
                    Task {
                        await smithAgent.analyzeSystemHealth()
                    }
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                
                Button("Close") {
                    NSApp.keyWindow?.close()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            cpuMonitor.startMonitoring()
            batteryMonitor.startMonitoring()
        }
    }
}

struct FloatingCPUMonitorView: View {
    @EnvironmentObject var cpuMonitor: CPUMonitor
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "cpu.fill")
                    .foregroundColor(.green)
                Text("CPU Monitor")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(cpuMonitor.cpuUsage))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            // CPU Usage Chart
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.gray.opacity(0.2))
                            .frame(height: 8)
                            .clipShape(Capsule())
                        
                        Rectangle()
                            .fill(.green.gradient)
                            .frame(width: geometry.size.width * (cpuMonitor.cpuUsage / 100), height: 8)
                            .clipShape(Capsule())
                            .animation(.easeInOut(duration: 0.5), value: cpuMonitor.cpuUsage)
                    }
                }
                .frame(height: 8)
                
                // Per-core usage
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(Array(cpuMonitor.perCoreUsage.enumerated()), id: \.offset) { index, usage in
                        VStack(spacing: 2) {
                            Text("Core \(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Text("\(Int(usage))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(usage > 80 ? .red : usage > 60 ? .orange : .green)
                        }
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            
            // Top processes
            VStack(alignment: .leading, spacing: 4) {
                Text("Top Processes")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(cpuMonitor.processes.prefix(5)) { process in
                    HStack {
                        Text(process.name)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f", process.cpuUsage))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(process.cpuUsage > 10 ? .red : .primary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            cpuMonitor.startMonitoring()
        }
    }
}

struct FloatingBatteryMonitorView: View {
    @EnvironmentObject var batteryMonitor: BatteryMonitor
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "battery.100.circle.fill")
                    .foregroundColor(.yellow)
                Text("Battery Monitor")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(batteryMonitor.batteryLevel))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            }
            
            // Battery visual
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 60, height: 30)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.yellow.gradient)
                        .frame(width: 54 * (batteryMonitor.batteryLevel / 100), height: 24)
                        .animation(.easeInOut(duration: 0.5), value: batteryMonitor.batteryLevel)
                    
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 3, height: 12)
                        .offset(x: 32)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(batteryMonitor.isCharging ? "Charging" : "On Battery")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(batteryMonitor.isCharging ? .green : .primary)
                    
                    Text(batteryMonitor.isCharging ? "Charging..." : "\(batteryMonitor.timeRemaining) remaining")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Battery health and stats
            VStack(spacing: 8) {
                HStack {
                    Text("Health")
                    Spacer()
                    Text("95%")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Cycles")
                    Spacer()
                    Text("\(batteryMonitor.cycleCount)")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Temperature")
                    Spacer()
                    Text("\(String(format: "%.1f", batteryMonitor.temperature))°C")
                        .foregroundColor(batteryMonitor.temperature > 35 ? .orange : .gray)
                }
                
                HStack {
                    Text("Power Usage")
                    Spacer()
                    Text("\(String(format: "%.1f", batteryMonitor.powerUsage))W")
                        .foregroundColor(.gray)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            batteryMonitor.startMonitoring()
        }
    }
}

struct FloatingAIChatView: View {
    @EnvironmentObject var smithAgent: SmithAgent
    @State private var messageText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.cyan)
                Text("Smith AI")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Circle()
                    .fill(smithAgent.isFoundationModelsAvailable ? .green : .red)
                    .frame(width: 8, height: 8)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(smithAgent.messages.suffix(5)) { message in
                        HStack {
                            if message.isUser {
                                Spacer()
                                Text(message.content)
                                    .padding(8)
                                    .background(.blue.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                                    .foregroundColor(.blue)
                            } else {
                                Text(message.content)
                                    .padding(8)
                                    .background(.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 200)
            
            // Input
            HStack {
                TextField("Ask Smith...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        messageText = ""
        Task {
            await smithAgent.sendMessage(message)
        }
    }
}

struct FloatingSystemAlertsView: View {
    @EnvironmentObject var smithAgent: SmithAgent
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("System Alerts")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if smithAgent.getCurrentAnomalies().isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    Text("All systems normal")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(smithAgent.getCurrentAnomalies().prefix(3).enumerated()), id: \.offset) { index, anomaly in
                        HStack {
                            Circle()
                                .fill(anomaly.alertSeverity.color)
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(anomaly.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Text(anomaly.description)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Types
struct FloatingPanel: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let defaultSize: CGSize
    let level: NSWindow.Level
    let isResizable: Bool
}

enum PanelPosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case center
    case custom(NSPoint)
}

// MARK: - Floating Panel Specific Components
struct FloatingQuickStatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Extensions
extension SystemAnomaly {
    var alertSeverity: AlertSeverity {
        // Use a simple mapping since priority property might not be available
        return .warning
    }
}

enum AlertSeverity {
    case info, warning, error, critical
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}
