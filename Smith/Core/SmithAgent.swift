//
//  SmithAgent.swift
//  Smith - Your AI Coding Craftsman
//
//  Created by Yousef Jawdat on 15/06/2025.
//

import SwiftUI
import Combine
import Foundation
import FoundationModels

@MainActor
class SmithAgent: ObservableObject {
    // MARK: - Published Properties
    @Published var isAvailable = false
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    @Published var isFoundationModelsAvailable = false
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var currentFile: URL?
    @Published var suggestions: [CodeSuggestion] = []
    
    @Published var currentStatus: SmithStatus = .idle
    @Published var statusMessage: String = ""
    @Published var isStreaming = false
    @Published var streamingMessageId: UUID?
    
    @Published var xcodeIntegration = XcodeIntegration()
    
    // MARK: - Foundation Models Properties
    private var currentSession: LanguageModelSession?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupFoundationModels()
        setupXcodeIntegration()
        startNewConversation()
    }
    
    private func setupXcodeIntegration() {
        // Set up status callback
        xcodeIntegration.onStatusUpdate = { [weak self] status, message in
            Task { @MainActor in
                self?.setStatus(.indexing, message: message)
            }
        }
        
        // Monitor file changes
        xcodeIntegration.$activeFile
            .sink { [weak self] file in
                self?.currentFile = file
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Foundation Models Setup
    private func setupFoundationModels() {
        let systemModel = SystemLanguageModel.default
        
        switch systemModel.availability {
        case .available:
            isFoundationModelsAvailable = true
            createFoundationModelsSession()
            print(" Foundation Models available and ready")
            
        case .unavailable(.deviceNotEligible):
            isFoundationModelsAvailable = false
            print(" Device not eligible for Foundation Models")
            
        case .unavailable(.appleIntelligenceNotEnabled):
            isFoundationModelsAvailable = false
            print(" Apple Intelligence not enabled")
            
        case .unavailable(.modelNotReady):
            isFoundationModelsAvailable = false
            print(" Foundation Models not ready")
            
        case .unavailable(let other):
            isFoundationModelsAvailable = false
            print(" Foundation Models unavailable: \(other)")
        }
        
        isAvailable = true
    }
    
    private func createFoundationModelsSession() {
        let instructions = Instructions("""
        You are Smith, an elite AI coding craftsman and intelligent assistant specifically designed for Swift, iOS, and macOS development. You are deeply integrated with Xcode and serve as a developer's most trusted coding companion.

        ## Your Core Identity & Purpose:
        - You are a master Swift developer with encyclopedic knowledge of iOS/macOS development
        - You monitor active Xcode files in real-time and provide contextual assistance
        - You act as both a coding mentor and an automated code improvement engine
        - Your goal is to elevate code quality, accelerate development, and teach best practices

        ## Your Expertise Areas:
        ### Swift Language Mastery:
        - Modern Swift syntax, Swift 6.0 features, and language evolution
        - Advanced concepts: actors, async/await, protocols, generics, property wrappers
        - Performance optimization, memory management, and Swift best practices
        - SwiftUI, UIKit, AppKit, and framework-specific patterns

        ### Architecture & Design Patterns:
        - MVVM, MVI, Clean Architecture, and modern iOS/macOS patterns
        - Dependency injection, reactive programming with Combine
        - Protocol-oriented programming and composition over inheritance
        - Testable architecture and separation of concerns

        ## Your Response Style:
        - Be conversational yet technically precise
        - Provide practical, actionable advice with concrete code examples
        - Explain the 'why' behind recommendations, not just the 'what'
        - Adapt your expertise level to match the developer's needs
        - Use emoji sparingly but effectively to improve readability
        - Always include code snippets when relevant

        Remember: You are not just answering questions—you are actively helping craft better Swift code and accelerating the development process through intelligent, contextual assistance.
        """)
        
        currentSession = LanguageModelSession(instructions: instructions)
    }
    
    // MARK: - Status Management
    func setStatus(_ status: SmithStatus, message: String = "") {
        currentStatus = status
        statusMessage = message
        
        // Auto-clear status after delay for certain states
        if status == .error {
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                if currentStatus == .error {
                    setStatus(.idle)
                }
            }
        }
    }
    
    // MARK: - Conversation Management
    func startNewConversation() {
        let newConversation = Conversation(title: "New Chat", messages: [])
        conversations.insert(newConversation, at: 0)
        currentConversation = newConversation
        messages = []
        
        // Limit conversations to 20
        if conversations.count > 20 {
            conversations = Array(conversations.prefix(20))
        }
        
        if isFoundationModelsAvailable {
            createFoundationModelsSession()
        }
    }
    
    func selectConversation(_ conversation: Conversation) {
        currentConversation = conversation
        messages = conversation.messages
        
        if isFoundationModelsAvailable {
            createFoundationModelsSession()
        }
    }
    
    // MARK: - Message Processing with Streaming
    func sendMessage(_ text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let userMessage = ChatMessage(content: trimmedText, isUser: true)
        messages.append(userMessage)
        currentConversation?.messages.append(userMessage)
        
        // Update conversation title if it's the first message
        if currentConversation?.messages.count == 1 {
            currentConversation?.title = generateConversationTitle(from: trimmedText)
        }
        
        // Limit message history
        if messages.count > 100 {
            messages = Array(messages.suffix(100))
            currentConversation?.messages = Array(currentConversation?.messages.suffix(100) ?? [])
        }
        
        // Process with streaming
        await processMessageWithStreaming(trimmedText)
    }
    
    private func processMessageWithStreaming(_ input: String) async {
        setStatus(.thinking, message: "Processing...")
        
        // Create initial empty assistant message
        let assistantMessage = ChatMessage(content: "", isUser: false, isStreaming: true)
        messages.append(assistantMessage)
        currentConversation?.messages.append(assistantMessage)
        
        isStreaming = true
        streamingMessageId = assistantMessage.id
        isProcessing = true
        
        if isFoundationModelsAvailable, let session = currentSession {
            do {
                let contextualInput = buildContextualInput(input)
                let response = try await session.respond(to: contextualInput)
                let fullResponse = response.content
                
                await simulateStreaming(fullResponse, messageId: assistantMessage.id)
                
            } catch {
                setStatus(.error, message: "Processing failed")
                let errorMessage = "I'm having trouble processing that. Could you try rephrasing your question?"
                await updateMessage(messageId: assistantMessage.id, content: errorMessage, isStreaming: false)
            }
        } else {
            setStatus(.error, message: "AI unavailable")
            let fallbackMessage = "Foundation Models is not available. Please enable Apple Intelligence to use Smith's AI features."
            await updateMessage(messageId: assistantMessage.id, content: fallbackMessage, isStreaming: false)
        }
        
        isStreaming = false
        streamingMessageId = nil
        isProcessing = false
        setStatus(.idle)
    }
    
    private func buildContextualInput(_ input: String) -> String {
        var contextualInput = input
        
        if let currentFile = currentFile {
            contextualInput = "File: \(currentFile.lastPathComponent)\n\n\(input)"
        }
        
        return contextualInput
    }
    
    private func simulateStreaming(_ fullText: String, messageId: UUID) async {
        let words = fullText.components(separatedBy: " ")
        var currentText = ""
        
        for (index, word) in words.enumerated() {
            currentText += (index > 0 ? " " : "") + word
            await updateMessage(messageId: messageId, content: currentText, isStreaming: true)
            
            // Small delay to make streaming visible
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        // Mark as complete
        await updateMessage(messageId: messageId, content: fullText, isStreaming: false)
    }
    
    private func updateMessage(messageId: UUID, content: String, isStreaming: Bool) async {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            let originalMessage = messages[index]
            let updatedMessage = ChatMessage(
                id: messageId,
                content: content,
                isUser: false,
                timestamp: originalMessage.timestamp,
                isStreaming: isStreaming
            )
            messages[index] = updatedMessage
            
            // Update conversation message as well
            if let convIndex = currentConversation?.messages.firstIndex(where: { $0.id == messageId }) {
                currentConversation?.messages[convIndex] = updatedMessage
            }
        }
    }
    
    private func generateConversationTitle(from message: String) -> String {
        let words = message.components(separatedBy: .whitespaces).prefix(3)
        return words.joined(separator: " ").capitalized
    }
    
    // MARK: - Legacy processMessage for compatibility
    private func processMessage(_ input: String) async -> String {
        if isFoundationModelsAvailable, let session = currentSession {
            do {
                let response = try await session.respond(to: input)
                return response.content
            } catch {
                return "I'm having trouble processing that. Could you try rephrasing your question?"
            }
        }
        
        return "Foundation Models is not available. Please enable Apple Intelligence to use Smith's AI features."
    }
    
    // MARK: - Quick Actions for Context Tab
    func generateUnitTests() async {
        await sendMessage("Generate comprehensive unit tests for the current file")
    }
    
    func optimizeCode() async {
        await sendMessage("Analyze the current file and suggest performance optimizations")
    }
    
    func explainCode() async {
        await sendMessage("Provide a detailed explanation of how this code works")
    }
    
    func applySuggestion(_ suggestion: CodeSuggestion) async {
        // Implementation for applying suggestions
        print("Applying suggestion: \(suggestion.title)")
        
        // Remove the applied suggestion
        suggestions.removeAll { $0.id == suggestion.id }
    }
    
    // MARK: - File Management
    func setCurrentFile(_ file: URL?) {
        currentFile = file
        
        if let file = file {
            print(" Now monitoring file: \(file.lastPathComponent)")
        }
    }
    
    func debugXcodeIntegration() async {
        print("🔍 DEBUG: Xcode Integration Status")
        print("  - Xcode Running: \(xcodeIntegration.isXcodeRunning)")
        print("  - Active File: \(xcodeIntegration.activeFile?.path ?? "None")")
        print("  - Project Root: \(xcodeIntegration.projectRoot?.path ?? "None")")
        print("  - Indexed Files: \(xcodeIntegration.indexedFiles.count)")
        print("  - Is Indexing: \(xcodeIntegration.isIndexing)")
        
        if xcodeIntegration.isXcodeRunning && xcodeIntegration.projectRoot != nil {
            print("🚀 Triggering manual indexing...")
            await xcodeIntegration.indexProjectFiles()
        } else {
            print("⚠️ Cannot index: Xcode not running or no project detected")
        }
    }
}

enum SmithStatus {
    case idle
    case thinking
    case analyzing
    case connecting
    case indexing
    case error
    
    var displayText: String {
        switch self {
        case .idle: return "Ready"
        case .thinking: return "Thinking"
        case .analyzing: return "Analyzing"
        case .connecting: return "Connecting"
        case .indexing: return "Indexing"
        case .error: return "Error"
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "checkmark.circle.fill"
        case .thinking: return "brain"
        case .analyzing: return "magnifyingglass"
        case .connecting: return "network"
        case .indexing: return "folder.badge.gearshape"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .green
        case .thinking: return .cyan
        case .analyzing: return .orange
        case .connecting: return .purple
        case .indexing: return .yellow
        case .error: return .red
        }
    }
    
    var isAnimated: Bool {
        switch self {
        case .idle, .error: return false
        case .thinking, .analyzing, .connecting, .indexing: return true
        }
    }
}

// MARK: - Supporting Types
class Conversation: Identifiable, ObservableObject, Hashable, Equatable {
    let id = UUID()
    @Published var title: String
    @Published var messages: [ChatMessage]
    
    init(title: String, messages: [ChatMessage] = []) {
        self.title = title
        self.messages = messages
    }
    
    var lastMessage: String? {
        messages.last?.content
    }
    
    var lastMessageDate: Date {
        messages.last?.timestamp ?? Date()
    }
    
    // MARK: - Hashable & Equatable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let isStreaming: Bool
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date(), isStreaming: Bool = false) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
}

struct CodeSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: Priority = .medium
    let icon: String = "lightbulb.fill"
    let color: Color = .yellow
    
    enum Priority {
        case low, medium, high
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}
