//
//  SettingsView.swift
//  Smith - Your AI Coding Craftsman
//
//  Created by Yousef Jawdat on 15/06/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SmithSettings.shared
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        NavigationSplitView {
            // Settings Sidebar
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.title, systemImage: tab.icon)
                        .foregroundColor(.primary)
                }
            }
            .navigationTitle("Settings")
            .frame(minWidth: 200)
        } detail: {
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .ai:
                    AISettingsView()
                case .xcode:
                    XcodeSettingsView()
                case .appearance:
                    AppearanceSettingsView()
                case .advanced:
                    AdvancedSettingsView()
                }
            }
            .frame(minWidth: 500, minHeight: 400)
            .navigationTitle(selectedTab.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .navigationTitle("Smith Settings")
    }
}

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case ai = "AI & Models"
    case xcode = "Xcode Integration"
    case appearance = "Appearance"
    case advanced = "Advanced"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gear"
        case .ai: return "brain"
        case .xcode: return "hammer"
        case .appearance: return "paintbrush"
        case .advanced: return "wrench.and.screwdriver"
        }
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @StateObject private var settings = SmithSettings.shared
    
    var body: some View {
        Form {
            Section("Application") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                Toggle("Show Menu Bar Icon", isOn: $settings.showMenuBarIcon)
                Toggle("Start Minimized", isOn: $settings.startMinimized)
                
                HStack {
                    Text("Default Window Size")
                    Spacer()
                    Picker("Window Size", selection: $settings.defaultWindowSize) {
                        Text("Small").tag(WindowSize.small)
                        Text("Medium").tag(WindowSize.medium)
                        Text("Large").tag(WindowSize.large)
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Section("Notifications") {
                Toggle("Show Notifications", isOn: $settings.showNotifications)
                Toggle("Sound Effects", isOn: $settings.soundEffects)
                Toggle("Notify on Code Suggestions", isOn: $settings.notifyOnSuggestions)
            }
            
            Section("Performance") {
                HStack {
                    Text("File Monitoring Interval")
                    Spacer()
                    Picker("Interval", selection: $settings.fileMonitoringInterval) {
                        Text("1 second").tag(1.0)
                        Text("2 seconds").tag(2.0)
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Text("Max File Size for Analysis")
                    Spacer()
                    Picker("Size", selection: $settings.maxFileSize) {
                        Text("1 MB").tag(1_000_000)
                        Text("2 MB").tag(2_000_000)
                        Text("5 MB").tag(5_000_000)
                        Text("10 MB").tag(10_000_000)
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - AI Settings
struct AISettingsView: View {
    @StateObject private var settings = SmithSettings.shared
    
    var body: some View {
        Form {
            Section("Foundation Models") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Apple Intelligence Status")
                            .font(.headline)
                        Text(settings.foundationModelsStatus)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Circle()
                        .fill(settings.isFoundationModelsAvailable ? .green : .orange)
                        .frame(width: 10, height: 10)
                }
                
                Toggle("Use Foundation Models", isOn: $settings.useFoundationModels)
                    .disabled(!settings.isFoundationModelsAvailable)
                
                Toggle("Streaming Responses", isOn: $settings.streamingResponses)
            }
            
            Section("Response Settings") {
                HStack {
                    Text("Response Style")
                    Spacer()
                    Picker("Style", selection: $settings.responseStyle) {
                        Text("Concise").tag(ResponseStyle.concise)
                        Text("Detailed").tag(ResponseStyle.detailed)
                        Text("Conversational").tag(ResponseStyle.conversational)
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Text("Code Explanation Level")
                    Spacer()
                    Picker("Level", selection: $settings.codeExplanationLevel) {
                        Text("Beginner").tag(ExplanationLevel.beginner)
                        Text("Intermediate").tag(ExplanationLevel.intermediate)
                        Text("Advanced").tag(ExplanationLevel.advanced)
                    }
                    .pickerStyle(.menu)
                }
                
                Toggle("Include Code Examples", isOn: $settings.includeCodeExamples)
                Toggle("Suggest Best Practices", isOn: $settings.suggestBestPractices)
            }
            
            Section("Auto-Features") {
                Toggle("Auto-Apply Safe Suggestions", isOn: $settings.autoApplySafeSuggestions)
                Toggle("Auto-Generate Documentation", isOn: $settings.autoGenerateDocumentation)
                Toggle("Auto-Detect Code Issues", isOn: $settings.autoDetectCodeIssues)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Xcode Settings
struct XcodeSettingsView: View {
    @StateObject private var settings = SmithSettings.shared
    @State private var xcodeVersion: String = "Not Detected"
    @State private var isXcodeRunning: Bool = false
    
    var body: some View {
        Form {
            Section("Xcode Detection") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Xcode Status")
                            .font(.headline)
                        Text(isXcodeRunning ? "Running" : "Not Running")
                            .foregroundColor(isXcodeRunning ? .green : .secondary)
                    }
                    Spacer()
                    Text("Version: \(xcodeVersion)")
                        .foregroundColor(.secondary)
                }
                
                Toggle("Monitor Xcode Files", isOn: $settings.monitorXcodeFiles)
                Toggle("Auto-Detect Project Changes", isOn: $settings.autoDetectProjectChanges)
            }
            
            Section("File Indexing") {
                Toggle("Enable File Indexing", isOn: $settings.enableFileIndexing)
                Toggle("Index on Project Open", isOn: $settings.indexOnProjectOpen)
                
                HStack {
                    Text("Supported File Types")
                    Spacer()
                    Text("\(settings.supportedFileTypes.joined(separator: ", "))")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Index Update Frequency")
                    Spacer()
                    Picker("Frequency", selection: $settings.indexUpdateFrequency) {
                        Text("Real-time").tag(IndexFrequency.realtime)
                        Text("Every 5 minutes").tag(IndexFrequency.fiveMinutes)
                        Text("Every 15 minutes").tag(IndexFrequency.fifteenMinutes)
                        Text("Manual").tag(IndexFrequency.manual)
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Section("Integration Features") {
                Toggle("Insert Code at Cursor", isOn: $settings.insertCodeAtCursor)
                Toggle("Open Files in Xcode", isOn: $settings.openFilesInXcode)
                Toggle("Build Project Shortcuts", isOn: $settings.buildProjectShortcuts)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @StateObject private var settings = SmithSettings.shared
    
    var body: some View {
        Form {
            Section("Theme") {
                HStack {
                    Text("Color Scheme")
                    Spacer()
                    Picker("Scheme", selection: $settings.colorScheme) {
                        Text("System").tag(AppColorScheme.system)
                        Text("Light").tag(AppColorScheme.light)
                        Text("Dark").tag(AppColorScheme.dark)
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Text("Accent Color")
                    Spacer()
                    Picker("Color", selection: $settings.accentColor) {
                        Text("Blue").tag(AccentColor.blue)
                        Text("Purple").tag(AccentColor.purple)
                        Text("Pink").tag(AccentColor.pink)
                        Text("Red").tag(AccentColor.red)
                        Text("Orange").tag(AccentColor.orange)
                        Text("Yellow").tag(AccentColor.yellow)
                        Text("Green").tag(AccentColor.green)
                        Text("Mint").tag(AccentColor.mint)
                        Text("Teal").tag(AccentColor.teal)
                        Text("Cyan").tag(AccentColor.cyan)
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Section("Typography") {
                HStack {
                    Text("Interface Font Size")
                    Spacer()
                    Picker("Size", selection: $settings.interfaceFontSize) {
                        Text("Small").tag(FontSize.small)
                        Text("Medium").tag(FontSize.medium)
                        Text("Large").tag(FontSize.large)
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Text("Code Font")
                    Spacer()
                    Picker("Font", selection: $settings.codeFont) {
                        Text("SF Mono").tag(CodeFont.sfMono)
                        Text("Menlo").tag(CodeFont.menlo)
                        Text("Monaco").tag(CodeFont.monaco)
                        Text("Fira Code").tag(CodeFont.firaCode)
                    }
                    .pickerStyle(.menu)
                }
                
                Toggle("Use Ligatures", isOn: $settings.useLigatures)
            }
            
            Section("Visual Effects") {
                Toggle("Use Vibrancy Effects", isOn: $settings.useVibrancy)
                Toggle("Animate Transitions", isOn: $settings.animateTransitions)
                Toggle("Show Syntax Highlighting", isOn: $settings.showSyntaxHighlighting)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Advanced Settings
struct AdvancedSettingsView: View {
    @StateObject private var settings = SmithSettings.shared
    @State private var showingResetAlert = false
    
    var body: some View {
        Form {
            Section("Debug") {
                Toggle("Enable Debug Logging", isOn: $settings.enableDebugLogging)
                Toggle("Show Performance Metrics", isOn: $settings.showPerformanceMetrics)
                Toggle("Log AppleScript Calls", isOn: $settings.logAppleScriptCalls)
            }
            
            Section("Data Management") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Cache Size")
                        Text("Approximate storage used by Smith")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("~2.5 MB")
                        .foregroundColor(.secondary)
                }
                
                Button("Clear Cache") {
                    settings.clearCache()
                }
                .buttonStyle(.bordered)
                
                Button("Export Settings") {
                    settings.exportSettings()
                }
                .buttonStyle(.bordered)
                
                Button("Import Settings") {
                    settings.importSettings()
                }
                .buttonStyle(.bordered)
            }
            
            Section("Reset") {
                Button("Reset All Settings") {
                    showingResetAlert = true
                }
                .foregroundColor(.red)
                .buttonStyle(.bordered)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .alert("Reset All Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settings.resetAllSettings()
            }
        } message: {
            Text("This will reset all Smith settings to their default values. This action cannot be undone.")
        }
    }
}

#Preview {
    SettingsView()
}
