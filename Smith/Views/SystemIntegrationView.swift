//
//  SystemIntegrationView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import SwiftUI
import Combine

struct SystemIntegrationView: View {
    @StateObject private var systemIntegration = SystemIntegration()
    @State private var showingURLSchemeTest = false
    @State private var testURLInput = "smith://analyze-file?path=/Users/example/file.txt"
    @State private var testResult = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("System Integration")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Services, URL schemes, and macOS integration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Services Status
            GroupBox("Services Integration") {
                VStack(alignment: .leading, spacing: 12) {
                    ServiceStatusRow(title: "File Analysis Service", 
                                   isEnabled: systemIntegration.isServicesEnabled,
                                   description: "Right-click → Services → Analyze with Smith")
                    
                    ServiceStatusRow(title: "Text Analysis Service", 
                                   isEnabled: systemIntegration.isServicesEnabled,
                                   description: "Analyze selected text in any app")
                    
                    ServiceStatusRow(title: "System Status Service", 
                                   isEnabled: systemIntegration.isServicesEnabled,
                                   description: "Quick system health check")
                    
                    HStack {
                        Button(systemIntegration.isServicesEnabled ? "Disable Services" : "Enable Services") {
                            systemIntegration.toggleServices()
                        }
                        .buttonStyle(.bordered)
                        
                        if systemIntegration.isUpdatingServices {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .padding()
            }
            
            // URL Scheme Status
            GroupBox("URL Scheme Integration") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: systemIntegration.isURLSchemeEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(systemIntegration.isURLSchemeEnabled ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text("smith:// URL Scheme")
                                .fontWeight(.medium)
                            
                            Text("Allows external apps to interact with Smith")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(systemIntegration.isURLSchemeEnabled ? "Active" : "Inactive")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(systemIntegration.isURLSchemeEnabled ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    // Supported URL patterns
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Supported URLs:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("smith://analyze-file?path=<filepath>")
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundColor(.secondary)
                        
                        Text("smith://chat?message=<message>")
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundColor(.secondary)
                        
                        Text("smith://system-status")
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Test URL Scheme") {
                        showingURLSchemeTest = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            
            // AppleScript Integration
            GroupBox("AppleScript Integration") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: systemIntegration.isAppleScriptEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(systemIntegration.isAppleScriptEnabled ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text("AppleScript Dictionary")
                                .fontWeight(.medium)
                            
                            Text("Complete automation support for power users")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(systemIntegration.isAppleScriptEnabled ? "Active" : "Inactive")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(systemIntegration.isAppleScriptEnabled ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if systemIntegration.isAppleScriptEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available Commands:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text("tell application \"Smith\" to get CPU usage")
                                .font(.caption)
                                .fontDesign(.monospaced)
                                .foregroundColor(.secondary)
                            
                            Text("tell application \"Smith\" to analyze system health")
                                .font(.caption)
                                .fontDesign(.monospaced)
                                .foregroundColor(.secondary)
                            
                            Text("tell application \"Smith\" to ask Smith \"optimize my system\"")
                                .font(.caption)
                                .fontDesign(.monospaced)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            
            // Shortcuts Integration
            GroupBox("Shortcuts Integration") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: systemIntegration.isShortcutsEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(systemIntegration.isShortcutsEnabled ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text("Shortcuts App Support")
                                .fontWeight(.medium)
                            
                            Text("Modern automation with the Shortcuts app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if systemIntegration.isShortcutsEnabled {
                            Text("Available")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        } else {
                            Text("macOS 13+ Required")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    if systemIntegration.isShortcutsEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available Actions:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text("• Get System Statistics")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Analyze System Health")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Ask Smith AI")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Enable Background Monitoring")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingURLSchemeTest) {
            URLSchemeTestView(testInput: $testURLInput, testResult: $testResult)
        }
    }
}

struct ServiceStatusRow: View {
    let title: String
    let isEnabled: Bool
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isEnabled ? .green : .gray)
            
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct URLSchemeTestView: View {
    @Binding var testInput: String
    @Binding var testResult: String
    @Environment(\.dismiss) private var dismiss
    @State private var isTesting = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Test URL Scheme")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter a smith:// URL to test:")
                    .font(.headline)
                
                TextField("smith://...", text: $testInput)
                    .textFieldStyle(.roundedBorder)
                    .fontDesign(.monospaced)
            }
            
            Button("Test URL") {
                testURL()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isTesting)
            
            if isTesting {
                ProgressView("Testing...")
            }
            
            if !testResult.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Result:")
                        .font(.headline)
                    
                    Text(testResult)
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
    
    private func testURL() {
        isTesting = true
        testResult = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard let url = URL(string: testInput) else {
                testResult = "Invalid URL format"
                isTesting = false
                return
            }
            
            if NSWorkspace.shared.open(url) {
                testResult = "URL opened successfully - check Smith for response"
            } else {
                testResult = "Failed to open URL - scheme may not be registered"
            }
            
            isTesting = false
        }
    }
}

#Preview {
    SystemIntegrationView()
        .frame(width: 600, height: 800)
}
