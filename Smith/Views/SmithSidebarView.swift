//
//  SmithSidebarView.swift
//  Smith - Your AI Coding Craftsman
//
//  Created by Yousef Jawdat on 14/06/2025.
//

import SwiftUI
import Combine

struct SmithSidebarView: View {
    @StateObject private var smithAgent = SmithAgent()
    @State private var selectedConversation: Conversation?
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var refreshTimer: Timer?
    @State private var showingSettings = false
    @State private var showingFileTree = false
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Conversation History Sidebar
            VStack(spacing: 0) {
                // Header with modern macOS 26 styling
                HStack {
                    Text("Conversations")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        smithAgent.startNewConversation()
                    } label: {
                        Image(systemName: "plus.message.fill")
                            .foregroundColor(.cyan)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .help("New Conversation")
                    .buttonStyle(.plain)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.cyan.opacity(0.15))
                    )
                    .contentShape(Circle())
                    .scaleEffect(1.0)
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            // Hover effect handled by background opacity
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(.cyan.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.gray.opacity(0.0))
                
                Divider()
                    .overlay(.gray.opacity(0.5))
                
                // Conversation List
                List(smithAgent.conversations, selection: $selectedConversation) { conversation in
                    ConversationRowView(conversation: conversation)
                        .tag(conversation)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedConversation?.id == conversation.id ? .cyan.opacity(0.2) : .clear)
                        )
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 2)
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .background(.gray.opacity(0.0))
            }
            .navigationTitle("SMITH")
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
            .background(.black)
        } detail: {
            VStack(spacing: 0) {
                Divider()
                
                // Show Chat directly without tab switching
                if let selectedConversation = selectedConversation {
                    ChatTabView(conversation: selectedConversation)
                        .environmentObject(smithAgent)
                } else {
                    ChatEmptyStateView {
                        smithAgent.startNewConversation()
                    }
                }
            }
            .navigationTitle(selectedConversation?.title ?? "Chat")
            .background(.black)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        smithAgent.startNewConversation()
                    } label: {
                        Image(systemName: "plus.message")
                            .foregroundColor(.cyan)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .help("New Conversation")
                    .buttonStyle(.plain)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(.cyan.opacity(0.1))
                            .opacity(0)
                    )
                    .contentShape(Circle())
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            // Hover feedback handled by system
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        // File tree button with enhanced safe area
                        Button {
                            showingFileTree = true
                        } label: {
                            Image(systemName: "folder")
                                .foregroundColor(.cyan)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .help("Browse Project Files")
                        .buttonStyle(.plain)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.cyan.opacity(0.1))
                                .opacity(0)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 6))
                        .onHover { isHovered in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                // System handles hover state
                            }
                        }
                        
                        // Visual separator
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .frame(width: 1, height: 16)
                            .padding(.horizontal, 4)
                        
                        // Settings button with enhanced safe area
                        Button {
                            openSettingsWindow()
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundColor(.cyan)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .help("Smith Settings")
                        .buttonStyle(.plain)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.cyan.opacity(0.1))
                                .opacity(0)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 6))
                        .onHover { isHovered in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                // System handles hover state
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                
                ToolbarItem(placement: .status) {
                    HStack(spacing: 12) {
                        // Xcode integration status only
                        HStack(spacing: 6) {
                            Image("ProjectImage")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                .foregroundColor(smithAgent.xcodeIntegration.isXcodeRunning ? .green : .gray)
                            
                            if let activeFile = smithAgent.xcodeIntegration.activeFile {
                                Text(cleanFileName(activeFile.lastPathComponent))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .frame(maxWidth: 120, alignment: .leading)
                            } else {
                                Text("No Active File")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.gray.opacity(0.0))
                        )
                        .help(smithAgent.xcodeIntegration.isXcodeRunning ? "Xcode Connected" : "Xcode Not Running")
                    }
                    .padding(.trailing, 8)
                }
            }
            .toolbarBackground(.visible, for: .windowToolbar)
            .toolbarColorScheme(.dark, for: .windowToolbar)
        }
        .background(.black)
        .sheet(isPresented: $showingFileTree) {
            IndexedFilesView()
                .environmentObject(smithAgent)
        }
        .onAppear {
            // Select the current conversation if available
            if let current = smithAgent.currentConversation {
                selectedConversation = current
            }
            
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
        .onChange(of: selectedConversation) { oldValue, newValue in
            if let conversation = newValue {
                smithAgent.selectConversation(conversation)
            }
        }
        .onChange(of: smithAgent.currentConversation) { oldValue, newValue in
            selectedConversation = newValue
        }
    }
    
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { @MainActor in
                // Force refresh of conversation list to update relative dates
                smithAgent.objectWillChange.send()
            }
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
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
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.makeKeyAndOrderFront(nil)
        
        // Make sure the window is visible
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func cleanFileName(_ fileName: String) -> String {
        // Remove .xcodeproj extension
        if fileName.hasSuffix(".xcodeproj") {
            return String(fileName.dropLast(10)) // Remove ".xcodeproj" (10 characters)
        }
        
        // Remove other common project extensions if needed
        if fileName.hasSuffix(".xcworkspace") {
            return String(fileName.dropLast(12)) // Remove ".xcworkspace" (12 characters)
        }
        
        return fileName
    }
}

struct ChatEmptyStateView: View {
    let onNewConversation: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.circle")
                .font(.system(size: 64))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("Start a Conversation")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Select a conversation from the sidebar or start a new one to chat with Smith")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("New Conversation") {
                onNewConversation()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ConversationRowView: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(conversation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(conversation.lastMessageDate, style: .relative)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.cyan.opacity(0.8))
            }
            
            if let lastMessage = conversation.lastMessage {
                Text(lastMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.clear)
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    SmithSidebarView()
        .frame(width: 800, height: 600)
}
