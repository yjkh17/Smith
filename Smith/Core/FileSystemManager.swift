//
//  FileSystemManager.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
class FileSystemManager: ObservableObject {
    @Published var currentPath: URL = FileManager.default.homeDirectoryForCurrentUser
    @Published var items: [FileItem] = []
    @Published var selectedItem: FileItem?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadDirectory(currentPath)
    }
    
    func loadDirectory(_ url: URL) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [
                        .isDirectoryKey,
                        .fileSizeKey,
                        .contentModificationDateKey,
                        .isHiddenKey
                    ],
                    options: [.skipsHiddenFiles]
                )
                
                let fileItems = contents.compactMap { url -> FileItem? in
                    return FileItem(url: url)
                }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                
                await MainActor.run {
                    self.currentPath = url
                    self.items = fileItems
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load directory: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func navigateToParent() {
        let parentURL = currentPath.deletingLastPathComponent()
        if parentURL != currentPath {
            loadDirectory(parentURL)
        }
    }
    
    func navigateToHome() {
        loadDirectory(FileManager.default.homeDirectoryForCurrentUser)
    }
    
    func navigateToDesktop() {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        loadDirectory(desktopURL)
    }
    
    func navigateToDocuments() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        loadDirectory(documentsURL)
    }
    
    func selectItem(_ item: FileItem) {
        selectedItem = item
    }
    
    func getFileInfo(_ item: FileItem) -> String {
        var info = "File: \(item.name)\n"
        info += "Path: \(item.url.path)\n"
        info += "Type: \(item.isDirectory ? "Directory" : "File")\n"
        
        if !item.isDirectory {
            info += "Size: \(formatFileSize(item.size))\n"
            info += "Extension: \(item.url.pathExtension.isEmpty ? "None" : item.url.pathExtension)\n"
        }
        
        if let modificationDate = item.modificationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            info += "Modified: \(formatter.string(from: modificationDate))\n"
        }
        
        return info
    }
    
    func analyzeFile(_ item: FileItem) -> String {
        var analysis = "File Analysis for: \(item.name)\n\n"
        
        if item.isDirectory {
            analysis += "This is a directory/folder that can contain other files and folders.\n"
            
            // Analyze common system directories
            switch item.name.lowercased() {
            case "applications":
                analysis += "System directory containing installed applications."
            case "library":
                analysis += "System directory containing application support files, preferences, and caches."
            case "system":
                analysis += "Critical system directory - DO NOT MODIFY."
            case "users":
                analysis += "Contains user home directories."
            case "downloads":
                analysis += "Default download location for web browsers and other applications."
            case "documents":
                analysis += "Default location for user documents."
            case "desktop":
                analysis += "Items displayed on the desktop."
            default:
                analysis += "User or application directory."
            }
        } else {
            // Analyze file types
            let ext = item.url.pathExtension.lowercased()
            
            switch ext {
            case "app":
                analysis += "macOS Application Bundle - Can be safely moved to Trash if not needed."
            case "dmg":
                analysis += "Disk Image file - Usually an installer that can be deleted after installation."
            case "pkg", "mpkg":
                analysis += "Installer package - Can be deleted after installation."
            case "zip", "rar", "7z":
                analysis += "Archive file - Can be deleted if contents have been extracted."
            case "tmp", "temp":
                analysis += "Temporary file - Usually safe to delete."
            case "log":
                analysis += "Log file - Can be deleted to free space, but may be useful for debugging."
            case "cache":
                analysis += "Cache file - Safe to delete, will be recreated as needed."
            case "plist":
                analysis += "Property list file - Contains application settings. Deleting may reset app preferences."
            case "db", "sqlite", "sql":
                analysis += "Database file - Contains important data, be careful before deleting."
            case "txt", "md", "rtf":
                analysis += "Text document - User content, check before deleting."
            case "pdf":
                analysis += "PDF document - User content, check before deleting."
            case "jpg", "jpeg", "png", "gif", "tiff", "heic":
                analysis += "Image file - User content, check before deleting."
            case "mp4", "mov", "avi", "mkv":
                analysis += "Video file - User content, check before deleting."
            case "mp3", "aac", "wav", "flac":
                analysis += "Audio file - User content, check before deleting."
            default:
                analysis += "File of type: \(ext.isEmpty ? "unknown" : ext.uppercased())"
            }
            
            // Size analysis
            if item.size > 1_000_000_000 { // > 1GB
                analysis += "\n⚠️ Large file (\(formatFileSize(item.size))) - Consider if still needed."
            } else if item.size > 100_000_000 { // > 100MB
                analysis += "\n📦 Medium-sized file (\(formatFileSize(item.size)))"
            }
        }
        
        return analysis
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date?
    let isHidden: Bool
    
    init?(url: URL) {
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .isDirectoryKey,
                .fileSizeKey,
                .contentModificationDateKey,
                .isHiddenKey,
                .nameKey
            ])
            
            self.url = url
            self.name = resourceValues.name ?? url.lastPathComponent
            self.isDirectory = resourceValues.isDirectory ?? false
            self.size = Int64(resourceValues.fileSize ?? 0)
            self.modificationDate = resourceValues.contentModificationDate
            self.isHidden = resourceValues.isHidden ?? false
            
        } catch {
            return nil
        }
    }
    
    var icon: String {
        if isDirectory {
            return "folder.fill"
        }
        
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "app":
            return "app.fill"
        case "txt", "md":
            return "doc.text.fill"
        case "pdf":
            return "doc.fill"
        case "jpg", "jpeg", "png", "gif", "tiff", "heic":
            return "photo.fill"
        case "mp4", "mov", "avi", "mkv":
            return "video.fill"
        case "mp3", "aac", "wav", "flac":
            return "music.note"
        case "zip", "rar", "7z":
            return "archivebox.fill"
        case "dmg":
            return "externaldrive.fill"
        default:
            return "doc.fill"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url
    }
}
