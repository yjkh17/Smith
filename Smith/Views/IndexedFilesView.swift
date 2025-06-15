//
//  IndexedFilesView.swift
//  Smith - Your AI Coding Craftsman
//
//  Created by Yousef Jawdat on 15/06/2025.
//

import SwiftUI

struct IndexedFilesView: View {
    @EnvironmentObject private var smithAgent: SmithAgent
    @State private var selectedFile: IndexedFile?
    @State private var searchText = ""
    @State private var selectedFileType: FileType?
    @Environment(\.dismiss) private var dismiss
    
    private var filteredFiles: [IndexedFile] {
        var files = smithAgent.xcodeIntegration.indexedFiles
        
        // Filter by search text
        if !searchText.isEmpty {
            files = smithAgent.xcodeIntegration.searchFiles(query: searchText)
        }
        
        // Filter by file type
        if let fileType = selectedFileType {
            files = files.filter { $0.fileType == fileType }
        }
        
        return files.sorted { $0.lastModified > $1.lastModified }
    }
    
    private var fileTypes: [FileType] {
        let types = Set(smithAgent.xcodeIntegration.indexedFiles.map { $0.fileType })
        return Array(types).sorted { $0.displayName < $1.displayName }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Project Files")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.black)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Files")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if smithAgent.xcodeIntegration.isIndexing {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Text("\(smithAgent.xcodeIntegration.indexedFiles.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            Task {
                                await smithAgent.xcodeIntegration.forceReindex()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .disabled(smithAgent.xcodeIntegration.isIndexing)
                    }
                }
                
                HStack(spacing: 8) {
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
                        .foregroundStyle(.primary)
                        .font(.caption)
                    
                    Menu {
                        Button("All") {
                            selectedFileType = nil
                        }
                        
                        ForEach(fileTypes, id: \.rawValue) { fileType in
                            Button(fileType.displayName) {
                                selectedFileType = fileType
                            }
                        }
                    } label: {
                        Image(systemName: selectedFileType?.icon ?? "doc")
                            .foregroundColor(selectedFileType?.color ?? .secondary)
                            .font(.caption)
                            .frame(width: 24, height: 24)
                            .background(.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .overlay(.gray.opacity(0.3))
            
            if smithAgent.xcodeIntegration.indexedFiles.isEmpty {
                MinimalEmptyView()
            } else if filteredFiles.isEmpty {
                MinimalNoResultsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredFiles, id: \.id) { file in
                            MinimalFileRowView(
                                file: file,
                                isSelected: selectedFile?.id == file.id
                            ) {
                                selectedFile = file
                                handleFileSelection(file)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .onAppear {
            if smithAgent.xcodeIntegration.indexedFiles.isEmpty && smithAgent.xcodeIntegration.isXcodeRunning {
                Task {
                    await smithAgent.xcodeIntegration.indexProjectFiles()
                }
            }
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }
    
    private func handleFileSelection(_ file: IndexedFile) {
        smithAgent.setCurrentFile(file.url)
        smithAgent.xcodeIntegration.openFileInXcode(file.url.path)
    }
}

struct MinimalFileRowView: View {
    let file: IndexedFile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // File type icon
            Image(systemName: file.fileType.icon)
                .foregroundColor(file.fileType.color)
                .font(.caption)
                .frame(width: 16)
            
            // File name
            Text(file.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
            
            // Minimal stats
            HStack(spacing: 6) {
                if file.summary.functionCount > 0 {
                    Text("\(file.summary.functionCount)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                
                if file.summary.totalTypes > 0 {
                    Text("\(file.summary.totalTypes)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                Text("indexed")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? .cyan.opacity(0.2) : .clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct MinimalEmptyView: View {
    @EnvironmentObject private var smithAgent: SmithAgent
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("No Files Indexed")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("Index Now") {
                Task {
                    await smithAgent.xcodeIntegration.indexProjectFiles()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(smithAgent.xcodeIntegration.isIndexing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct MinimalNoResultsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text("No Results")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct IndexedFileRowView: View {
    let file: IndexedFile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        // Keep for compatibility but hidden
        EmptyView()
    }
}

struct EmptyIndexedView: View {
    @EnvironmentObject private var smithAgent: SmithAgent
    
    var body: some View {
        // Keep for compatibility but hidden
        EmptyView()
    }
}

struct NoResultsView: View {
    let searchText: String
    let fileType: FileType?
    
    var body: some View {
        // Keep for compatibility but hidden
        EmptyView()
    }
}

// Keep the same FileTreeView name for compatibility
typealias FileTreeView = IndexedFilesView

#Preview {
    IndexedFilesView()
        .environmentObject(SmithAgent())
        .background(.black)
}
