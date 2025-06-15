import Foundation
import Combine
import AppKit
import SwiftUI

@MainActor
class XcodeIntegration: ObservableObject {
    @Published var activeFile: URL?
    @Published var projectRoot: URL?
    @Published var recentFiles: [URL] = []
    @Published var xcodeVersion: String?
    @Published var isXcodeRunning = false
    
    @Published var indexedFiles: [IndexedFile] = []
    @Published var isIndexing = false
    @Published var indexingProgress: Double = 0.0
    @Published var lastIndexTime: Date?
    
    // Status callback for SmithAgent
    var onStatusUpdate: ((String, String) -> Void)?
    
    private var fileMonitor: DispatchSourceFileSystemObject?
    private var cancellables = Set<AnyCancellable>()
    
    private var lastCheckTime: Date = Date()
    private let checkInterval: TimeInterval = 2.0
    
    private let maxFileSize: Int64 = 2_000_000 // 2MB limit
    private let supportedExtensions = ["swift", "m", "mm", "h", "hpp", "cpp", "c"]
    
    init() {
        print(" Initializing XcodeIntegration...")
        startMonitoring()
        checkXcodeStatus()
        
        requestAppleScriptPermissions()
    }
    
    private func requestAppleScriptPermissions() {
        // This will trigger the system to show Smith in Automation settings
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.triggerAppleScriptPermissionRequest()
        }
    }
    
    private func triggerAppleScriptPermissionRequest() {
        print(" Requesting AppleScript permissions...")
        
        let script = """
        tell application "System Events"
            try
                -- This will trigger the permission dialog
                get name of every process
                return "System Events access granted"
            on error errMsg number errNum
                return "Error: " & errMsg & " (Code: " & errNum & ")"
            end try
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary?
        
        if let result = appleScript?.executeAndReturnError(&errorDict) {
            let response = result.stringValue ?? ""
            print(" AppleScript result: \(response)")
            
            // If we get an error about authorization, show the manual steps
            if response.contains("Not authorized") || response.contains("Code: -600") {
                DispatchQueue.main.async {
                    self.showPermissionInstructions()
                }
            }
        } else {
            print(" AppleScript execution failed")
            if let error = errorDict {
                print("Error details: \(error)")
            }
            
            DispatchQueue.main.async {
                self.showPermissionInstructions()
            }
        }
    }
    
    private func showPermissionInstructions() {
        let alert = NSAlert()
        alert.messageText = "Smith needs permission to access System Events"
        alert.informativeText = """
        To enable Xcode integration, follow these steps:
        
        1. Open Terminal
        2. Run this command to reset permissions:
           tccutil reset AppleEvents
        
        3. Run this command to trigger permission request:
           osascript -e 'tell application "System Events" to activate'
        
        4. Click "OK" when macOS asks for permission
        5. Go to System Settings → Privacy & Security → Automation
        6. Enable "System Events" for Smith
        7. Restart Smith
        
        Alternative: You can also try running the permission request from Xcode itself.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Copy Terminal Command")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            // Copy the terminal command to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString("osascript -e 'tell application \"System Events\" to activate'", forType: .string)
        }
    }
    
    // MARK: - Enhanced Xcode Monitoring
    func startMonitoring() {
        print(" Starting Xcode monitoring...")
        
        // Monitor Xcode status and active files
        Timer.publish(every: checkInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkXcodeStatus()
                self?.checkActiveXcodeFile()
                self?.detectProjectRoot()
            }
            .store(in: &cancellables)
            
        $projectRoot
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] projectRoot in
                print(" Project root changed: \(projectRoot?.path ?? "None")")
                if projectRoot != nil {
                    Task {
                        await self?.indexProjectFiles()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - File Indexing Methods
    func indexProjectFiles() async {
        guard let projectRoot = projectRoot else {
            print(" No project root found")
            return
        }
        
        isIndexing = true
        indexingProgress = 0.0
        var newIndexedFiles: [IndexedFile] = []
        
        // Shorter status updates
        onStatusUpdate?("indexing", "Scanning...")
        
        print(" Starting file indexing for project: \(projectRoot.lastPathComponent)")
        
        let fileManager = FileManager.default
        
        var allFiles: [URL] = []
        
        if let enumerator = fileManager.enumerator(
            at: projectRoot,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) {
            while let fileURL = enumerator.nextObject() as? URL {
                if supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
                    allFiles.append(fileURL)
                }
            }
        }
        
        let totalFiles = allFiles.count
        print(" Found \(totalFiles) files to index")
        
        onStatusUpdate?("indexing", "Indexing...")
        
        for (index, fileURL) in allFiles.enumerated() {
            // Simplified progress updates
            let currentFileNumber = index + 1
            
            if currentFileNumber % 5 == 0 { // Update every 5 files to reduce UI churn
                onStatusUpdate?("indexing", "\(currentFileNumber)/\(totalFiles)")
            }
            
            if let indexedFile = await indexSingleFile(fileURL) {
                newIndexedFiles.append(indexedFile)
            }
            
            indexingProgress = Double(index + 1) / Double(totalFiles)
            
            if index % 10 == 0 {
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
        
        indexedFiles = newIndexedFiles.sorted { $0.lastModified > $1.lastModified }
        lastIndexTime = Date()
        isIndexing = false
        indexingProgress = 1.0
        
        onStatusUpdate?("idle", "")
        
        print(" Indexing complete: \(indexedFiles.count) files indexed")
    }
    
    private func indexSingleFile(_ url: URL) async -> IndexedFile? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            
            guard let fileSize = attributes[.size] as? Int64 else {
                print(" Could not determine file size for: \(url.lastPathComponent)")
                return nil
            }
            
            guard fileSize < maxFileSize else {
                print(" Skipping large file: \(url.lastPathComponent) (\(fileSize) bytes)")
                return nil
            }
            
            let content = try String(contentsOf: url, encoding: .utf8)
            let modificationDate = attributes[.modificationDate] as? Date ?? Date()
            
            return IndexedFile(
                url: url,
                name: url.lastPathComponent,
                relativePath: getRelativePath(for: url),
                content: content,
                fileSize: fileSize,
                lastModified: modificationDate,
                fileType: FileType(from: url.pathExtension),
                summary: generateFileSummary(content: content, fileName: url.lastPathComponent)
            )
            
        } catch {
            print(" Failed to index file \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    private func getRelativePath(for url: URL) -> String {
        guard let projectRoot = projectRoot else { return url.path }
        
        let projectPath = projectRoot.path
        let filePath = url.path
        
        if filePath.hasPrefix(projectPath) {
            let relativePath = String(filePath.dropFirst(projectPath.count))
            return relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
        }
        
        return url.path
    }
    
    private func generateFileSummary(content: String, fileName: String) -> FileSummary {
        let lines = content.components(separatedBy: .newlines)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let functions = content.matches(of: /func\s+\w+/).count
        let classes = content.matches(of: /class\s+\w+/).count
        let structs = content.matches(of: /struct\s+\w+/).count
        let enums = content.matches(of: /enum\s+\w+/).count
        let protocols = content.matches(of: /protocol\s+\w+/).count
        
        let imports = lines.compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("import ") {
                return String(trimmed.dropFirst(7))
            }
            return nil
        }
        
        let typeMatches = content.matches(of: /(class|struct|enum|protocol)\s+(\w+)/)
        let typeNames = typeMatches.compactMap { match in
            let matchString = String(content[match.range])
            let components = matchString.components(separatedBy: .whitespaces)
            return components.count >= 2 ? components[1] : nil
        }
        
        return FileSummary(
            lineCount: lines.count,
            nonEmptyLineCount: nonEmptyLines.count,
            functionCount: functions,
            classCount: classes,
            structCount: structs,
            enumCount: enums,
            protocolCount: protocols,
            imports: imports,
            typeNames: typeNames
        )
    }
    
    // MARK: - Search and Filter Methods
    func searchFiles(query: String) -> [IndexedFile] {
        guard !query.isEmpty else { return indexedFiles }
        
        let lowercaseQuery = query.lowercased()
        
        return indexedFiles.filter { file in
            if file.name.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            if file.relativePath.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            if file.summary.typeNames.contains(where: { $0.lowercased().contains(lowercaseQuery) }) {
                return true
            }
            
            if file.summary.imports.contains(where: { $0.lowercased().contains(lowercaseQuery) }) {
                return true
            }
            
            if file.content.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            return false
        }
    }
    
    func getFilesByType(_ fileType: FileType) -> [IndexedFile] {
        return indexedFiles.filter { $0.fileType == fileType }
    }
    
    func getRecentlyModifiedFiles(limit: Int = 10) -> [IndexedFile] {
        return Array(indexedFiles.prefix(limit))
    }
    
    func forceReindex() async {
        await indexProjectFiles()
    }
    
    private func checkXcodeStatus() {
        let runningApps = NSWorkspace.shared.runningApplications
        let wasRunning = isXcodeRunning
        isXcodeRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.dt.Xcode" }
        
        if isXcodeRunning != wasRunning {
            print(" Xcode status changed: \(isXcodeRunning ? "Running" : "Not Running")")
        }
        
        if isXcodeRunning {
            getXcodeVersion()
        }
    }
    
    private func getXcodeVersion() {
        let script = """
        tell application "Xcode"
            try
                return version
            on error
                return "Unknown"
            end try
        end tell
        """
        
        Task.detached {
            let appleScript = NSAppleScript(source: script)
            if let result = appleScript?.executeAndReturnError(nil),
               let version = result.stringValue {
                await MainActor.run {
                    self.xcodeVersion = version
                }
            }
        }
    }
    
    private func checkActiveXcodeFile() {
        guard isXcodeRunning else {
            if activeFile != nil {
                print(" Clearing active file (Xcode not running)")
                activeFile = nil
            }
            return
        }
        
        let script = """
        tell application "System Events"
            if exists (processes whose name is "Xcode") then
                tell application "Xcode"
                    try
                        set currentDoc to document 1
                        set docPath to path of currentDoc
                        return docPath
                    on error errMsg
                        return "ERROR: " & errMsg
                    end try
                end tell
            else
                return "NO_XCODE"
            end if
        end tell
        """
        
        Task.detached {
            let appleScript = NSAppleScript(source: script)
            var errorDict: NSDictionary?
            
            if let result = appleScript?.executeAndReturnError(&errorDict) {
                let response = result.stringValue ?? ""
                
                await MainActor.run {
                    if response.hasPrefix("ERROR:") {
                        print(" Project detection error: \(response)")
                    } else if response == "NO_XCODE" {
                        print(" Xcode process not found")
                    } else if !response.isEmpty && response != "missing value" {
                        let fileURL = URL(fileURLWithPath: response)
                        if fileURL != self.activeFile {
                            print(" Active file changed: \(fileURL.lastPathComponent)")
                            self.activeFile = fileURL
                            self.updateRecentFiles(fileURL)
                        }
                    }
                }
            } else if let error = errorDict {
                print(" AppleScript execution failed: \(error)")
            }
        }
    }
    
    private func detectProjectRoot() {
        guard activeFile != nil else {
            if projectRoot != nil {
                print(" Clearing project root (no active file)")
                projectRoot = nil
            }
            return
        }
        
        let script = """
        tell application "System Events"
            if exists (processes whose name is "Xcode") then
                tell application "Xcode"
                    try
                        set currentWorkspace to active workspace document
                        if currentWorkspace is not missing value then
                            return path of currentWorkspace
                        end if
                        
                        set currentProject to project document 1
                        if currentProject is not missing value then
                            return path of currentProject
                        end if
                        
                        return "NO_PROJECT"
                    on error errMsg
                        return "ERROR: " & errMsg
                    end try
                end tell
            else
                return "NO_XCODE"
            end if
        end tell
        """
        
        Task.detached {
            let appleScript = NSAppleScript(source: script)
            var errorDict: NSDictionary?
            
            if let result = appleScript?.executeAndReturnError(&errorDict) {
                let response = result.stringValue ?? ""
                
                await MainActor.run {
                    if response.hasPrefix("ERROR:") {
                        print(" Project detection error: \(response)")
                    } else if response == "NO_XCODE" || response == "NO_PROJECT" {
                        print(" No project detected in Xcode")
                    } else if !response.isEmpty {
                        let projectURL = URL(fileURLWithPath: response)
                        
                        // Get the parent directory if it's a .xcodeproj file
                        let actualProjectRoot = projectURL.pathExtension == "xcodeproj"
                            ? projectURL.deletingLastPathComponent()
                            : projectURL
                        
                        if actualProjectRoot != self.projectRoot {
                            print(" Project root detected: \(actualProjectRoot.lastPathComponent)")
                            self.projectRoot = actualProjectRoot
                        }
                    }
                }
            } else if let error = errorDict {
                print(" Project detection failed: \(error)")
            }
        }
    }
    
    func openFileInXcode(_ filePath: String) {
        let script = """
        tell application "Xcode"
            open "\(filePath)"
            activate
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(nil)
    }
    
    func createNewFile(at path: String, content: String) {
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            openFileInXcode(path)
        } catch {
            print(" Failed to create file: \(error)")
        }
    }
    
    func insertCodeAtCursor(_ code: String) {
        let script = """
        tell application "Xcode"
            tell application "System Events"
                keystroke "\(code)"
            end tell
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(nil)
    }
    
    func getSelectedText() -> String? {
        let script = """
        tell application "Xcode"
            tell application "System Events"
                keystroke "c" using command down
                delay 0.1
                return the clipboard
            end tell
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        if let result = appleScript?.executeAndReturnError(nil) {
            return result.stringValue
        }
        return nil
    }
    
    func buildProject() {
        let script = """
        tell application "Xcode"
            tell application "System Events"
                keystroke "b" using command down
            end tell
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(nil)
    }
    
    func runProject() {
        let script = """
        tell application "Xcode"
            tell application "System Events"
                keystroke "r" using command down
            end tell
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(nil)
    }
    
    func getProjectFiles() -> [URL] {
        guard let projectRoot = projectRoot else { return [] }
        
        var files: [URL] = []
        let fileManager = FileManager.default
        
        if let enumerator = fileManager.enumerator(at: projectRoot, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension == "swift" {
                    files.append(fileURL)
                }
            }
        }
        
        return files
    }
    
    private func updateRecentFiles(_ file: URL) {
        recentFiles.removeAll { $0 == file }
        recentFiles.insert(file, at: 0)
        if recentFiles.count > 10 {
            recentFiles = Array(recentFiles.prefix(10))
        }
    }
    
    func analyzeFile(_ url: URL) -> FileAnalysis? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64,
              size < 1_000_000 else { return nil }
        
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        
        let limitedContent = String(content.prefix(10000))
        
        return FileAnalysis(
            url: url,
            content: limitedContent,
            lineCount: limitedContent.components(separatedBy: .newlines).count,
            functionCount: limitedContent.matches(of: /func\s+\w+/).count,
            classCount: limitedContent.matches(of: /class\s+\w+/).count,
            structCount: limitedContent.matches(of: /struct\s+\w+/).count,
            issues: findCodeIssues(in: limitedContent)
        )
    }
    
    private func findCodeIssues(in content: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []
        let lines = content.components(separatedBy: .newlines)
        
        if lines.count > 200 {
            issues.append(CodeIssue(
                type: .longFunction,
                message: "File has \(lines.count) lines. Consider splitting into smaller files.",
                severity: .medium
            ))
        }
        
        let forceUnwrapCount = content.components(separatedBy: "!").count - 1
        if forceUnwrapCount > 10 {
            issues.append(CodeIssue(
                type: .excessiveForceUnwrapping,
                message: "Found \(forceUnwrapCount) force unwraps. Consider using safe unwrapping.",
                severity: .high
            ))
        }
        
        return issues
    }
    
    func triggerPermissionRequest() {
        triggerAppleScriptPermissionRequest()
    }
}

struct FileAnalysis {
    let url: URL
    let content: String
    let lineCount: Int
    let functionCount: Int
    let classCount: Int
    let structCount: Int
    let issues: [CodeIssue]
}

struct CodeIssue {
    let type: IssueType
    let message: String
    let severity: Severity
    
    enum IssueType {
        case longFunction
        case excessiveForceUnwrapping
        case missingDocumentation
        case complexLogic
    }
    
    enum Severity {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

extension CodeIssue.IssueType {
    var displayName: String {
        switch self {
        case .longFunction: return "Long Function"
        case .excessiveForceUnwrapping: return "Excessive Force Unwrapping"
        case .missingDocumentation: return "Missing Documentation"
        case .complexLogic: return "Complex Logic"
        }
    }
}

// MARK: - Supporting Types for File Indexing
struct IndexedFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let relativePath: String
    let content: String
    let fileSize: Int64
    let lastModified: Date
    let fileType: FileType
    let summary: FileSummary
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: IndexedFile, rhs: IndexedFile) -> Bool {
        lhs.id == rhs.id
    }
}

struct FileSummary {
    let lineCount: Int
    let nonEmptyLineCount: Int
    let functionCount: Int
    let classCount: Int
    let structCount: Int
    let enumCount: Int
    let protocolCount: Int
    let imports: [String]
    let typeNames: [String]
    
    var totalTypes: Int {
        classCount + structCount + enumCount + protocolCount
    }
}

enum FileType: String, CaseIterable {
    case swift = "swift"
    case objectiveC = "m"
    case objectiveCPlusPlus = "mm"
    case header = "h"
    case cppHeader = "hpp"
    case cpp = "cpp"
    case c = "c"
    case unknown = "unknown"
    
    init(from extension: String) {
        self = FileType(rawValue: `extension`.lowercased()) ?? .unknown
    }
    
    var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .objectiveC: return "Objective-C"
        case .objectiveCPlusPlus: return "Objective-C++"
        case .header: return "Header"
        case .cppHeader: return "C++ Header"
        case .cpp: return "C++"
        case .c: return "C"
        case .unknown: return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .swift: return "swift"
        case .objectiveC, .objectiveCPlusPlus: return "objectivec"
        case .header, .cppHeader: return "h.square"
        case .cpp, .c: return "c.square"
        case .unknown: return "doc"
        }
    }
    
    var color: Color {
        switch self {
        case .swift: return .orange
        case .objectiveC, .objectiveCPlusPlus: return .blue
        case .header, .cppHeader: return .purple
        case .cpp, .c: return .green
        case .unknown: return .gray
        }
    }
}
