//
//  DiskView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct DiskView: View {
    @StateObject private var fileManager = FileSystemManager()
    @EnvironmentObject private var smithAgent: SmithAgent
    // Currently unused but kept for future file actions
    @State private var selectedFileURL: URL?
    @State private var expandedFolders: Set<URL> = []
    
    var body: some View {
        VStack(spacing: 4) {
            // Ultra-Compact Header with navigation
            HStack {
                // Ultra-Compact Navigation buttons
                HStack(spacing: 3) {
                    Button {
                        fileManager.navigateToParent()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.cyan)
                            .font(.caption2)
                    }
                    .disabled(fileManager.currentPath == fileManager.currentPath.deletingLastPathComponent())
                    
                    Button {
                        fileManager.navigateToHome()
                    } label: {
                        Image(systemName: "house")
                            .foregroundColor(.cyan)
                            .font(.caption2)
                    }
                    
                    Button {
                        fileManager.navigateToDesktop()
                    } label: {
                        Image(systemName: "macwindow")
                            .foregroundColor(.cyan)
                            .font(.caption2)
                    }
                }
                
                Spacer()
                
                // Ultra-Compact Current path
                Text(fileManager.currentPath.lastPathComponent)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(6)
            .background(Color(.secondarySystemBackground))
            
            // Ultra-Compact File browser with info panel
            HStack(spacing: 4) {
                // Ultra-Compact File list
                VStack(spacing: 2) {
                    if fileManager.isLoading {
                        ProgressView("Loading...")
                            .controlSize(.mini)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = fileManager.errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.callout)
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption2)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 1) {
                                ForEach(fileManager.items.prefix(6), id: \.id) { item in
                                    UltraCompactFileRowView(item: item, isSelected: fileManager.selectedItem?.id == item.id)
                                        .onTapGesture {
                                            fileManager.selectItem(item)
                                            smithAgent.setFocusedFile(item)
                                        }
                                        .onTapGesture(count: 2) {
                                            if item.isDirectory {
                                                fileManager.loadDirectory(item.url)
                                            } else {
                                                askAboutFile(item)
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                .frame(maxHeight: 140)
                
                // Ultra-Compact File info panel
                VStack(alignment: .leading, spacing: 4) {
                    if let selectedItem = fileManager.selectedItem {
                        VStack(alignment: .leading, spacing: 4) {
                            // Ultra-Compact File icon and name
                            HStack {
                                Image(systemName: selectedItem.icon)
                                    .font(.callout)
                                    .foregroundColor(.cyan)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(selectedItem.name)
                                        .font(.caption2)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                    
                                    Text(selectedItem.isDirectory ? "Folder" : "File")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Ultra-Compact Quick actions
                            VStack(spacing: 2) {
                                Button("Necessary?") {
                                    askAboutFileNecessity(selectedItem)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                                
                                Button("Analyze") {
                                    analyzeFile(selectedItem)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                        .padding(6)
                    } else {
                        VStack {
                            Image(systemName: "doc.questionmark")
                                .font(.callout)
                                .foregroundColor(.gray)
                            
                            Text("Select file")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(6)
                    }
                }
                .frame(width: 100)
                .background(Color(.secondarySystemBackground))
            }
        }
        .background(Color(.systemBackground))
        .frame(maxHeight: 200)
    }
    
    private func askAboutFile(_ item: FileItem) {
        let question = "What does this file do?"
        
        Task {
            await smithAgent.sendMessage(question)
        }
    }
    
    private func askAboutFileNecessity(_ item: FileItem) {
        let question = "Is this file necessary and safe to delete?"
        
        Task {
            await smithAgent.sendMessage(question)
        }
    }
    
    private func analyzeFile(_ item: FileItem) {
        let question = "Please provide a detailed analysis of this file."
        
        Task {
            await smithAgent.sendMessage(question)
        }
    }
}

struct FileRowView: View {
    let item: FileItem
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundColor(item.isDirectory ? .cyan : .primary)
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !item.isDirectory {
                    Text(formatFileSize(item.size))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? .cyan.opacity(0.2) : .clear)
        )
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

struct CompactFileRowView: View {
    let item: FileItem
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundColor(item.isDirectory ? .cyan : .primary)
                .font(.caption)
                .frame(width: 12)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !item.isDirectory {
                    Text(formatFileSize(item.size))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 1)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? .cyan.opacity(0.2) : .clear)
        )
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

struct UltraCompactFileRowView: View {
    let item: FileItem
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundColor(item.isDirectory ? .cyan : .primary)
                .font(.caption2)
                .frame(width: 10)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !item.isDirectory {
                    Text(formatFileSize(item.size))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 1)
        .padding(.horizontal, 3)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(isSelected ? .cyan.opacity(0.2) : .clear)
        )
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

#Preview {
    DiskView()
        .environmentObject(SmithAgent())
}
