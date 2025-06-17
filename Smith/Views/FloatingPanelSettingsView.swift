//
//  FloatingPanelSettingsView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 17/06/2025.
//

import SwiftUI

struct FloatingPanelSettingsView: View {
    @EnvironmentObject var floatingPanelManager: FloatingPanelManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GroupBox("Available Panels") {
                    VStack(spacing: 12) {
                        ForEach(floatingPanelManager.panels, id: \.id) { panel in
                            HStack {
                                Image(systemName: panel.icon)
                                    .frame(width: 20, height: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(panel.title)
                                        .fontWeight(.medium)
                                    
                                    Text(panel.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Show") {
                                    floatingPanelManager.showPanel(panel.id)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                }
                
                GroupBox("Panel Management") {
                    VStack(spacing: 12) {
                        Button("Close All Panels") {
                            floatingPanelManager.closeAllPanels()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Floating Panels")
    }
}

#Preview {
    FloatingPanelSettingsView()
        .environmentObject(FloatingPanelManager())
        .frame(width: 500, height: 400)
}
