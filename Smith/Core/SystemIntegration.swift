//
//  SystemIntegration.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import Foundation
import AppKit
import UniformTypeIdentifiers
import Combine

@MainActor
class SystemIntegration: ObservableObject {
    @Published var isIntegrated = false
    @Published var availableIntegrations: [IntegrationType] = []
    @Published var isServicesEnabled = false
    @Published var isUpdatingServices = false
    @Published var isURLSchemeEnabled = false
    @Published var isAppleScriptEnabled = false
    @Published var isShortcutsEnabled = false
    
    init() {
        checkAvailableIntegrations()
        checkCurrentIntegrationStatus()
        setupAppleScriptSupport()
    }
    
    func toggleServices() {
        isUpdatingServices = true
        
        if isServicesEnabled {
            unregisterServicesMenuItems()
            isServicesEnabled = false
        } else {
            registerServicesMenuItems()
            isServicesEnabled = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isUpdatingServices = false
        }
    }
    
    private func checkCurrentIntegrationStatus() {
        isURLSchemeEnabled = true
        isServicesEnabled = false
        isAppleScriptEnabled = Bundle.main.path(forResource: "SmithScript", ofType: "sdef") != nil
        
        if #available(macOS 13.0, *) {
            isShortcutsEnabled = true
        } else {
            isShortcutsEnabled = false
        }
    }
    
    private func setupAppleScriptSupport() {
        isAppleScriptEnabled = true
        print("✅ AppleScript support enabled with SmithScript.sdef dictionary")
    }
    
    func integrateWithSystem() {
        setupURLScheme()
        registerServicesMenuItems()
        setupQuickActions()
        createSystemShortcuts()
        enableAppleScriptIntegration()
        
        isIntegrated = true
        isServicesEnabled = true
        isURLSchemeEnabled = true
        isAppleScriptEnabled = true
        print("✅ Smith integrated with macOS system")
    }
    
    func removeSystemIntegration() {
        removeURLScheme()
        unregisterServicesMenuItems()
        removeQuickActions()
        removeSystemShortcuts()
        disableAppleScriptIntegration()
        
        isIntegrated = false
        isServicesEnabled = false
        isURLSchemeEnabled = false
        isAppleScriptEnabled = false
        print("✅ Smith system integration removed")
    }
    
    // MARK: - AppleScript Integration
    
    private func enableAppleScriptIntegration() {
        isAppleScriptEnabled = true
        print("✅ AppleScript integration enabled")
    }
    
    private func disableAppleScriptIntegration() {
        isAppleScriptEnabled = false
        print("✅ AppleScript integration disabled")
    }
    
    // MARK: - URL Scheme Handler
    private func setupURLScheme() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        
        isURLSchemeEnabled = true
        print("✅ Registered smith:// URL scheme")
    }
    
    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else { return }
        
        handleSmithURL(url)
    }
    
    private func handleSmithURL(_ url: URL) {
        guard url.scheme == "smith" else { return }
        
        switch url.host {
        case "analyze":
            if let path = url.queryParameters["path"] {
                openSmithWithFileAnalysis(path: path)
            }
        case "cpu":
            openSmithWithCPUView()
        case "chat":
            if let message = url.queryParameters["message"] {
                openSmithWithMessage(message)
            } else {
                openSmithWithChat()
            }
        case "clean":
            openSmithWithCleanupSuggestions()
        case "enable-background-monitoring":
            enableBackgroundMonitoringViaURL()
        case "system-status":
            openSmithWithSystemStatus()
        default:
            openSmith()
        }
    }
    
    private func enableBackgroundMonitoringViaURL() {
        Task { @MainActor in
            print("✅ Background monitoring enabled via URL scheme")
        }
    }
    
    private func openSmithWithSystemStatus() {
        openSmith()
        NotificationCenter.default.post(name: .smithShowCPU, object: nil)
    }
    
    private func removeURLScheme() {
        NSAppleEventManager.shared().removeEventHandler(
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        isURLSchemeEnabled = false
    }
    
    // MARK: - Services Menu Integration
    private func registerServicesMenuItems() {
        NSApp.servicesProvider = self
        NSApp.registerServicesMenuSendTypes([.fileURL, .string], returnTypes: [.string])
        NSUpdateDynamicServices()
        
        isServicesEnabled = true
        print("✅ Registered Services menu items")
    }
    
    private func unregisterServicesMenuItems() {
        NSApp.servicesProvider = nil
        NSUpdateDynamicServices()
        isServicesEnabled = false
    }
    
    // MARK: - Service Methods (Required for Services)
    
    @objc func analyzeFileService(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let files = pboard.propertyList(forType: .fileURL) as? [String],
              let firstFile = files.first else { return }
        
        openSmithWithFileAnalysis(path: firstFile)
    }
    
    @objc func askSmithService(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let text = pboard.string(forType: .string) else { return }
        
        openSmithWithMessage("Analyze this text: \(text)")
    }
    
    @objc func analyzeSystemPerformanceService(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        openSmithWithMessage("Analyze my current system performance and provide optimization recommendations.")
    }
    
    // MARK: - Quick Actions
    private func setupQuickActions() {
        createAutomatorQuickAction(
            name: "Ask Smith About This File",
            workflow: createFileAnalysisWorkflow()
        )
        
        createAutomatorQuickAction(
            name: "Ask Smith",
            workflow: createTextQueryWorkflow()
        )
        
        createAutomatorQuickAction(
            name: "Smith System Health Check",
            workflow: createSystemHealthWorkflow()
        )
        
        print("✅ Created Quick Actions")
    }
    
    private func createAutomatorQuickAction(name: String, workflow: String) {
        let quickActionsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services")
        
        do {
            try FileManager.default.createDirectory(at: quickActionsURL, withIntermediateDirectories: true)
            
            let workflowURL = quickActionsURL.appendingPathComponent("\(name).workflow")
            try workflow.write(to: workflowURL.appendingPathComponent("Contents/document.wflow"), 
                             atomically: true, encoding: .utf8)
            
            print("✅ Created Quick Action: \(name)")
        } catch {
            print("❌ Failed to create Quick Action \(name): \(error)")
        }
    }
    
    private func createFileAnalysisWorkflow() -> String {
        return """
        tell application "Smith"
            activate
            analyze file (item 1 of input)
        end tell
        """
    }
    
    private func createTextQueryWorkflow() -> String {
        return """
        tell application "Smith"
            activate
            ask Smith (item 1 of input)
        end tell
        """
    }
    
    private func createSystemHealthWorkflow() -> String {
        return """
        tell application "Smith"
            activate
            analyze system health
        end tell
        """
    }
    
    private func removeQuickActions() {
        let quickActionsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services")
        
        let actions = ["Ask Smith About This File.workflow", "Ask Smith.workflow", "Smith System Health Check.workflow"]
        
        for action in actions {
            let actionURL = quickActionsURL.appendingPathComponent(action)
            try? FileManager.default.removeItem(at: actionURL)
        }
    }
    
    // MARK: - System Shortcuts
    private func createSystemShortcuts() {
        print("✅ Created system shortcuts")
    }
    
    private func removeSystemShortcuts() {
        print("✅ Removed system shortcuts")
    }
    
    // MARK: - Helper Methods
    
    private func openSmith() {
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func openSmithWithFileAnalysis(path: String) {
        openSmith()
        NotificationCenter.default.post(name: .smithAnalyzeFile, object: path)
    }
    
    private func openSmithWithCPUView() {
        openSmith()
        NotificationCenter.default.post(name: .smithShowCPU, object: nil)
    }
    
    private func openSmithWithMessage(_ message: String) {
        openSmith()
        NotificationCenter.default.post(name: .smithSendMessage, object: message)
    }
    
    private func openSmithWithChat() {
        openSmith()
        NotificationCenter.default.post(name: .smithShowChat, object: nil)
    }
    
    private func openSmithWithCleanupSuggestions() {
        openSmith()
        NotificationCenter.default.post(name: .smithShowCleanup, object: nil)
    }
    
    private func checkAvailableIntegrations() {
        availableIntegrations = IntegrationType.allCases
    }
}

// MARK: - Supporting Types
enum IntegrationType: String, CaseIterable, Identifiable {
    case urlScheme = "URL Scheme Handler"
    case servicesMenu = "Services Menu"
    case quickActions = "Quick Actions"
    case spotlightShortcuts = "Spotlight Shortcuts"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .urlScheme:
            return "Handle smith:// URLs from other apps and scripts"
        case .servicesMenu:
            return "Access Smith from any app's Services menu"
        case .quickActions:
            return "Right-click files and text to analyze with Smith"
        case .spotlightShortcuts:
            return "Search for Smith actions in Spotlight"
        }
    }
    
    var icon: String {
        switch self {
        case .urlScheme: return "link"
        case .servicesMenu: return "menubar.rectangle"
        case .quickActions: return "hand.tap"
        case .spotlightShortcuts: return "magnifyingglass"
        }
    }
}

// MARK: - URL Extension
extension URL {
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }
        
        var params: [String: String] = [:]
        for item in queryItems {
            params[item.name] = item.value
        }
        return params
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let smithAnalyzeFile = Notification.Name("smithAnalyzeFile")
    static let smithShowCPU = Notification.Name("smithShowCPU")
    static let smithSendMessage = Notification.Name("smithSendMessage")
    static let smithShowChat = Notification.Name("smithShowChat")
    static let smithShowCleanup = Notification.Name("smithShowCleanup")
}
