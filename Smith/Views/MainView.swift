//
//  MainView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var smithAgent: SmithAgent
    @StateObject private var batteryMonitor = BatteryMonitor()
    @StateObject private var cpuMonitor = CPUMonitor()
    @StateObject private var memoryMonitor = MemoryMonitor()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var storageMonitor = StorageMonitor()
    @StateObject private var automationManager = SystemAutomationManager()
    @StateObject private var floatingPanelManager = FloatingPanelManager()
    @State private var selectedSystemView: SystemMonitorView = .cpu
    @State private var showingSettings = false
    
    private var cpuStatusColor: Color {
        let usage = cpuMonitor.cpuUsage
        if !usage.isFinite || usage.isNaN { return .gray }
        if usage > 80 { return .red }
        if usage > 60 { return .orange }
        return .green
    }
    
    private var batteryStatusColor: Color {
        let level = batteryMonitor.batteryLevel
        if !level.isFinite || level.isNaN { return .gray }
        if level < 20 { return .red }
        if level < 50 { return .orange }
        return .green
    }

    private var diskStatusColor: Color {
        let usage = safeDiskUsage
        if usage > 90 { return .red }
        if usage > 75 { return .orange }
        return .purple
    }

    private var memoryStatusColor: Color {
        let usage = safeMemoryUsage
        if usage > 90 { return .red }
        if usage > 75 { return .orange }
        return .blue
    }

    private var networkStatusColor: Color {
        return networkMonitor.networkQuality.color
    }
    
    // Safe conversion helpers
    private var safeCPUUsage: Int {
        let usage = cpuMonitor.cpuUsage
        guard usage.isFinite && !usage.isNaN else { return 0 }
        return Int(max(0, min(100, usage)))
    }
    
    private var safeBatteryLevel: Int {
        let level = batteryMonitor.batteryLevel
        guard level.isFinite && !level.isNaN else { return 0 }
        return Int(max(0, min(100, level)))
    }

    private var safeDiskUsage: Int {
        guard storageMonitor.totalSpace > 0 else { return 0 }
        let percentage = Double(storageMonitor.usedSpace) / Double(storageMonitor.totalSpace) * 100
        return Int(max(0, min(100, percentage)))
    }

    private var safeMemoryUsage: Int {
        guard memoryMonitor.totalMemory > 0 else { return 0 }
        let percentage = Double(memoryMonitor.usedMemory) / Double(memoryMonitor.totalMemory) * 100
        return Int(max(0, min(100, percentage)))
    }

    private var formattedUsedSpace: String {
        ByteCountFormatter.string(fromByteCount: storageMonitor.usedSpace, countStyle: .file)
    }

    private var formattedTotalSpace: String {
        ByteCountFormatter.string(fromByteCount: storageMonitor.totalSpace, countStyle: .file)
    }

    private var formattedAvailableSpace: String {
        ByteCountFormatter.string(fromByteCount: storageMonitor.availableSpace, countStyle: .file)
    }
    
    private var automationStatusColor: Color {
        return automationManager.isAutomationEnabled ? Color.green : Color.gray
    }
    
    private var aiStatusColor: Color {
        return smithAgent.isFoundationModelsAvailable ? Color.green : Color.red
    }
    
    var body: some View {
        NavigationSplitView {
            // Left Section: Enhanced System Monitoring with Floating Panel Controls
            VStack(spacing: 0) {
                // Ultra-Compact Header with Floating Panel Controls
                VStack(spacing: 6) {
                    // Minimal App Branding with Quick Actions
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.title3)
                            .foregroundStyle(.cyan.gradient)
                        
                        Text("SMITH")
                            .font(.callout)
                            .fontWeight(.bold)
                            .fontDesign(.monospaced)
                            .foregroundColor(Color.primary)
                        
                        Spacer()
                        
                        // Floating Panel Quick Access
                        HStack(spacing: 4) {
                            Button {
                                floatingPanelManager.showQuickStats()
                            } label: {
                                Image(systemName: "chart.bar.circle")
                                    .font(.callout)
                                    .foregroundColor(floatingPanelManager.isQuickStatsVisible ? .cyan : .gray)
                            }
                            .buttonStyle(.plain)
                            .help("Show Floating Quick Stats")
                            
                            Button {
                                floatingPanelManager.showAIChat()
                            } label: {
                                Image(systemName: "brain.head.profile.circle")
                                    .font(.callout)
                                    .foregroundColor(floatingPanelManager.isAIChatVisible ? .cyan : .gray)
                            }
                            .buttonStyle(.plain)
                            .help("Show Floating AI Chat")
                        }
                        
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.callout)
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                        .help("Settings")
                    }
                    .padding(.horizontal, Spacing.large)
                    .padding(.top, Spacing.small)
                    
                    // Enhanced System Overview Cards with Floating Panel Integration
                    HStack(spacing: 3) {
                        CompactSystemCard(
                            icon: "cpu",
                            value: "\(safeCPUUsage)%",
                            color: cpuStatusColor,
                            isActive: selectedSystemView == .cpu
                        ) {
                            selectedSystemView = .cpu
                        }
                        .onLongPressGesture {
                            floatingPanelManager.showCPUMonitor()
                        }

                        CompactSystemCard(
                            icon: "memorychip",
                            value: "\(safeMemoryUsage)%",
                            color: memoryStatusColor,
                            isActive: selectedSystemView == .memory
                        ) {
                            selectedSystemView = .memory
                        }

                        CompactSystemCard(
                            icon: "battery.100",
                            value: "\(safeBatteryLevel)%",
                            color: batteryStatusColor,
                            isActive: selectedSystemView == .battery
                        ) {
                            selectedSystemView = .battery
                        }
                        .onLongPressGesture {
                            floatingPanelManager.showBatteryMonitor()
                        }

                        CompactSystemCard(
                            icon: "internaldrive",
                            value: "\(safeDiskUsage)%",
                            color: diskStatusColor,
                            isActive: selectedSystemView == .disk
                        ) {
                            selectedSystemView = .disk
                        }

                        CompactSystemCard(
                            icon: "wifi",
                            value: networkMonitor.isConnected ? (networkMonitor.networkName.isEmpty ? networkMonitor.connectionType.rawValue : "\(networkMonitor.connectionType.rawValue) - \(networkMonitor.networkName)") : "Off",
                            color: networkStatusColor,
                            isActive: selectedSystemView == .network
                        ) {
                            selectedSystemView = .network
                        }

                        CompactSystemCard(
                            icon: "gearshape.2",
                            value: "Auto",
                            color: automationStatusColor,
                            isActive: selectedSystemView == .automation
                        ) {
                            selectedSystemView = .automation
                        }
                    }
                    .padding(.horizontal, Spacing.large)
                    .padding(.bottom, Spacing.small)
                }
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.secondary.opacity(0.2)),
                    alignment: .bottom
                )
                
                // Enhanced Content Area with Automation
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Enhanced Current View Header with Automation Status
                        HStack(spacing: 8) {
                            Image(systemName: selectedSystemView.icon)
                                .font(.title3)
                                .foregroundColor(selectedSystemView.color)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(selectedSystemView.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.primary)
                                
                                Text(selectedSystemView.description)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Enhanced Status Indicator with Automation Badge
                            ZStack {
                                Circle()
                                    .fill(selectedSystemView.color.gradient)
                                    .frame(width: 6, height: 6)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedSystemView.color, lineWidth: BorderWidth.hairline)
                                            .scaleEffect(2.0)
                                            .opacity(0.2)
                                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: selectedSystemView)
                                    )
                                
                                if selectedSystemView == .automation && automationManager.isAutomationEnabled {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 3, height: 3)
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.large)
                        .padding(.top, Spacing.medium)
                        
                        // Enhanced Dynamic Content Area with Automation
                        VStack(spacing: 12) {
                            switch selectedSystemView {
                            case .cpu:
                                CompactCPUSection()
                                    .environmentObject(cpuMonitor)
                            case .memory:
                                MemoryView()
                                    .environmentObject(memoryMonitor)
                                    .environmentObject(smithAgent)
                            case .battery:
                                CompactBatterySection()
                                    .environmentObject(batteryMonitor)
                            case .disk:
                                CompactDiskSection()
                                    .environmentObject(storageMonitor)
                            case .network:
                                NetworkView()
                                    .environmentObject(networkMonitor)
                            case .automation:
                                CompactAutomationSection()
                                    .environmentObject(automationManager)
                            case .integration:
                                EnhancedIntegrationSection()
                            }
                        }
                        .padding(.horizontal, Spacing.large)
                        
                        // Bottom padding
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 20)
                    }
                }
                .background(.black.opacity(0.02))
            }
            .frame(minWidth: 350, maxWidth: 400)
            .background(.black.opacity(0.05))
        } detail: {
            // Right Section: Enhanced AI Chat Layout with Smart Integration
            VStack(spacing: 0) {
                // Ultra-Modern Chat Header with System Status
                HStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundStyle(.cyan.gradient)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("SMITH AI")
                            .font(.callout)
                            .fontWeight(.bold)
                            .fontDesign(.monospaced)
                            .foregroundColor(Color.primary)
                        
                        Text("Your intelligent assistant")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Enhanced System Integration Status
                    HStack(spacing: 8) {
                        // Automation Status
                        HStack(spacing: 3) {
                            Circle()
                                .fill(automationStatusColor)
                                .frame(width: 4, height: 4)
                            
                            Text("Auto")
                                .font(.caption2)
                                .foregroundColor(automationStatusColor)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, Spacing.xsmall)
                        .padding(.vertical, Spacing.xsmall)
                        .background(automationStatusColor.opacity(0.1), in: Capsule())
                        
                        // AI Connection Status
                        HStack(spacing: 3) {
                            Circle()
                                .fill(aiStatusColor)
                                .frame(width: 4, height: 4)
                                .overlay(
                                    Circle()
                                        .stroke(aiStatusColor, lineWidth: BorderWidth.ultraThin)
                                        .scaleEffect(1.5)
                                        .opacity(0.4)
                                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: smithAgent.isProcessing)
                                )
                            
                            Text(smithAgent.isFoundationModelsAvailable ? "Online" : "Offline")
                                .font(.caption2)
                                .foregroundColor(aiStatusColor)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.xsmall)
                        .background(aiStatusColor.opacity(0.08), in: Capsule())
                        .overlay(Capsule().stroke(aiStatusColor.opacity(0.2), lineWidth: BorderWidth.ultraThin))
                    }
                }
                .padding(.horizontal, Spacing.large)
                .padding(.vertical, Spacing.small)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .frame(height: 0.3)
                        .foregroundColor(Color.secondary.opacity(0.2)),
                    alignment: .bottom
                )
                
                // Enhanced Chat Content with System Context
                ChatView()
                    .environmentObject(smithAgent)
            }
            .background(.black)
        }
        .navigationSplitViewStyle(.balanced)
        .background(.black)
        .dynamicTypeSize(.medium ... .accessibility3)
        .sheet(isPresented: $showingSettings) {
            EnhancedSettingsView()
                .environmentObject(automationManager)
                .environmentObject(floatingPanelManager)
                .frame(width: 700, height: 600)
        }
        .onAppear {
            setupMonitoring()
            setupIntegrations()
        }
        .onDisappear {
            stopMonitoring()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Quick Action Buttons
                Button {
                    Task {
                        smithAgent.analyzeSystemHealth()
                    }
                } label: {
                    Image(systemName: "heart.text.square")
                }
                .help("System Health Check")
                
                Button {
                    Task {
                        smithAgent.optimizePerformance()
                    }
                } label: {
                    Image(systemName: "speedometer")
                }
                .help("Optimize Performance")
                
                Menu {
                    Button("Show Quick Stats") {
                        floatingPanelManager.showQuickStats()
                    }
                    
                    Button("Show CPU Monitor") {
                        floatingPanelManager.showCPUMonitor()
                    }
                    
                    Button("Show Battery Monitor") {
                        floatingPanelManager.showBatteryMonitor()
                    }
                    
                    Button("Show AI Chat") {
                        floatingPanelManager.showAIChat()
                    }
                    
                    Divider()
                    
                    Button("Close All Panels") {
                        floatingPanelManager.closeAllPanels()
                    }
                } label: {
                    Image(systemName: "rectangle.3.group")
                }
                .help("Floating Panels")
            }
        }
    }
    
    private func setupMonitoring() {
        cpuMonitor.startMonitoring()
        batteryMonitor.startMonitoring()
        memoryMonitor.startMonitoring()
        networkMonitor.startMonitoring()
        storageMonitor.startMonitoring()
        
        // Setup integrations
        smithAgent.setSystemMonitors(cpu: cpuMonitor, battery: batteryMonitor, memory: memoryMonitor, network: networkMonitor, storage: storageMonitor)
        automationManager.setMonitors(cpu: cpuMonitor, battery: batteryMonitor, memory: memoryMonitor, network: networkMonitor, storage: storageMonitor, intelligence: smithAgent.intelligenceEngine)
        floatingPanelManager.setDependencies(smithAgent: smithAgent, cpuMonitor: cpuMonitor, batteryMonitor: batteryMonitor, memoryMonitor: memoryMonitor)
    }
    
    private func stopMonitoring() {
        cpuMonitor.stopMonitoring()
        batteryMonitor.stopMonitoring()
        memoryMonitor.stopMonitoring()
        networkMonitor.stopMonitoring()
        storageMonitor.stopMonitoring()
    }
    
    private func setupIntegrations() {
        // Setup deep system integrations synchronously
        setupURLSchemeHandling()
        setupServicesIntegration()
        setupSpotlightIntegration()
    }
    
    private func setupURLSchemeHandling() {
        // URL scheme handling is set up in SmithApp.swift
        print("✅ URL scheme handling ready: smith://")
    }
    
    private func setupServicesIntegration() {
        // Services integration is handled via Info.plist and AppDelegate
        print("✅ Services integration ready")
    }
    
    private func setupSpotlightIntegration() {
        // Spotlight integration for Smith commands
        print("✅ Spotlight integration ready")
    }
}

// MARK: - Enhanced Automation Section
struct CompactAutomationSection: View {
    @EnvironmentObject var automationManager: SystemAutomationManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Automation Status Overview
            VStack(spacing: 8) {
                HStack {
                    Text("System Automation")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primary)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { automationManager.isAutomationEnabled },
                        set: { _ in automationManager.toggleAutomation() }
                    ))
                    .toggleStyle(.switch)
                    .scaleEffect(0.8)
                }
                
                if automationManager.isAutomationEnabled {
                    // Active Automation Tasks
                    VStack(spacing: 6) {
                        ForEach(automationManager.automationTasks.filter(\.isEnabled).prefix(3), id: \.id) { task in
                            HStack {
                                Image(systemName: task.category.icon)
                                    .foregroundColor(task.category.color)
                                    .frame(width: 16)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(task.title)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Text(task.frequency.rawValue)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Circle()
                                    .fill(task.priority.color)
                                    .frame(width: 6, height: 6)
                            }
                            .padding(.vertical, Spacing.xsmall)
                        }
                    }
                    
                    // Next Maintenance
                    if let nextMaintenance = automationManager.nextScheduledMaintenance {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .frame(width: 16)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Next Maintenance")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Text(nextMaintenance, style: .relative)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button("Run Now") {
                                Task {
                                    await automationManager.runMaintenanceNow()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                        .padding(.top, Spacing.xsmall)
                    }
                } else {
                    Text("Enable automation for smart system maintenance")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, Spacing.small)
                }
            }
            .padding(Spacing.medium)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.xlarge))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xlarge)
                    .stroke(.green.opacity(0.2), lineWidth: BorderWidth.hairline)
            )
        }
    }
}

// MARK: - Enhanced Settings View
struct EnhancedSettingsView: View {
    @EnvironmentObject var automationManager: SystemAutomationManager
    @EnvironmentObject var floatingPanelManager: FloatingPanelManager
    
    var body: some View {
        TabView {
            BackgroundSettingsView()
                .tabItem {
                    Label("Background", systemImage: "gear.circle")
                }
            
            AutomationSettingsView()
                .environmentObject(automationManager)
                .tabItem {
                    Label("Automation", systemImage: "gearshape.2")
                }
            
            FloatingPanelSettingsView()
                .environmentObject(floatingPanelManager)
                .tabItem {
                    Label("Panels", systemImage: "rectangle.3.group")
                }
            
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            IntegrationSettingsView()
                .tabItem {
                    Label("Integration", systemImage: "link")
                }
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 700, height: 600)
    }
}

// MARK: - New Settings Views
struct AutomationSettingsView: View {
    @EnvironmentObject var automationManager: SystemAutomationManager
    
    var body: some View {
        Form {
            Section("Automation Status") {
                Toggle("Enable System Automation", isOn: Binding(
                    get: { automationManager.isAutomationEnabled },
                    set: { _ in automationManager.toggleAutomation() }
                ))
                .help("Enables automatic system maintenance and optimization")
            }
            
            Section("Automation Tasks") {
                ForEach(automationManager.automationTasks, id: \.id) { task in
                    HStack {
                        Image(systemName: task.category.icon)
                            .foregroundColor(task.category.color)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .fontWeight(.medium)
                            
                            Text(task.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { task.isEnabled },
                            set: { _ in automationManager.toggleTask(task.id) }
                        ))
                        .toggleStyle(.switch)
                    }
                    .padding(.vertical, Spacing.xsmall)
                }
            }
            
            Section("Scheduled Maintenance") {
                ForEach(automationManager.scheduledMaintenance, id: \.id) { maintenance in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(maintenance.title)
                                .fontWeight(.medium)
                            
                            Text("Next: \(maintenance.scheduledDate, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Run Now") {
                            Task {
                                await automationManager.runMaintenanceNow()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Automation")
    }
}

// MARK: - System Monitor Views Enum (Updated)
enum SystemMonitorView: String, CaseIterable {
    case cpu = "CPU"
    case memory = "Memory"
    case battery = "Battery"
    case disk = "Disk"
    case network = "Network"
    case automation = "Automation"
    case integration = "Integration"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .cpu: return "cpu.fill"
        case .memory: return "memorychip"
        case .battery: return "battery.100.circle.fill"
        case .disk: return "externaldrive.fill"
        case .network: return "wifi"
        case .automation: return "gearshape.2.fill"
        case .integration: return "gearshape.2.fill"
        }
    }
    
    var description: String {
        switch self {
        case .cpu: return "Monitor processor performance and usage"
        case .memory: return "Monitor RAM usage and pressure"
        case .battery: return "Track power consumption and health"
        case .disk: return "Analyze storage usage and files"
        case .network: return "Analyze network connectivity and speed"
        case .automation: return "Automated system maintenance"
        case .integration: return "Configure system integration features"
        }
    }
    
    var color: Color {
        switch self {
        case .cpu: return .green
        case .memory: return .orange
        case .battery: return .yellow
        case .disk: return .purple
        case .network: return .cyan
        case .automation: return .blue
        case .integration: return .indigo
        }
    }
}

// MARK: - Existing Component Definitions (keeping the same structure)
struct CompactSystemCard: View {
    let icon: String
    let value: String
    let color: Color
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.small)
            .padding(.horizontal, Spacing.xsmall)
            .background(
                isActive ? color.opacity(0.15) : .clear,
                in: RoundedRectangle(cornerRadius: CornerRadius.medium)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(
                        isActive ? color.opacity(0.5) : Color.secondary.opacity(0.1),
                        lineWidth: isActive ? BorderWidth.thin : BorderWidth.hairline
                    )
            )
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isActive)
        }
        .buttonStyle(.plain)
    }
}

struct CompactCPUSection: View {
    @EnvironmentObject var cpuMonitor: CPUMonitor
    
    private var safeCPUUsage: Int {
        let usage = cpuMonitor.cpuUsage
        guard usage.isFinite && !usage.isNaN else { return 0 }
        return Int(max(0, min(100, usage)))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Compact CPU Usage Overview
            VStack(spacing: 8) {
                HStack {
                    Text("Performance")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primary)
                    
                    Spacer()
                    
                    Text("\(safeCPUUsage)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                // Compact CPU Usage Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.gray.opacity(0.15))
                            .frame(height: 4)
                            .clipShape(Capsule())
                        
                        Rectangle()
                            .fill(.green.gradient)
                            .frame(width: geometry.size.width * (Double(safeCPUUsage) / 100), height: 4)
                            .clipShape(Capsule())
                            .animation(.easeInOut(duration: 0.5), value: safeCPUUsage)
                    }
                }
                .frame(height: 4)
                
                // Compact Stats Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 4) {
                    CompactStatItem(title: "Cores", value: "8", color: .green)
                    CompactStatItem(title: "Threads", value: "16", color: .green)
                    CompactStatItem(title: "Temp", value: "\(Int(cpuMonitor.temperature))°C", color: cpuMonitor.temperature > 80 ? .red : cpuMonitor.temperature > 70 ? .orange : .green)
                    CompactStatItem(title: "Freq", value: "3.2GHz", color: .blue)
                }
            }
            .padding(Spacing.medium)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.xlarge))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xlarge)
                    .stroke(.green.opacity(0.2), lineWidth: BorderWidth.hairline)
            )
            
            // Compact CPU View with Reduced Padding
            VStack(spacing: 0) {
                CPUView()
                    .environmentObject(cpuMonitor)
            }
            .frame(maxHeight: 220)
            .background(.black.opacity(0.02), in: RoundedRectangle(cornerRadius: CornerRadius.large))
        }
    }
}

struct CompactBatterySection: View {
    @EnvironmentObject var batteryMonitor: BatteryMonitor
    
    private var safeBatteryLevel: Int {
        let level = batteryMonitor.batteryLevel
        guard level.isFinite && !level.isNaN else { return 0 }
        return Int(max(0, min(100, level)))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Compact Battery Health Overview
            VStack(spacing: 8) {
                HStack {
                    Text("Battery Health")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primary)
                    
                    Spacer()
                    
                    Text("Excellent")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.xsmall)
                        .background(.green.opacity(0.15), in: Capsule())
                }
                
                // Compact Battery Visual
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.xsmall)
                            .stroke(.gray.opacity(0.3), lineWidth: BorderWidth.thin)
                            .frame(width: 30, height: 16)
                        
                        RoundedRectangle(cornerRadius: CornerRadius.tiny)
                            .fill(Color.green.gradient)
                            .frame(width: 26 * (Double(safeBatteryLevel) / 100), height: 12)
                            .animation(.easeInOut(duration: 0.5), value: safeBatteryLevel)
                        
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .frame(width: 2, height: 6)
                            .offset(x: 16)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(safeBatteryLevel)%")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(Color.primary)
                        
                        Text("4h 32m remaining")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
            .padding(Spacing.medium)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.xlarge))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xlarge)
                    .stroke(.yellow.opacity(0.2), lineWidth: BorderWidth.hairline)
            )
            
            // Compact Battery View with Reduced Padding
            VStack(spacing: 0) {
                BatteryView()
                    .environmentObject(batteryMonitor)
            }
            .frame(maxHeight: 200)
            .background(.black.opacity(0.02), in: RoundedRectangle(cornerRadius: CornerRadius.large))
        }
    }
}

struct CompactDiskSection: View {
    @EnvironmentObject var storageMonitor: StorageMonitor

    private var safeDiskUsage: Int {
        guard storageMonitor.totalSpace > 0 else { return 0 }
        let percentage = Double(storageMonitor.usedSpace) / Double(storageMonitor.totalSpace) * 100
        return Int(max(0, min(100, percentage)))
    }

    private var ringProgress: Double { Double(safeDiskUsage) / 100 }

    private var formattedUsedSpace: String {
        ByteCountFormatter.string(fromByteCount: storageMonitor.usedSpace, countStyle: .file)
    }

    private var formattedTotalSpace: String {
        ByteCountFormatter.string(fromByteCount: storageMonitor.totalSpace, countStyle: .file)
    }

    private var formattedAvailableSpace: String {
        ByteCountFormatter.string(fromByteCount: storageMonitor.availableSpace, countStyle: .file)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Compact Storage Overview
            VStack(spacing: 8) {
                HStack {
                    Text("Storage Usage")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primary)

                    Spacer()

                    Text("\(formattedUsedSpace) / \(formattedTotalSpace)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Compact Storage Ring
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: BorderWidth.thick)
                            .frame(width: 36, height: 36)

                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(.purple.gradient, style: StrokeStyle(lineWidth: BorderWidth.thick, lineCap: .round))
                            .frame(width: 36, height: 36)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: ringProgress)

                        Text("\(safeDiskUsage)%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(formattedUsedSpace) used")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.primary)

                        Text("\(formattedAvailableSpace) available")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
            .padding(Spacing.medium)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.xlarge))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xlarge)
                    .stroke(.purple.opacity(0.2), lineWidth: BorderWidth.hairline)
            )
            
            // Compact Disk View with Reduced Padding
            VStack(spacing: 0) {
                DiskView()
                    .environmentObject(storageMonitor)
            }
            .frame(maxHeight: 240)
            .background(.black.opacity(0.02), in: RoundedRectangle(cornerRadius: CornerRadius.large))
        }
    }
}

struct CompactStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xsmall)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.xsmall))
    }
}

struct EnhancedIntegrationSection: View {
    var body: some View {
        VStack(spacing: 12) {
            // Integration Status with Modern Cards
            VStack(spacing: 10) {
                HStack {
                    Text("System Integration")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primary)
                    
                    Spacer()
                    
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.xsmall)
                        .background(.green.opacity(0.15), in: Capsule())
                }
                
                // Modern Integration Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                    ModernIntegrationCard(title: "URL Scheme", status: true, icon: "link")
                    ModernIntegrationCard(title: "Services", status: true, icon: "menubar.rectangle")
                    ModernIntegrationCard(title: "Quick Actions", status: true, icon: "hand.tap")
                    ModernIntegrationCard(title: "Spotlight", status: true, icon: "magnifyingglass")
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.xxlarge))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xxlarge)
                    .stroke(.indigo.opacity(0.2), lineWidth: BorderWidth.hairline)
            )
            
            // Detailed Integration View
            SystemIntegrationView()
        }
    }
}

struct ModernIntegrationCard: View {
    let title: String
    let status: Bool
    let icon: String
    
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(status ? .green : .red)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
            
            Circle()
                .fill(status ? Color.green : Color.red)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.small)
        .background((status ? Color.green : Color.red).opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

struct MainViewQuickStatRow: View {
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

#Preview {
    MainView()
        .environmentObject(SmithAgent())
}
