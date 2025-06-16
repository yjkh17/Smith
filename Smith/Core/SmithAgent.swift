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
    
    @Published var currentStatus: SmithStatus = .idle
    @Published var statusMessage: String = ""
    @Published var isStreaming = false
    @Published var streamingMessageId: UUID?
    
    @Published var focusedFile: FileItem?
    
    
    // MARK: - Foundation Models Properties
    private var currentSession: LanguageModelSession?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupFoundationModels()
        startNewConversation()
    }
    
    // MARK: - Foundation Models Setup
    private func setupFoundationModels() {
        let systemModel = SystemLanguageModel.default
        
        switch systemModel.availability {
        case .available:
            isFoundationModelsAvailable = true
            createFoundationModelsSession()
            print("✅ Foundation Models available and ready")
            
        case .unavailable(.deviceNotEligible):
            isFoundationModelsAvailable = false
            print("❌ Device not eligible for Foundation Models")
            
        case .unavailable(.appleIntelligenceNotEnabled):
            isFoundationModelsAvailable = false
            print("❌ Apple Intelligence not enabled")
            
        case .unavailable(.modelNotReady):
            isFoundationModelsAvailable = false
            print("❌ Foundation Models not ready")
            
        case .unavailable(let other):
            isFoundationModelsAvailable = false
            print("❌ Foundation Models unavailable: \(other)")
        }
        
        isAvailable = true
    }
    
    private func createFoundationModelsSession() {
        let instructions = Instructions("""
        You are Smith, an elite AI system assistant and intelligent companion specifically designed for macOS system analysis, file management, and performance optimization.

        ## Your Core Identity & Purpose:
        - You are an expert macOS system analyst with deep knowledge of file systems, CPU management, and battery optimization
        - You help users understand their Mac's performance, analyze files and folders, and provide actionable recommendations
        - You act as both a technical advisor and a friendly assistant for system-related questions
        - Your goal is to help users optimize their Mac's performance, manage their files effectively, and maintain system health

        ## Your Expertise Areas:
        ### File System Analysis:
        - Analyze files and folders to determine their purpose and necessity
        - Identify safe-to-delete files, system files, and important user data
        - Provide insights on file organization, storage optimization, and cleanup strategies
        - Understand macOS directory structure and common file types

        ### CPU Performance Analysis:
        - Analyze CPU usage patterns and identify performance bottlenecks
        - Explain why certain processes consume high CPU and provide optimization recommendations
        - Help users understand normal vs. abnormal CPU behavior
        - Suggest ways to improve system performance and reduce CPU load

        ### Battery Health & Power Management:
        - Analyze battery health, charging patterns, and power consumption
        - Identify apps and processes that drain battery quickly
        - Provide power optimization strategies and battery longevity tips
        - Help users understand battery states and charging best practices

        ### System Optimization:
        - Provide comprehensive system health assessments
        - Recommend maintenance tasks and optimization strategies
        - Help troubleshoot performance issues and system slowdowns
        - Suggest hardware upgrade paths when necessary

        ## Your Response Style:
        - Be conversational yet technically precise
        - Provide practical, actionable advice with specific steps when possible
        - Explain technical concepts in accessible language
        - Use appropriate emojis to make responses more engaging and readable
        - Always prioritize user safety - warn about risky operations
        - Provide context for your recommendations (explain the "why")

        ## Safety Guidelines:
        - Always warn users before suggesting deletion of system files
        - Emphasize the importance of backups before major system changes
        - Distinguish between safe cleanup operations and potentially risky ones
        - Recommend testing changes in non-critical environments when applicable

        Remember: You are not just answering questions—you are actively helping users maintain and optimize their Mac systems through intelligent analysis and personalized recommendations.
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
        
        // Add focused file context if available
        if let focusedFile = focusedFile {
            contextualInput = """
            FOCUSED FILE CONTEXT:
            File Name: \(focusedFile.name)
            File Path: \(focusedFile.url.path)
            File Type: \(focusedFile.isDirectory ? "Directory/Folder" : "File")
            File Size: \(focusedFile.isDirectory ? "N/A" : formatFileSize(focusedFile.size))
            Extension: \(focusedFile.url.pathExtension.isEmpty ? "None" : focusedFile.url.pathExtension)
            
            USER QUESTION: \(input)
            
            Please analyze this file/folder and answer the user's question with specific context about the focused item.
            """
        } else {
            // Add system context based on the type of query
            if input.lowercased().contains("file") || input.lowercased().contains("folder") {
                contextualInput = "File System Query: \(input)"
            } else if input.lowercased().contains("cpu") || input.lowercased().contains("process") {
                contextualInput = "CPU Analysis Query: \(input)"
            } else if input.lowercased().contains("battery") || input.lowercased().contains("power") {
                contextualInput = "Battery Analysis Query: \(input)"
            }
        }
        
        return contextualInput
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
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
    
    // MARK: - Quick Analysis Actions
    func analyzeSystemHealth() async {
        let healthReport = """
        System Health Analysis Request:
        
        Please provide a comprehensive analysis of my Mac's current health including:
        - Overall system performance assessment
        - Recommendations for optimization
        - Potential issues to monitor
        - Maintenance suggestions
        """
        
        await sendMessage(healthReport)
    }
    
    func optimizePerformance() async {
        let optimizationRequest = """
        Performance Optimization Request:
        
        Please provide specific recommendations to improve my Mac's performance including:
        - CPU optimization strategies
        - Memory management tips
        - Storage cleanup suggestions
        - Battery life improvements
        """
        
        await sendMessage(optimizationRequest)
    }
    
    func setFocusedFile(_ file: FileItem?) {
        focusedFile = file
    }
}

enum SmithStatus {
    case idle
    case thinking
    case analyzing
    case connecting
    case error
    
    var displayText: String {
        switch self {
        case .idle: return "Ready"
        case .thinking: return "Thinking"
        case .analyzing: return "Analyzing"
        case .connecting: return "Connecting"
        case .error: return "Error"
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "checkmark.circle.fill"
        case .thinking: return "brain"
        case .analyzing: return "magnifyingglass"
        case .connecting: return "network"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .green
        case .thinking: return .cyan
        case .analyzing: return .orange
        case .connecting: return .purple
        case .error: return .red
        }
    }
    
    var isAnimated: Bool {
        switch self {
        case .idle, .error: return false
        case .thinking, .analyzing, .connecting: return true
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
