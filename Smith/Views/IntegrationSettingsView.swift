//
//  IntegrationSettingsView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 17/06/2025.
//

import SwiftUI

struct IntegrationSettingsView: View {
    @AppStorage("smith.urlSchemeEnabled") private var urlSchemeEnabled = true
    @AppStorage("smith.servicesEnabled") private var servicesEnabled = true
    @AppStorage("smith.quickActionsEnabled") private var quickActionsEnabled = true
    @AppStorage("smith.spotlightEnabled") private var spotlightEnabled = true
    @AppStorage("smith.shortcutsEnabled") private var shortcutsEnabled = true
    
    var body: some View {
        Form {
            Section("System Integration") {
                Toggle("URL Scheme (smith://)", isOn: $urlSchemeEnabled)
                    .help("Allow other apps to communicate with Smith via smith:// URLs")
                
                Toggle("macOS Services", isOn: $servicesEnabled)
                    .help("Add Smith actions to right-click context menus")
                
                Toggle("Quick Actions", isOn: $quickActionsEnabled)
                    .help("Enable Smith quick actions in Finder and other apps")
                
                Toggle("Spotlight Integration", isOn: $spotlightEnabled)
                    .help("Allow Smith commands through Spotlight search")
            }
            
            Section("Automation") {
                Toggle("Shortcuts Integration", isOn: $shortcutsEnabled)
                    .help("Allow Smith to work with macOS Shortcuts app")
                
                Button("Reset All Integrations") {
                    resetAllIntegrations()
                }
                .foregroundColor(.red)
            }
            
            Section("Integration Status") {
                IntegrationStatusRow(title: "URL Scheme", status: urlSchemeEnabled, icon: "link")
                IntegrationStatusRow(title: "Services", status: servicesEnabled, icon: "menubar.rectangle")
                IntegrationStatusRow(title: "Quick Actions", status: quickActionsEnabled, icon: "hand.tap")
                IntegrationStatusRow(title: "Spotlight", status: spotlightEnabled, icon: "magnifyingglass")
                IntegrationStatusRow(title: "Shortcuts", status: shortcutsEnabled, icon: "gear.badge")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Integration")
    }
    
    private func resetAllIntegrations() {
        urlSchemeEnabled = true
        servicesEnabled = true
        quickActionsEnabled = true
        spotlightEnabled = true
        shortcutsEnabled = true
    }
}

struct IntegrationStatusRow: View {
    let title: String
    let status: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(status ? .green : .red)
                .frame(width: 20)
            
            Text(title)
            
            Spacer()
            
            Text(status ? "Active" : "Inactive")
                .foregroundColor(status ? .green : .red)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background((status ? Color.green : Color.red).opacity(0.15), in: Capsule())
        }
    }
}

#Preview {
    IntegrationSettingsView()
        .frame(width: 500, height: 400)
}