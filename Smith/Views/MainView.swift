//
//  MainView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import SwiftUI

struct MainView: View {
    @StateObject private var smithAgent = SmithAgent()
    @State private var selectedSystemView: SystemView = .disk
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation buttons
            HStack {
                // App branding
                HStack(spacing: 8) {
                    Image(systemName: "brain")
                        .foregroundColor(.cyan)
                        .font(.title2)
                    
                    Text("SMITH")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .fontDesign(.monospaced)
                    
                    Text("AI System Assistant")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // System view selector buttons
                HStack(spacing: 4) {
                    ForEach(SystemView.allCases, id: \.self) { view in
                        Button {
                            selectedSystemView = view
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: view.icon)
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text(view.title)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(selectedSystemView == view ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedSystemView == view ? .cyan : .gray.opacity(0.2))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(smithAgent.isAvailable ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Text(smithAgent.isAvailable ? "AI Ready" : "AI Unavailable")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if smithAgent.isProcessing {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }
            }
            .padding()
            .background(.gray.opacity(0.1))
            
            Divider()
            
            // Main content area - two sections
            HStack(spacing: 0) {
                // Left section - System monitoring views
                VStack(spacing: 0) {
                    // Section header
                    HStack {
                        Image(systemName: selectedSystemView.icon)
                            .foregroundColor(.cyan)
                            .font(.headline)
                        
                        Text(selectedSystemView.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(selectedSystemView.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(.gray.opacity(0.05))
                    
                    Divider()
                    
                    // System view content
                    Group {
                        switch selectedSystemView {
                        case .disk:
                            DiskView()
                        case .cpu:
                            CPUView()
                        case .battery:
                            BatteryView()
                        }
                    }
                    .environmentObject(smithAgent)
                }
                .frame(minWidth: 400, maxWidth: .infinity)
                .background(.black)
                
                Divider()
                    .background(.gray.opacity(0.3))
                
                // Right section - Chat
                VStack(spacing: 0) {
                    // Chat header
                    HStack {
                        Image(systemName: "message.circle.fill")
                            .foregroundColor(.cyan)
                            .font(.headline)
                        
                        Text("AI Chat")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Ask questions about your system")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(.gray.opacity(0.05))
                    
                    Divider()
                    
                    // Chat content
                    ChatView()
                        .environmentObject(smithAgent)
                }
                .frame(minWidth: 350, maxWidth: .infinity)
                .background(.black)
            }
        }
        .background(.black)
    }
}

enum SystemView: String, CaseIterable {
    case disk = "disk"
    case cpu = "cpu"
    case battery = "battery"
    
    var title: String {
        switch self {
        case .disk: return "Disk"
        case .cpu: return "CPU"
        case .battery: return "Battery"
        }
    }
    
    var icon: String {
        switch self {
        case .disk: return "externaldrive.fill"
        case .cpu: return "cpu.fill"
        case .battery: return "battery.100.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .disk: return "Browse and analyze files"
        case .cpu: return "Monitor CPU usage"
        case .battery: return "Monitor battery health"
        }
    }
}

#Preview {
    MainView()
}
