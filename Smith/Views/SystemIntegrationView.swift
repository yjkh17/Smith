//
//  SystemIntegrationView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import SwiftUI

struct SystemIntegrationView: View {
    @StateObject private var systemIntegration = SystemIntegration()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gearshape.2")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                Text("System Integration")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Master toggle
                Button(systemIntegration.isIntegrated ? "Remove Integration" : "Integrate with macOS") {
                    toggleSystemIntegration()
                }
                .buttonStyle(.borderedProminent)
                .tint(systemIntegration.isIntegrated ? .red : .cyan)
            }
            .padding()
            .background(.gray.opacity(0.1))
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Integration Status
                    IntegrationStatusCard(isIntegrated: systemIntegration.isIntegrated)
                    
                    // Available Integrations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Integrations")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ForEach(systemIntegration.availableIntegrations) { integration in
                            IntegrationCard(
                                integration: integration,
                                isEnabled: systemIntegration.isIntegrated
                            )
                        }
                    }
                    
                    // Usage Examples
                    UsageExamplesCard()
                    
                    // Troubleshooting
                    TroubleshootingCard()
                }
                .padding()
            }
        }
        .background(.black)
        .alert("System Integration", isPresented: $showingPermissionAlert) {
            Button("OK") { }
        } message: {
            Text("Smith needs permission to integrate with macOS. Some features may require administrator privileges.")
        }
    }
    
    private func toggleSystemIntegration() {
        if systemIntegration.isIntegrated {
            systemIntegration.removeSystemIntegration()
        } else {
            systemIntegration.integrateWithSystem()
            showingPermissionAlert = true
        }
    }
}

struct IntegrationStatusCard: View {
    let isIntegrated: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isIntegrated ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title)
                .foregroundColor(isIntegrated ? .green : .red)
            
            VStack(alignment: .leading) {
                Text(isIntegrated ? "System Integration Active" : "System Integration Inactive")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(isIntegrated ? 
                     "Smith is integrated with macOS and available system-wide" :
                     "Click 'Integrate with macOS' to enable system-wide access")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct IntegrationCard: View {
    let integration: IntegrationType
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: integration.icon)
                .font(.title2)
                .foregroundColor(isEnabled ? .cyan : .gray)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(integration.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(integration.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isEnabled ? .green : .gray)
        }
        .padding()
        .background(.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct UsageExamplesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Examples")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ExampleItem(
                    title: "Finder Integration",
                    description: "Right-click any file → Services → 'Ask Smith About This File'"
                )
                
                ExampleItem(
                    title: "Spotlight Access",
                    description: "Press Cmd+Space, type 'Smith CPU Check' or 'Ask Smith'"
                )
                
                ExampleItem(
                    title: "URL Commands",
                    description: "Use smith://cpu or smith://chat URLs in scripts"
                )
                
                ExampleItem(
                    title: "Text Selection",
                    description: "Select text in any app → Services → 'Ask Smith'"
                )
            }
        }
        .padding()
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ExampleItem: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.cyan)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct TroubleshootingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Troubleshooting")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                TroubleshootingItem(
                    issue: "Services not appearing",
                    solution: "Restart your Mac or run 'sudo /System/Library/CoreServices/pbs -flush' in Terminal"
                )
                
                TroubleshootingItem(
                    issue: "Spotlight shortcuts missing",
                    solution: "Rebuild Spotlight index: System Preferences → Spotlight → Privacy"
                )
                
                TroubleshootingItem(
                    issue: "Permission denied errors",
                    solution: "Grant Smith full disk access in System Preferences → Security & Privacy"
                )
            }
        }
        .padding()
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TroubleshootingItem: View {
    let issue: String
    let solution: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Issue: \(issue)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
            
            Text("Solution: \(solution)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    SystemIntegrationView()
}