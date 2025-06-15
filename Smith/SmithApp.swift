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
            SmithSidebarView()
                .frame(minWidth: 400, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .windowBackgroundDragBehavior(.enabled)
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 700)
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
        CommandGroup(after: .newItem) {
            Button("Analyze Current File") {
                // TODO: Implement global action
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])
            
            Button("Quick Code Review") {
                // TODO: Implement global action
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            
            Button("Generate Unit Tests") {
                // TODO: Implement global action
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
        }
        
        CommandMenu("Smith") {
            Button("Settings...") {
                openSettingsWindow()
            }
            .keyboardShortcut(",", modifiers: [.command])
            
            Divider()
            
            Button("Toggle Auto-Apply Mode") {
                // TODO: Implement global action
            }
            .keyboardShortcut("m", modifiers: [.command, .option])
            
            Button("Show/Hide Smith") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut("k", modifiers: [.command])
        }
    }
    
    private func openSettingsWindow() {
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        settingsWindow.title = "Smith Settings"
        settingsWindow.contentViewController = hostingController
        settingsWindow.center()
        settingsWindow.setFrameAutosaveName("SmithSettingsWindow")
        settingsWindow.makeKeyAndOrderFront(nil)
        
        // Make sure the window is visible
        NSApp.activate(ignoringOtherApps: true)
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
        .frame(width: 160)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
