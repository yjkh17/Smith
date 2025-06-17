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
    
    init() {
        checkAvailableIntegrations()
    }
    
    func integrateWithSystem() {
        setupURLScheme()
        registerServicesMenuItems()
        setupQuickActions()
        createSystemShortcuts()
        
        isIntegrated = true
        print("✅ Smith integrated with macOS system")
    }
    
    func removeSystemIntegration() {
        removeURLScheme()
        unregisterServicesMenuItems()
        removeQuickActions()
        removeSystemShortcuts()
        
        isIntegrated = false
        print("✅ Smith system integration removed")
    }
    
    // MARK: - URL Scheme Handler
    private func setupURLScheme() {
        // Register smith:// URL scheme
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        
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
        default:
            openSmith()
        }
    }
    
    private func removeURLScheme() {
        NSAppleEventManager.shared().removeEventHandler(
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    // MARK: - Services Menu Integration
    private func registerServicesMenuItems() {
        NSApp.servicesProvider = self
        NSApp.registerServicesMenuSendTypes([.fileURL, .string], returnTypes: [.string])
        NSUpdateDynamicServices()
        
        print("✅ Registered Services menu items")
    }
    
    private func unregisterServicesMenuItems() {
        NSApp.servicesProvider = nil
        NSUpdateDynamicServices()
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
        
        print("✅ Created Quick Actions")
    }
    
    private func createAutomatorQuickAction(name: String, workflow: String) {
        let quickActionsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services")
        
        let actionURL = quickActionsURL.appendingPathComponent("\(name).workflow")
        
        do {
            try FileManager.default.createDirectory(at: actionURL, withIntermediateDirectories: true)
            
            let contentsURL = actionURL.appendingPathComponent("Contents")
            try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
            
            // Create workflow files
            let workflowURL = contentsURL.appendingPathComponent("document.applescript")
            try workflow.write(to: workflowURL, atomically: true, encoding: .utf8)
            
            // Create Info.plist
            let infoPlist = createQuickActionInfoPlist(name: name)
            let infoPlistURL = contentsURL.appendingPathComponent("Info.plist")
            try infoPlist.write(to: infoPlistURL)
            
        } catch {
            print("❌ Failed to create Quick Action: \(error)")
        }
    }
    
    private func createFileAnalysisWorkflow() -> String {
        return """
        on run {input, parameters}
            repeat with anItem in input
                set filePath to POSIX path of anItem
                set smithURL to "smith://analyze?path=" & (quoted form of filePath)
                do shell script "open " & quoted form of smithURL
            end repeat
            return input
        end run
        """
    }
    
    private func createTextQueryWorkflow() -> String {
        return """
        on run {input, parameters}
            set selectedText to item 1 of input as string
            set encodedText to do shell script "python3 -c \"import urllib.parse; print(urllib.parse.quote('" & selectedText & "'))\""
            set smithURL to "smith://chat?message=" & encodedText
            do shell script "open " & quoted form of smithURL
            return input
        end run
        """
    }
    
    private func createQuickActionInfoPlist(name: String) -> Data {
        let plist = [
            "CFBundleIdentifier": "com.motherofbrand.Smith.\(name.replacingOccurrences(of: " ", with: ""))",
            "CFBundleName": name,
            "CFBundleVersion": "1.0",
            "NSServices": [
                [
                    "NSMenuItem": ["default": name],
                    "NSMessage": "runWorkflowAsService",
                    "NSSendTypes": name.contains("File") ? ["public.file-url"] : ["public.plain-text"],
                    "NSReturnTypes": ["public.plain-text"]
                ]
            ]
        ] as [String: Any]
        
        return try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    }
    
    private func removeQuickActions() {
        let servicesURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services")
        
        let actionsToRemove = [
            "Ask Smith About This File.workflow",
            "Ask Smith.workflow"
        ]
        
        for action in actionsToRemove {
            let actionURL = servicesURL.appendingPathComponent(action)
            try? FileManager.default.removeItem(at: actionURL)
        }
    }
    
    // MARK: - System Shortcuts
    private func createSystemShortcuts() {
        // Create app shortcuts that appear in Spotlight
        createSpotlightApp(name: "Smith CPU Check", command: "smith://cpu")
        createSpotlightApp(name: "Smith System Clean", command: "smith://clean")
        createSpotlightApp(name: "Ask Smith", command: "smith://chat")
        
        print("✅ Created system shortcuts")
    }
    
    private func createSpotlightApp(name: String, command: String) {
        let applicationsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/Smith Shortcuts")
        
        let appURL = applicationsURL.appendingPathComponent("\(name).app")
        
        do {
            try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
            
            let contentsURL = appURL.appendingPathComponent("Contents")
            try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
            
            let macOSURL = contentsURL.appendingPathComponent("MacOS")
            try FileManager.default.createDirectory(at: macOSURL, withIntermediateDirectories: true)
            
            // Create executable
            let executableName = name.replacingOccurrences(of: " ", with: "")
            let executableURL = macOSURL.appendingPathComponent(executableName)
            let script = """
            #!/bin/bash
            open "\(command)"
            """
            try script.write(to: executableURL, atomically: true, encoding: .utf8)
            
            // Make executable
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executableURL.path)
            
            // Create Info.plist
            let infoPlist = createAppInfoPlist(name: name, executable: executableName)
            let infoPlistURL = contentsURL.appendingPathComponent("Info.plist")
            try infoPlist.write(to: infoPlistURL)
            
        } catch {
            print("❌ Failed to create Spotlight app: \(error)")
        }
    }
    
    private func createAppInfoPlist(name: String, executable: String) -> Data {
        let plist = [
            "CFBundleIdentifier": "com.motherofbrand.Smith.\(executable)",
            "CFBundleName": name,
            "CFBundleDisplayName": name,
            "CFBundleVersion": "1.0",
            "CFBundleExecutable": executable,
            "CFBundlePackageType": "APPL",
            "LSUIElement": true, // Hide from Dock
            "LSBackgroundOnly": false
        ] as [String: Any]
        
        return try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    }
    
    private func removeSystemShortcuts() {
        let shortcutsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/Smith Shortcuts")
        
        try? FileManager.default.removeItem(at: shortcutsURL)
    }
    
    // MARK: - Integration Status
    private func checkAvailableIntegrations() {
        availableIntegrations = [
            .urlScheme,
            .servicesMenu,
            .quickActions,
            .spotlightShortcuts
        ]
    }
    
    // MARK: - Smith App Handlers
    private func openSmith() {
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func openSmithWithFileAnalysis(path: String) {
        // Implementation depends on your app structure
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
}

// MARK: - Services Provider
extension SystemIntegration {
    @objc func analyzeFileService(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let items = pasteboard.pasteboardItems else { return }
        
        for item in items {
            if let fileURL = item.string(forType: .fileURL) {
                openSmithWithFileAnalysis(path: fileURL)
                break
            }
        }
    }
    
    @objc func askSmithService(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let selectedText = pasteboard.string(forType: .string) else { return }
        openSmithWithMessage(selectedText)
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
