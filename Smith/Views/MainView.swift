//
//  MainView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import SwiftUI

struct MainView: View {
    @StateObject private var smithAgent = SmithAgent()
    @State private var selectedTab: MainTab = .chat
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with navigation
            VStack(spacing: 0) {
                // App Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "brain")
                            .foregroundColor(.cyan)
                            .font(.title)
                        
                        Text("SMITH")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .fontDesign(.monospaced)
                    }
                    
                    Text("AI System Assistant")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(.gray.opacity(0.1))
                
                Divider()
                
                // Navigation Tabs
                List(MainTab.allCases, id: \.self, selection: $selectedTab) { tab in
                    NavigationTabRow(tab: tab, isSelected: selectedTab == tab)
                        .tag(tab)
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                
                Spacer()
                
                // Status Footer
                VStack(spacing: 4) {
                    HStack {
                        Circle()
                            .fill(smithAgent.isAvailable ? .green : .red)
                            .frame(width: 8, height: 8)
                        
                        Text(smithAgent.isAvailable ? "AI Ready" : "AI Unavailable")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    
                    if smithAgent.isProcessing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Processing...")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Smith")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
            .background(.black)
        } detail: {
            // Main Content Area
            Group {
                switch selectedTab {
                case .chat:
                    ChatTabView()
                case .disk:
                    DiskView()
                case .cpu:
                    CPUView()
                case .battery:
                    BatteryView()
                }
            }
            .environmentObject(smithAgent)
            .navigationTitle(selectedTab.title)
            .background(.black)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

enum MainTab: String, CaseIterable {
    case chat = "chat"
    case disk = "disk"
    case cpu = "cpu"
    case battery = "battery"
    
    var title: String {
        switch self {
        case .chat: return "AI Chat"
        case .disk: return "Disk Analysis"
        case .cpu: return "CPU Monitor"
        case .battery: return "Battery Monitor"
        }
    }
    
    var icon: String {
        switch self {
        case .chat: return "message.circle.fill"
        case .disk: return "externaldrive.fill"
        case .cpu: return "cpu.fill"
        case .battery: return "battery.100.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .chat: return "Chat with AI assistant"
        case .disk: return "Browse and analyze files"
        case .cpu: return "Monitor CPU usage"
        case .battery: return "Monitor battery health"
        }
    }
}

struct NavigationTabRow: View {
    let tab: MainTab
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tab.icon)
                .foregroundColor(isSelected ? .cyan : .gray)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tab.title)
                    .foregroundColor(isSelected ? .white : .gray)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text(tab.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? .cyan.opacity(0.1) : .clear)
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    MainView()
}