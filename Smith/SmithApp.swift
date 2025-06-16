//
//  SmithApp.swift
//  Smith - Your AI Coding Craftsman
//
//  Created by Yousef Jawdat on 14/06/2025.
//

import SwiftUI

@main
struct SmithApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 800, maxWidth: .infinity, minHeight: 700, maxHeight: .infinity)
                .background(.black)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .windowBackgroundDragBehavior(.enabled)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        .commands {
            SmithCommands()
        }
        
        MenuBarExtra("Smith", systemImage: "brain") {
            SmithMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}

struct SmithCommands: Commands {
    var body: some Commands {
        CommandMenu("Smith") {
            Button("New Conversation") {
                // TODO: Add global action for new conversation
            }
            .keyboardShortcut("n", modifiers: [.command])
            
            Button("Analyze System Health") {
                // TODO: Add global action for system health analysis
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Show/Hide Smith") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut("k", modifiers: [.command])
        }
    }
}

struct SmithMenuBarView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.cyan)
                    .font(.title2)
                Text("SMITH")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .fontDesign(.monospaced)
            }
            
            Divider()
                .overlay(.cyan.opacity(0.3))
            
            Text("AI System Assistant")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button("Show Smith") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.borderedProminent)
            
            Button("Quit Smith") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 180)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
