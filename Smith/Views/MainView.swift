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
    
    var body: some View {
        NavigationSplitView {
            // Left Section: Minimized and Enhanced System Monitoring
            VStack(spacing: 0) {
                // Ultra-Compact Header
                VStack(spacing: 6) {
                    // Minimal App Branding
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.title3)
                            .foregroundStyle(.cyan.gradient)
                        
                        Text("SMITH")
                            .font(.callout)
                            .fontWeight(.bold)
                            .fontDesign(.monospaced)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
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
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    
                    // Compact System Overview Cards
                    HStack(spacing: 3) {
                        CompactSystemCard(
                            icon: "cpu",
                            value: "\(safeCPUUsage)%",
                            color: cpuStatusColor,
                            isActive: selectedSystemView == .cpu
                        ) {
                            selectedSystemView = .cpu
                        }
                        
                        CompactSystemCard(
                            icon: "battery.100",
                            value: "\(safeBatteryLevel)%",
                            color: batteryStatusColor,
                            isActive: selectedSystemView == .battery
                        ) {
                            selectedSystemView = .battery
                        }
                        
                        CompactSystemCard(
                            icon: "internaldrive",
                            value: "456GB",
                            color: .purple,
                            isActive: selectedSystemView == .disk
                        ) {
                            selectedSystemView = .disk
                        }
                        
                        CompactSystemCard(
                            icon: "gearshape.2",
                            value: "Config",
                            color: .indigo,
                            isActive: selectedSystemView == .integration
                        ) {
                            selectedSystemView = .integration
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                }
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(.gray.opacity(0.2)),
                    alignment: .bottom
                )
                
                // Enhanced Content Area
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Minimal Current View Header
                        HStack(spacing: 8) {
                            Image(systemName: selectedSystemView.icon)
                                .font(.title3)
                                .foregroundColor(selectedSystemView.color)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(selectedSystemView.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text(selectedSystemView.description)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Pulsing Status Indicator
                            Circle()
                                .fill(selectedSystemView.color.gradient)
                                .frame(width: 6, height: 6)
                                .overlay(
                                    Circle()
                                        .stroke(selectedSystemView.color, lineWidth: 0.5)
                                        .scaleEffect(2.0)
                                        .opacity(0.2)
                                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: selectedSystemView)
                                )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        
                        // Enhanced Dynamic Content Area
                        VStack(spacing: 12) {
                            switch selectedSystemView {
                            case .cpu:
                                CompactCPUSection()
                                    .environmentObject(cpuMonitor)
                            case .battery:
                                CompactBatterySection()
                                    .environmentObject(batteryMonitor)
                            case .disk:
                                CompactDiskSection()
                            case .integration:
                                EnhancedIntegrationSection()
                            }
                        }
                        .padding(.horizontal, 16)
                        
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
            // Right Section: Enhanced AI Chat Layout
            VStack(spacing: 0) {
                // Ultra-Modern Chat Header
                HStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundStyle(.cyan.gradient)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("SMITH AI")
                            .font(.callout)
                            .fontWeight(.bold)
                            .fontDesign(.monospaced)
                            .foregroundColor(.white)
                        
                        Text("Your intelligent assistant")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Modern Connection Status
                    HStack(spacing: 3) {
                        Circle()
                            .fill(.green)
                            .frame(width: 5, height: 5)
                            .overlay(
                                Circle()
                                    .stroke(.green, lineWidth: 0.3)
                                    .scaleEffect(1.5)
                                    .opacity(0.4)
                                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: smithAgent.isProcessing)
                            )
                        
                        Text("Online")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.green.opacity(0.08), in: Capsule())
                    .overlay(Capsule().stroke(.green.opacity(0.2), lineWidth: 0.3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .frame(height: 0.3)
                        .foregroundColor(.gray.opacity(0.2)),
                    alignment: .bottom
                )
                
                // Enhanced Chat Content
                ChatView()
                    .environmentObject(smithAgent)
            }
            .background(.black)
        }
        .navigationSplitViewStyle(.balanced)
        .background(.black)
        .sheet(isPresented: $showingSettings) {
            ModernSettingsView()
                .frame(width: 500, height: 400)
        }
        .onAppear {
            cpuMonitor.startMonitoring()
            batteryMonitor.startMonitoring()
        }
        .onDisappear {
            cpuMonitor.stopMonitoring()
            batteryMonitor.stopMonitoring()
        }
    }
}

// MARK: - Ultra-Compact UI Components
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
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(
                isActive ? color.opacity(0.15) : .clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isActive ? color.opacity(0.5) : .gray.opacity(0.1), lineWidth: isActive ? 1 : 0.5)
            )
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isActive)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Enhanced Content Sections with Modern Design
struct EnhancedCPUSection: View {
    @EnvironmentObject var cpuMonitor: CPUMonitor
    
    private var safeCPUUsage: Int {
        let usage = cpuMonitor.cpuUsage
        guard usage.isFinite && !usage.isNaN else { return 0 }
        return Int(max(0, min(100, usage)))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // CPU Usage Overview with Modern Gradient
            VStack(spacing: 10) {
                HStack {
                    Text("Performance")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(safeCPUUsage)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                // Modern CPU Usage Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.gray.opacity(0.15))
                            .frame(height: 6)
                            .clipShape(Capsule())
                        
                        Rectangle()
                            .fill(.green.gradient)
                            .frame(width: geometry.size.width * (Double(safeCPUUsage) / 100), height: 6)
                            .clipShape(Capsule())
                            .animation(.easeInOut(duration: 0.5), value: safeCPUUsage)
                    }
                }
                .frame(height: 6)
                
                // Quick Stats Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    QuickStatItem(title: "Cores", value: "8", color: .green)
                    QuickStatItem(title: "Threads", value: "16", color: .green)
                    QuickStatItem(title: "Temperature", value: "65°C", color: .orange)
                    QuickStatItem(title: "Frequency", value: "3.2GHz", color: .blue)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.green.opacity(0.2), lineWidth: 0.5)
            )
            
            // Detailed CPU View
            CPUView()
                .environmentObject(cpuMonitor)
        }
    }
}

struct EnhancedBatterySection: View {
    @EnvironmentObject var batteryMonitor: BatteryMonitor
    
    private var safeBatteryLevel: Int {
        let level = batteryMonitor.batteryLevel
        guard level.isFinite && !level.isNaN else { return 0 }
        return Int(max(0, min(100, level)))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Battery Health with Modern Visual
            VStack(spacing: 10) {
                HStack {
                    Text("Battery Health")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Excellent")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.15), in: Capsule())
                }
                
                // Modern Battery Visual
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 40, height: 20)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.green.gradient)
                            .frame(width: 36 * (Double(safeBatteryLevel) / 100), height: 16)
                            .animation(.easeInOut(duration: 0.5), value: safeBatteryLevel)
                        
                        // Battery tip
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .frame(width: 2, height: 8)
                            .offset(x: 22)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(safeBatteryLevel)%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("4h 32m remaining")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.yellow.opacity(0.2), lineWidth: 0.5)
            )
            
            // Detailed Battery View
            BatteryView()
                .environmentObject(batteryMonitor)
        }
    }
}

struct EnhancedDiskSection: View {
    var body: some View {
        VStack(spacing: 12) {
            // Storage Overview with Modern Progress Ring
            VStack(spacing: 10) {
                HStack {
                    Text("Storage Usage")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("456GB / 1TB")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Modern Storage Ring
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(.gray.opacity(0.2), lineWidth: 4)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: 0.456)
                            .stroke(.purple.gradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: 0.456)
                        
                        Text("46%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("456 GB used")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("544 GB available")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.purple.opacity(0.2), lineWidth: 0.5)
            )
            
            // Detailed Disk View
            DiskView()
        }
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
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.15), in: Capsule())
                }
                
                // Modern Integration Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                    ModernIntegrationCard(title: "URL Scheme", status: true, icon: "link")
                    ModernIntegrationCard(title: "Services", status: true, icon: "menubar.rectangle")
                    ModernIntegrationCard(title: "Quick Actions", status: false, icon: "hand.tap")
                    ModernIntegrationCard(title: "Spotlight", status: true, icon: "magnifyingglass")
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.indigo.opacity(0.2), lineWidth: 0.5)
            )
            
            // Detailed Integration View
            SystemIntegrationView()
        }
    }
}

// MARK: - Modern Supporting Components
struct QuickStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
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
        .padding(.vertical, 6)
        .background((status ? Color.green : Color.red).opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Settings and Other Components
struct ModernSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var enableNotifications = true
    @State private var autoCleanup = false
    @State private var refreshInterval = 5.0
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Smith Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsSection(title: "Notifications") {
                        Toggle("Enable System Notifications", isOn: $enableNotifications)
                            .toggleStyle(.switch)
                    }
                    
                    SettingsSection(title: "Monitoring") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Refresh Interval: \(Int(refreshInterval)) seconds")
                                .foregroundColor(.gray)
                            
                            Slider(value: $refreshInterval, in: 1...30, step: 1)
                                .tint(.orange)
                        }
                    }
                    
                    SettingsSection(title: "Automation") {
                        Toggle("Auto System Cleanup", isOn: $autoCleanup)
                            .toggleStyle(.switch)
                    }
                    
                    SettingsSection(title: "AI Assistant") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Stream Responses", isOn: .constant(true))
                                .toggleStyle(.switch)
                            
                            Toggle("Save Conversation History", isOn: .constant(true))
                                .toggleStyle(.switch)
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .background(.black)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            content
                .foregroundColor(.gray)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - System Monitor Views Enum
enum SystemMonitorView: String, CaseIterable {
    case cpu = "CPU"
    case battery = "Battery"
    case disk = "Disk"
    case integration = "Integration"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .cpu: return "cpu.fill"
        case .battery: return "battery.100.circle.fill"
        case .disk: return "externaldrive.fill"
        case .integration: return "gearshape.2.fill"
        }
    }
    
    var description: String {
        switch self {
        case .cpu: return "Monitor processor performance and usage"
        case .battery: return "Track power consumption and health"
        case .disk: return "Analyze storage usage and files"
        case .integration: return "Configure system integration features"
        }
    }
    
    var color: Color {
        switch self {
        case .cpu: return .green
        case .battery: return .yellow
        case .disk: return .purple
        case .integration: return .indigo
        }
    }
}

// MARK: - Compact Content Sections with Reduced Margins
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
                        .foregroundColor(.white)
                    
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
                    CompactStatItem(title: "Temp", value: "65°C", color: .orange)
                    CompactStatItem(title: "Freq", value: "3.2GHz", color: .blue)
                }
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.green.opacity(0.2), lineWidth: 0.5)
            )
            
            // Compact CPU View with Reduced Padding
            VStack(spacing: 0) {
                CPUView()
                    .environmentObject(cpuMonitor)
            }
            .frame(maxHeight: 220)
            .background(.black.opacity(0.02), in: RoundedRectangle(cornerRadius: 8))
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
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Excellent")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.15), in: Capsule())
                }
                
                // Compact Battery Visual
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 30, height: 16)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.green.gradient)
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
                            .foregroundColor(.white)
                        
                        Text("4h 32m remaining")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.yellow.opacity(0.2), lineWidth: 0.5)
            )
            
            // Compact Battery View with Reduced Padding
            VStack(spacing: 0) {
                BatteryView()
                    .environmentObject(batteryMonitor)
            }
            .frame(maxHeight: 200)
            .background(.black.opacity(0.02), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct CompactDiskSection: View {
    var body: some View {
        VStack(spacing: 8) {
            // Compact Storage Overview
            VStack(spacing: 8) {
                HStack {
                    Text("Storage Usage")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("456GB / 1TB")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Compact Storage Ring
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(.gray.opacity(0.2), lineWidth: 3)
                            .frame(width: 36, height: 36)
                        
                        Circle()
                            .trim(from: 0, to: 0.456)
                            .stroke(.purple.gradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 36, height: 36)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: 0.456)
                        
                        Text("46%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("456 GB used")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("544 GB available")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.purple.opacity(0.2), lineWidth: 0.5)
            )
            
            // Compact Disk View with Reduced Padding
            VStack(spacing: 0) {
                DiskView()
            }
            .frame(maxHeight: 240)
            .background(.black.opacity(0.02), in: RoundedRectangle(cornerRadius: 8))
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
        .padding(.vertical, 3)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 3))
    }
}

#Preview {
    MainView()
        .environmentObject(SmithAgent())
}
