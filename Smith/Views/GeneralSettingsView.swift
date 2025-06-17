//
//  GeneralSettingsView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 17/06/2025.
//

import SwiftUI
import Foundation

struct GeneralSettingsView: View {
    @AppStorage("smith.launchAtLogin") private var launchAtLogin = false
    @AppStorage("smith.showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("smith.enableNotifications") private var enableNotifications = true
    @AppStorage("smith.darkMode") private var darkMode = false
    @AppStorage("smith.updateFrequency") private var updateFrequency = "auto"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GroupBox("Application") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Launch at Login", isOn: $launchAtLogin)
                            .help("Automatically start Smith when you log in")
                        
                        Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
                            .help("Display Smith icon in the menu bar")
                        
                        Toggle("Enable Notifications", isOn: $enableNotifications)
                            .help("Allow Smith to send system notifications")
                    }
                    .padding()
                }
                
                GroupBox("Appearance") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Dark Mode", isOn: $darkMode)
                            .help("Use dark appearance for Smith interface")
                        
                        HStack {
                            Text("Update Frequency")
                            Spacer()
                            Picker("Update Frequency", selection: $updateFrequency) {
                                Text("Automatic").tag("auto")
                                Text("Manual").tag("manual")
                                Text("Weekly").tag("weekly")
                            }
                            .pickerStyle(.menu)
                            .help("How often to check for Smith updates")
                        }
                    }
                    .padding()
                }
                
                GroupBox("About") {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Build")
                            Spacer()
                            Text("2025.06.17")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("macOS Version")
                            Spacer()
                            Text("macOS 26.0")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("General")
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 500, height: 400)
}
