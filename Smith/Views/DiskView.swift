//
//  DiskView.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import SwiftUI

struct DiskView: View {
    @StateObject private var fileManager = FileSystemManager()
    @EnvironmentObject private var smithAgent: SmithAgent
    @State private var showingFilePicker = false
    @State private var selectedFileURL: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation
            HStack {
                // Navigation buttons
                HStack(spacing: 8) {
                    Button {
                        fileManager.navigateToParent()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.cyan)
                    }
                    .disabled(fileManager.currentPath == fileManager.currentPath.deletingLastPathComponent())
                    
                    Button {
                        fileManager.navigateToHome()
                    } label: {
                        Image(systemName: "house")
                            .foregroundColor(.cyan)
                    }
                    
                    Button {
                        fileManager.navigateToDesktop()
                    } label: {
                        Image(systemName: "macwindow")
                            .foregroundColor(.cyan)
                    }
                    
                    Button {
                        fileManager.navigateToDocuments()
                    } label: {
                        Image(systemName: "doc")
                            .foregroundColor(.cyan)
                    }
                }
                
                Spacer()
                
                // Current path
                Text(fileManager.currentPath.path)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                // File picker button
                Button("Select File") {
                    showingFilePicker = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.gray.opacity(0.1))
            
            Divider()
            
            HStack(spacing: 0) {
                // File browser
                VStack(spacing: 0) {
                    if fileManager.isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = fileManager.errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(fileManager.items, selection: Binding<FileItem?>(
                            get: { fileManager.selectedItem },
                            set: { item in
                                if let item = item {
                                    fileManager.selectItem(item)
                                    if item.isDirectory {
                                        fileManager.loadDirectory(item.url)
                                    }
                                }
                            }
                        )) { item in
                            FileRowView(item: item)
                                .onTapGesture(count: 2) {
                                    if item.isDirectory {
                                        fileManager.loadDirectory(item.url)
                                    } else {
                                        askAboutFile(item)
                                    }
                                }
                        }
                        .listStyle(.sidebar)
                        .scrollContentBackground(.hidden)
                    }
                }
                .frame(minWidth: 300)
                
                Divider()
                
                // File info panel
                VStack(alignment: .leading, spacing: 16) {
                    if let selectedItem = fileManager.selectedItem {
                        VStack(alignment: .leading, spacing: 12) {
                            // File icon and name
                            HStack {
                                Image(systemName: selectedItem.icon)
                                    .font(.largeTitle)
                                    .foregroundColor(.cyan)
                                
                                VStack(alignment: .leading) {
                                    Text(selectedItem.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(selectedItem.isDirectory ? "Folder" : "File")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Divider()
                            
                            // File details
                            Text("Details")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(fileManager.getFileInfo(selectedItem))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textSelection(.enabled)
                            
                            Divider()
                            
                            // Quick actions
                            VStack(spacing: 8) {
                                Button("Ask: What does this file do?") {
                                    askAboutFile(selectedItem)
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("Ask: Is this file necessary?") {
                                    askAboutFileNecessity(selectedItem)
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Analyze File") {
                                    analyzeFile(selectedItem)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                    } else {
                        VStack {
                            Image(systemName: "doc.questionmark")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            
                            Text("Select a file or folder")
                                .foregroundColor(.gray)
                            
                            Text("Double-click to open folders or ask questions about files")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 250)
                .background(.gray.opacity(0.05))
            }
        }
        .background(.black)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedFileURL = url
                    let fileItem = FileItem(url: url)
                    if let fileItem = fileItem {
                        fileManager.selectItem(fileItem)
                        askAboutFile(fileItem)
                    }
                }
            case .failure(let error):
                print("File selection failed: \(error)")
            }
        }
    }
    
    private func askAboutFile(_ item: FileItem) {
        let question = "What does this file do?\n\nFile: \(item.name)\nPath: \(item.url.path)\nType: \(item.isDirectory ? "Directory" : "File")"
        
        Task {
            await smithAgent.sendMessage(question)
        }
    }
    
    private func askAboutFileNecessity(_ item: FileItem) {
        let question = "Is this file necessary and safe to delete?\n\nFile: \(item.name)\nPath: \(item.url.path)\nType: \(item.isDirectory ? "Directory" : "File")"
        
        Task {
            await smithAgent.sendMessage(question)
        }
    }
    
    private func analyzeFile(_ item: FileItem) {
        let analysis = fileManager.analyzeFile(item)
        
        Task {
            await smithAgent.sendMessage("Please provide a detailed analysis of this file:\n\n\(analysis)")
        }
    }
}

struct FileRowView: View {
    let item: FileItem
    
    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundColor(item.isDirectory ? .cyan : .white)
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if !item.isDirectory {
                    Text(formatFileSize(item.size))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if let modDate = item.modificationDate {
                Text(modDate, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 2)
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