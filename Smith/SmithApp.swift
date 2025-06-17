//
//  SmithApp.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 14/06/2025.
//

import SwiftUI

@main
struct SmithApp: App {
    @StateObject private var smithAgent = SmithAgent()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(smithAgent)
                .preferredColorScheme(.dark)
                .background(.ultraThinMaterial)
                .onReceive(NotificationCenter.default.publisher(for: .smithAnalyzeFile)) { notification in
                    if let filePath = notification.object as? String {
                        handleFileAnalysis(filePath)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .smithShowCPU)) { _ in
                    // Handle CPU view showing
                }
                .onReceive(NotificationCenter.default.publisher(for: .smithSendMessage)) { notification in
                    if let message = notification.object as? String {
                        Task {
                            await smithAgent.sendMessage(message)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .smithShowChat)) { _ in
                    // Focus on chat - implementation depends on your UI structure
                }
                .onReceive(NotificationCenter.default.publisher(for: .smithShowCleanup)) { _ in
                    // Show cleanup suggestions
                    Task {
                        await smithAgent.sendMessage("Please provide system cleanup suggestions for my Mac.")
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            SmithCommands()
        }
    }
    
    private func handleFileAnalysis(_ filePath: String) {
        // Create FileItem from path and set as focused
        if let url = URL(string: filePath),
           let fileItem = FileItem(url: url) {
            smithAgent.setFocusedFile(fileItem)
            
            Task {
                await smithAgent.sendMessage("Please analyze this file and tell me what it does.")
            }
        }
    }
}

struct SmithCommands: Commands {
    var body: some Commands {
        CommandMenu("Smith") {
            Button("New Conversation") {
                NotificationCenter.default.post(name: .smithShowChat, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command])
            
            Button("Analyze System Health") {
                NotificationCenter.default.post(name: .smithSendMessage, object: "Analyze my system health and performance")
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            
            Button("Quick CPU Check") {
                NotificationCenter.default.post(name: .smithShowCPU, object: nil)
            }
            .keyboardShortcut("u", modifiers: [.command, .shift])
            
            Button("System Cleanup") {
                NotificationCenter.default.post(name: .smithShowCleanup, object: nil)
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Toggle Main Window") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut("s", modifiers: [.command, .option])
        }
        
        CommandGroup(replacing: .help) {
            Button("Smith Help") {
                NotificationCenter.default.post(name: .smithSendMessage, object: "How can I use Smith effectively?")
            }
        }
    }
}
