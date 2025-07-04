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
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(Spacing.small)
            .background(Color.panelBackground)
            
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
                            .padding(.horizontal, Spacing.xsmall)
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
                                        .foregroundColor(Color.primary)
                                        .lineLimit(2)
                                    
                                    Text(selectedItem.isDirectory ? "Folder" : "File")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
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
                        .padding(Spacing.small)
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
                        .padding(Spacing.small)
                    }
                }
                .frame(width: 100)
                .background(Color.secondary.opacity(0.05))
            }
        }
        .background(.black)
        .frame(maxHeight: 200)
    }
    
    private func askAboutFile(_ item: FileItem) {
        let question = "What does this file do?"
        
        Task {
            smithAgent.sendMessage(question)
        }
    }
    
    private func askAboutFileNecessity(_ item: FileItem) {
        let question = "Is this file necessary and safe to delete?"
        
        Task {
            smithAgent.sendMessage(question)
        }
    }
    
    private func analyzeFile(_ item: FileItem) {
        let question = "Please provide a detailed analysis of this file."
        
        Task {
            smithAgent.sendMessage(question)
        }
    }
}

struct FileRowView: View {
    let item: FileItem
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundColor(item.isDirectory ? .cyan : .white)
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .foregroundColor(Color.primary)
                    .lineLimit(1)
                
                if !item.isDirectory {
                    Text(formatFileSize(item.size))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.xsmall)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
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
                .foregroundColor(item.isDirectory ? .cyan : .white)
                .font(.caption)
                .frame(width: 12)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.caption)
                    .foregroundColor(Color.primary)
                    .lineLimit(1)
                
                if !item.isDirectory {
                    Text(formatFileSize(item.size))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.xsmall)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small)
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
                .foregroundColor(item.isDirectory ? .cyan : .white)
                .font(.caption2)
                .frame(width: 10)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .font(.caption2)
                    .foregroundColor(Color.primary)
                    .lineLimit(1)
                
                if !item.isDirectory {
                    Text(formatFileSize(item.size))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.xsmall)
        .padding(.horizontal, Spacing.xsmall)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xsmall)
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
