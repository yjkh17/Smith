//
//  SmithApp.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 14/06/2025.
//

import SwiftUI
import UserNotifications
import AppKit

@main
struct SmithApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var smithAgent = SmithAgent()
    @StateObject private var launchAgentManager = LaunchAgentManager()
    @StateObject private var backgroundService = BackgroundMonitorService()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(smithAgent)
                .environmentObject(launchAgentManager)
                .environmentObject(backgroundService)
                .preferredColorScheme(.dark)
                .background(.ultraThinMaterial)
                .onOpenURL { url in
                    handleSmithURL(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: .smithAnalyzeFile)) { notification in
                    if let filePath = notification.object as? String {
                        handleFileAnalysis(filePath)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .smithShowCPU)) { _ in
                    // Handle CPU view showing
                }
                .onReceive(NotificationCenter.default.publisher(for: .smithSendMessage)) { notification in
                    if let message = notification.object as? String {
                        Task {
                            smithAgent.sendMessage(message)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .smithShowChat)) { _ in
                    // Focus on chat - implementation depends on your UI structure
                }
                .onReceive(NotificationCenter.default.publisher(for: .smithShowCleanup)) { _ in
                    // Show cleanup suggestions
                    Task {
                        smithAgent.sendMessage("Please provide system cleanup suggestions for my Mac.")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .smithLaunchAgentStatusChanged)) { _ in
                    // Handle launch agent status changes
                }
                .onReceive(NotificationCenter.default.publisher(for: .smithBackgroundMonitoringToggled)) { notification in
                    if let enable = notification.object as? Bool {
                        Task {
                            if enable {
                                await launchAgentManager.toggleBackgroundMonitoring()
                            } else {
                                await launchAgentManager.toggleBackgroundMonitoring()
                            }
                        }
                    } else {
                        Task {
                            await launchAgentManager.toggleBackgroundMonitoring()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .smithBackgroundIntensityChanged)) { notification in
                    if let intensityString = notification.object as? String,
                       let intensity = BackgroundIntensity(rawValue: intensityString) {
                        Task {
                            await launchAgentManager.setBackgroundIntensity(intensity)
                        }
                    }
                }
                .onAppear {
                    setupApplication()
                    // Pass the smith agent to app delegate for menu bar integration
                    appDelegate.smithAgent = smithAgent
                    appDelegate.launchAgentManager = launchAgentManager
                    appDelegate.backgroundService = backgroundService
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            SmithCommands()
        }
        Settings {
            SettingsView()
                .environmentObject(launchAgentManager)
                .environmentObject(backgroundService)
        }
    }
    
    private func setupApplication() {
        // Request sensitive permissions
        PermissionsManager.shared.requestPermissions()

        // Request notification permissions for background alerts
        Task {
            await requestNotificationPermissions()
        }
        
        // Check if app was launched in background mode
        let arguments = CommandLine.arguments
        if arguments.contains("--background-monitor") {
            // App was launched by LaunchAgent - minimize UI and run background monitoring
            NSApp.setActivationPolicy(.accessory)
        }
        
        // Register for system services
        NSApp.servicesProvider = appDelegate
    }
    
    private func requestNotificationPermissions() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            if granted {
                print("Notification permissions granted")
            } else {
                print("Notification permissions denied")
            }
        } catch {
            print("Error requesting notification permissions: \(error)")
        }
    }
    
    private func handleFileAnalysis(_ filePath: String) {
        // Create FileItem from path and set as focused
        if let url = URL(string: filePath),
           let fileItem = FileItem(url: url) {
            smithAgent.setFocusedFile(fileItem)
            
            Task {
                smithAgent.sendMessage("Please analyze this file and tell me what it does.")
            }
        }
    }
    
    private func handleSmithURL(_ url: URL) {
        guard url.scheme == "smith" else { return }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        switch url.host {
        case "analyze-file":
            if let path = components?.queryItems?.first(where: { $0.name == "path" })?.value {
                handleFileAnalysis(path)
            }
        case "system-health":
            Task {
                smithAgent.analyzeSystemHealth()
            }
        case "optimize":
            Task {
                smithAgent.optimizePerformance()
            }
        case "chat":
            if let message = components?.queryItems?.first(where: { $0.name == "message" })?.value {
                Task {
                    smithAgent.sendMessage(message)
                }
            }
            // Bring app to front
            NSApp.activate(ignoringOtherApps: true)
        case "quick-stats":
            // Show quick stats in menu bar or floating window
            appDelegate.showQuickStats()
        default:
            break
        }
    }
}

// MARK: - App Delegate with Menu Bar and Services
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var smithAgent: SmithAgent?
    var launchAgentManager: LaunchAgentManager?
    var backgroundService: BackgroundMonitorService?
    var quickStatsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupServices()
        setupSpotlightIntegration()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Show main window when dock icon is clicked
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
    
    // MARK: - Menu Bar Setup
    private func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Smith")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        let menu = NSMenu()
        
        // System Status Section
        menu.addItem(NSMenuItem.sectionHeader(title: "System Status"))
        menu.addItem(withTitle: "Quick Health Check", action: #selector(quickHealthCheck), keyEquivalent: "h")
        menu.addItem(withTitle: "CPU Monitor", action: #selector(showCPUMonitor), keyEquivalent: "u")
        menu.addItem(withTitle: "Battery Status", action: #selector(showBatteryStatus), keyEquivalent: "b")
        menu.addItem(withTitle: "Storage Analysis", action: #selector(showStorageAnalysis), keyEquivalent: "s")
        
        menu.addItem(NSMenuItem.separator())
        
        // AI Assistant Section
        menu.addItem(NSMenuItem.sectionHeader(title: "AI Assistant"))
        menu.addItem(withTitle: "Ask Smith...", action: #selector(openMainWindow), keyEquivalent: "a")
        menu.addItem(withTitle: "System Optimization", action: #selector(optimizeSystem), keyEquivalent: "o")
        menu.addItem(withTitle: "File Analysis", action: #selector(analyzeFile), keyEquivalent: "f")
        
        menu.addItem(NSMenuItem.separator())
        
        // Background Monitoring Section
        menu.addItem(NSMenuItem.sectionHeader(title: "Background Monitoring"))
        let backgroundToggle = NSMenuItem(title: "Enable Background Monitoring", action: #selector(toggleBackgroundMonitoring), keyEquivalent: "")
        backgroundToggle.target = self
        menu.addItem(backgroundToggle)
        
        menu.addItem(withTitle: "Monitoring Settings", action: #selector(showBackgroundSettings), keyEquivalent: "")
        
        menu.addItem(NSMenuItem.separator())
        
        // App Control Section
        menu.addItem(withTitle: "Show Main Window", action: #selector(openMainWindow), keyEquivalent: "")
        menu.addItem(withTitle: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        menu.addItem(withTitle: "About Smith", action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Smith", action: #selector(quitApp), keyEquivalent: "q")
        
        statusBarItem?.menu = menu
        
        // Update menu items based on current state
        updateMenuItems()
    }
    
    private func updateMenuItems() {
        guard let menu = statusBarItem?.menu else { return }
        
        // Update background monitoring toggle
        if let backgroundToggle = menu.item(withTitle: "Enable Background Monitoring") {
            // Check if launch agent is enabled (simplified check)
            let isEnabled = launchAgentManager?.isEnabled ?? false
            backgroundToggle.title = isEnabled ? "Disable Background Monitoring" : "Enable Background Monitoring"
        }
    }
    
    // MARK: - Menu Actions
    @objc private func statusBarButtonClicked() {
        // Option+click shows quick stats, regular click shows menu
        if NSApp.currentEvent?.modifierFlags.contains(.option) == true {
            showQuickStats()
        }
    }
    
    @objc private func quickHealthCheck() {
        Task { @MainActor in
            smithAgent?.analyzeSystemHealth()
            openMainWindow()
        }
    }
    
    @objc private func showCPUMonitor() {
        NotificationCenter.default.post(name: .smithShowCPU, object: nil)
        openMainWindow()
    }
    
    @objc private func showBatteryStatus() {
        Task { @MainActor in
            smithAgent?.sendMessage("Show me detailed battery status and health information")
            openMainWindow()
        }
    }
    
    @objc private func showStorageAnalysis() {
        Task { @MainActor in
            smithAgent?.sendMessage("Analyze my storage usage and provide cleanup recommendations")
            openMainWindow()
        }
    }
    
    @objc private func optimizeSystem() {
        Task { @MainActor in
            smithAgent?.optimizePerformance()
            openMainWindow()
        }
    }
    
    @objc private func analyzeFile() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            if let fileItem = FileItem(url: url) {
                smithAgent?.setFocusedFile(fileItem)
                Task { @MainActor in
                    smithAgent?.sendMessage("Please analyze this file/folder and provide insights.")
                    openMainWindow()
                }
            }
        }
    }
    
    @objc private func toggleBackgroundMonitoring() {
        Task {
            await launchAgentManager?.toggleBackgroundMonitoring()
            await MainActor.run {
                updateMenuItems()
            }
        }
    }
    
    @objc private func showBackgroundSettings() {
        showPreferences()
    }
    
    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            if window.title.isEmpty || window.title.contains("Smith") {
                window.makeKeyAndOrderFront(self)
                break
            }
        }
    }
    
    @objc private func showPreferences() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(self)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(self)
    }
    
    // MARK: - Quick Stats Window
    func showQuickStats() {
        if quickStatsWindow == nil {
            let contentView = AppQuickStatsView()
                .environmentObject(smithAgent ?? SmithAgent())
            
            quickStatsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            
            quickStatsWindow?.title = "Smith Quick Stats"
            quickStatsWindow?.contentView = NSHostingView(rootView: contentView)
            quickStatsWindow?.level = .floating
            quickStatsWindow?.isReleasedWhenClosed = false
        }
        
        if let window = quickStatsWindow {
            // Position near menu bar
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let windowFrame = window.frame
                let x = screenFrame.maxX - windowFrame.width - 20
                let y = screenFrame.maxY - windowFrame.height - 20
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            window.makeKeyAndOrderFront(self)
        }
    }
    
    // MARK: - Services Setup
    private func setupServices() {
        // Services are automatically registered via Info.plist
        // The methods will be called by the system
    }
    
    // MARK: - Services Implementation
    @objc func analyzeFileService(_ pasteboard: NSPasteboard, userData: String, error: UnsafeMutablePointer<NSString>) {
        guard let types = pasteboard.types, types.contains(.fileURL) else { return }
        
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let url = urls.first {
            
            if let fileItem = FileItem(url: url) {
                smithAgent?.setFocusedFile(fileItem)
                Task { @MainActor in
                    smithAgent?.sendMessage("Please analyze this file and provide detailed insights about its purpose, contents, and recommendations.")
                    openMainWindow()
                }
            }
        }
    }
    
    @objc func askSmithService(_ pasteboard: NSPasteboard, userData: String, error: UnsafeMutablePointer<NSString>) {
        guard let types = pasteboard.types, types.contains(.string) else { return }
        
        if let text = pasteboard.string(forType: .string) {
            Task { @MainActor in
                smithAgent?.sendMessage("Context from user selection: \(text)\n\nPlease provide insights or answer questions about this content.")
                openMainWindow()
            }
        }
    }
    
    @objc func analyzeSystemPerformanceService(_ pasteboard: NSPasteboard, userData: String, error: UnsafeMutablePointer<NSString>) {
        Task { @MainActor in
            smithAgent?.analyzeSystemHealth()
            openMainWindow()
        }
    }
    
    // MARK: - Spotlight Integration
    private func setupSpotlightIntegration() {
        // Register custom metadata for Spotlight
        // This would typically involve creating and indexing custom content
        print("Spotlight integration ready - Smith commands available")
    }
}

// MARK: - Quick Stats View
struct QuickStatsView: View {
    @EnvironmentObject var smithAgent: SmithAgent
    @StateObject private var cpuMonitor = CPUMonitor()
    @StateObject private var batteryMonitor = BatteryMonitor()
    @StateObject private var storageMonitor = StorageMonitor()

    private var storageUsagePercentage: Int {
        guard storageMonitor.totalSpace > 0 else { return 0 }
        let pct = Double(storageMonitor.usedSpace) / Double(storageMonitor.totalSpace) * 100
        return Int(max(0, min(100, pct)))
    }
    
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
                QuickStatRow(
                    icon: "cpu.fill",
                    title: "CPU",
                    value: "\(Int(cpuMonitor.cpuUsage))%",
                    color: cpuMonitor.cpuUsage > 80 ? .red : cpuMonitor.cpuUsage > 60 ? .orange : .green
                )
                
                QuickStatRow(
                    icon: "battery.100",
                    title: "Battery",
                    value: "\(Int(batteryMonitor.batteryLevel))%",
                    color: batteryMonitor.batteryLevel < 20 ? .red : batteryMonitor.batteryLevel < 50 ? .orange : .green
                )

                QuickStatRow(
                    icon: "internaldrive",
                    title: "Storage",
                    value: "\(Int(storageUsagePercentage))%",
                    color: storageUsagePercentage > 90 ? .red : storageUsagePercentage > 75 ? .orange : .purple
                )
                
                QuickStatRow(
                    icon: "brain",
                    title: "AI Status",
                    value: smithAgent.isFoundationModelsAvailable ? "Ready" : "Offline",
                    color: smithAgent.isFoundationModelsAvailable ? .green : .red
                )
                
                QuickStatRow(
                    icon: "gearshape.2",
                    title: "Performance",
                    value: "\(Int(smithAgent.getPerformanceScore()))/100",
                    color: smithAgent.getPerformanceScore() > 80 ? .green : smithAgent.getPerformanceScore() > 60 ? .orange : .red
                )
            }
            
            HStack {
                Button("Full Analysis") {
                    Task {
                        smithAgent.analyzeSystemHealth()
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
        .background(.ultraThinMaterial)
        .onAppear {
            cpuMonitor.startMonitoring()
            batteryMonitor.startMonitoring()
            storageMonitor.startMonitoring()
        }
        .onDisappear {
            cpuMonitor.stopMonitoring()
            batteryMonitor.stopMonitoring()
            storageMonitor.stopMonitoring()
        }
    }
}

struct QuickStatRow: View {
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

struct AppQuickStatsView: View {
    @EnvironmentObject var smithAgent: SmithAgent
    @StateObject private var cpuMonitor = CPUMonitor()
    @StateObject private var batteryMonitor = BatteryMonitor()
    @StateObject private var storageMonitor = StorageMonitor()

    private var storageUsagePercentage: Int {
        guard storageMonitor.totalSpace > 0 else { return 0 }
        let pct = Double(storageMonitor.usedSpace) / Double(storageMonitor.totalSpace) * 100
        return Int(max(0, min(100, pct)))
    }
    
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
                AppQuickStatRow(
                    icon: "cpu.fill",
                    title: "CPU",
                    value: "\(Int(cpuMonitor.cpuUsage))%",
                    color: cpuMonitor.cpuUsage > 80 ? .red : cpuMonitor.cpuUsage > 60 ? .orange : .green
                )
                
                AppQuickStatRow(
                    icon: "battery.100",
                    title: "Battery",
                    value: "\(Int(batteryMonitor.batteryLevel))%",
                    color: batteryMonitor.batteryLevel < 20 ? .red : batteryMonitor.batteryLevel < 50 ? .orange : .green
                )

                AppQuickStatRow(
                    icon: "internaldrive",
                    title: "Storage",
                    value: "\(Int(storageUsagePercentage))%",
                    color: storageUsagePercentage > 90 ? .red : storageUsagePercentage > 75 ? .orange : .purple
                )
                
                AppQuickStatRow(
                    icon: "brain",
                    title: "AI Status",
                    value: smithAgent.isFoundationModelsAvailable ? "Ready" : "Offline",
                    color: smithAgent.isFoundationModelsAvailable ? .green : .red
                )
                
                AppQuickStatRow(
                    icon: "gearshape.2",
                    title: "Performance",
                    value: "\(Int(smithAgent.getPerformanceScore()))/100",
                    color: smithAgent.getPerformanceScore() > 80 ? .green : smithAgent.getPerformanceScore() > 60 ? .orange : .red
                )
            }
            
            HStack {
                Button("Full Analysis") {
                    Task {
                        smithAgent.analyzeSystemHealth()
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
        .background(.ultraThinMaterial)
        .onAppear {
            cpuMonitor.startMonitoring()
            batteryMonitor.startMonitoring()
            storageMonitor.startMonitoring()
        }
        .onDisappear {
            cpuMonitor.stopMonitoring()
            batteryMonitor.stopMonitoring()
            storageMonitor.stopMonitoring()
        }
    }
}

struct AppQuickStatRow: View {
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

struct SmithCommands: Commands {
    var body: some Commands {
        CommandMenu("Smith") {
            Button("New Conversation") {
                NotificationCenter.default.post(name: .smithShowChat, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command])
            
            Button("Analyze System Health") {
                NotificationCenter.default.post(name: .smithSendMessage, object: "Analyze my system health and performance")
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            
            Button("Quick CPU Check") {
                NotificationCenter.default.post(name: .smithShowCPU, object: nil)
            }
            .keyboardShortcut("u", modifiers: [.command, .shift])
            
            Button("System Cleanup") {
                NotificationCenter.default.post(name: .smithShowCleanup, object: nil)
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Background Monitoring Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])
            
            Button("Toggle Main Window") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut("s", modifiers: [.command, .option])
        }
        
        CommandGroup(replacing: .help) {
            Button("Smith Help") {
                NotificationCenter.default.post(name: .smithSendMessage, object: "What permissions does Smith require and how do I use it effectively?")
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        TabView {
            BackgroundSettingsView()
                .tabItem {
                    Label("Background", systemImage: "gear.circle")
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
        .frame(width: 600, height: 500)
    }
}

// MARK: - URL Extensions
extension URL {
    var queryItems: [URLQueryItem]? {
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems
    }
}

// MARK: - NSMenuItem Extensions
extension NSMenuItem {
    static func sectionHeader(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
    
    convenience init(title: String, action: Selector?, keyEquivalent: String) {
        self.init()
        self.title = title
        self.action = action
        self.keyEquivalent = keyEquivalent
        self.target = nil // Will use first responder
    }
}
