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
    
    // MARK: - Intelligence Engine
    @Published var intelligenceEngine = IntelligenceEngine()

    private var currentTask: Task<Void, Never>?
    
    
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
        guard let url = Bundle.main.url(forResource: "AgentInstructions", withExtension: "txt") else {
            print("❌ AgentInstructions.txt not found in bundle")
            return
        }

        let instructionsText: String
        do {
            instructionsText = try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("❌ Failed to load AgentInstructions.txt: \(error)")
            return
        }

        let instructions = Instructions(instructionsText)
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
    func sendMessage(_ text: String) {
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
        currentTask = Task {
            await self.processMessageWithStreaming(trimmedText)
        }
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
        let category = QuestionAnalyzer.categorize(input)
        var contextualInput = ""

        if category != .general {
            contextualInput += "QUESTION CATEGORY: \(category.rawValue)\n\n"
        }

        // Skip system context for identity questions
        if category == .identity {
            contextualInput += """
            USER QUESTION: \(input)

            The user is asking about your identity. Introduce yourself briefly and highlight your capabilities without discussing current system status.
            """
            return contextualInput
        }

        // Add real-time system intelligence context
        let systemContext = buildSystemIntelligenceContext()
        
        // Add focused file context if available
        if let focusedFile = focusedFile {
            contextualInput += """
            REAL-TIME SYSTEM CONTEXT:
            \(systemContext)
            
            FOCUSED FILE CONTEXT:
            File Name: \(focusedFile.name)
            File Path: \(focusedFile.url.path)
            File Type: \(focusedFile.isDirectory ? "Directory/Folder" : "File")
            File Size: \(focusedFile.isDirectory ? "N/A" : formatFileSize(focusedFile.size))
            Extension: \(focusedFile.url.pathExtension.isEmpty ? "None" : focusedFile.url.pathExtension)
            
            USER QUESTION: \(input)
            
            Please analyze this file/folder with the current system context and answer the user's question with specific insights.
            """
        } else {
            // Add system context based on intelligence engine insights
            contextualInput += """
            REAL-TIME SYSTEM CONTEXT:
            \(systemContext)
            
            USER QUESTION: \(input)
            
            Please provide an intelligent response based on the current system state and context above.
            """
        }
        
        return contextualInput
    }
    
    private func buildSystemIntelligenceContext() -> String {
        var context = ""
        
        // Current workload
        if intelligenceEngine.currentWorkload != .unknown {
            context += "Current Workload: \(intelligenceEngine.currentWorkload.displayName)\n"
        }
        
        // Performance score
        context += "System Performance Score: \(Int(intelligenceEngine.performanceScore))/100\n"
        
        // Active insights
        if !intelligenceEngine.currentInsights.isEmpty {
            context += "Current Insights:\n"
            for insight in intelligenceEngine.currentInsights.prefix(3) {
                context += "- \(insight.title): \(insight.description)\n"
            }
        }
        
        // Active anomalies
        if !intelligenceEngine.activeAnomalies.isEmpty {
            context += "Active Issues:\n"
            for anomaly in intelligenceEngine.activeAnomalies.prefix(2) {
                context += "- \(anomaly.title): \(anomaly.description)\n"
            }
        }
        
        // Optimization suggestions
        if !intelligenceEngine.optimizationSuggestions.isEmpty {
            context += "Available Optimizations:\n"
            for suggestion in intelligenceEngine.optimizationSuggestions.prefix(2) {
                context += "- \(suggestion.title): \(suggestion.description)\n"
            }
        }
        
        return context
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
            if Task.isCancelled {
                await updateMessage(messageId: messageId, content: currentText, isStreaming: false)
                return
            }
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

    func cancelCurrentTask() {
        currentTask?.cancel()
        isStreaming = false
        streamingMessageId = nil
        isProcessing = false
        setStatus(.idle)
    }
    
    private func generateConversationTitle(from message: String) -> String {
        let words = message.components(separatedBy: .whitespaces).prefix(3)
        return words.joined(separator: " ").capitalized
    }
    
    // MARK: - Quick Analysis Actions
    func analyzeSystemHealth() {
        let intelligenceContext = buildSystemIntelligenceContext()
        let healthReport = """
        System Health Analysis Request:
        
        Current System Intelligence:
        \(intelligenceContext)
        
        Please provide a comprehensive analysis of my Mac's current health including:
        - Overall system performance assessment based on current workload
        - Real-time optimization recommendations
        - Analysis of current issues and anomalies
        - Intelligent maintenance suggestions
        """
        
        sendMessage(healthReport)
    }

    func optimizePerformance() {
        let intelligenceContext = buildSystemIntelligenceContext()
        let optimizationRequest = """
        Performance Optimization Request:
        
        Current System Intelligence:
        \(intelligenceContext)
        
        Please provide specific recommendations to improve my Mac's performance including:
        - Workload-specific optimization strategies
        - Real-time system improvements
        - Context-aware resource management
        - Intelligent performance tuning
        """
        
        sendMessage(optimizationRequest)
    }
    
    func setFocusedFile(_ file: FileItem?) {
        focusedFile = file
    }
    
    // MARK: - Intelligence Engine Integration
    func setSystemMonitors(cpu: CPUMonitor, battery: BatteryMonitor, memory: MemoryMonitor, network: NetworkMonitor, storage: StorageMonitor) {
        intelligenceEngine.setMonitors(cpu: cpu, battery: battery, memory: memory, network: network, storage: storage)
    }
    
    func getCurrentSystemInsights() -> [SystemInsight] {
        return intelligenceEngine.currentInsights
    }
    
    func getCurrentOptimizations() -> [OptimizationSuggestion] {
        return intelligenceEngine.optimizationSuggestions
    }
    
    func getCurrentAnomalies() -> [SystemAnomaly] {
        return intelligenceEngine.activeAnomalies
    }
    
    func getPerformanceScore() -> Double {
        return intelligenceEngine.performanceScore
    }
    
    func getCurrentWorkload() -> WorkloadType {
        return intelligenceEngine.currentWorkload
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
