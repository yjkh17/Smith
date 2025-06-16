//
//  ChatTabView.swift
//  Smith - Your AI Coding Craftsman
//
//  Created by Yousef Jawdat on 14/06/2025.
//

import SwiftUI

struct ChatTabView: View {
    @EnvironmentObject private var smithAgent: SmithAgent
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    let conversation: Conversation?
    
    init(conversation: Conversation? = nil) {
        self.conversation = conversation
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(conversation?.messages ?? smithAgent.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if smithAgent.isProcessing {
                            TypingIndicator()
                        }
                    }
                    .padding()
                }
                .onChange(of: conversation?.messages.count ?? smithAgent.messages.count) { _, _ in
                    let messages = conversation?.messages ?? smithAgent.messages
                    if let lastMessage = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
                .overlay(.gray.opacity(0.5))
            
            HStack(spacing: 8) {
                TextField("Ask Smith anything...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...3)
                    .focused($isInputFocused)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onSubmit {
                        sendMessage()
                    }
                
                Button("Send") {
                    sendMessage()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(minWidth: 60, minHeight: 36)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || smithAgent.isProcessing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.gray.opacity(0.05))
        }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = inputText
        inputText = ""
        
        Task {
            await smithAgent.sendMessage(message)
        }
    }
}

struct MessageBubble: View {
    @EnvironmentObject private var smithAgent: SmithAgent
    let message: ChatMessage
    
    private var isCurrentResponse: Bool {
        !message.isUser && smithAgent.streamingMessageId == message.id
    }
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                MessageContentView(content: message.content, isUser: message.isUser)
                
                HStack {
                    if !message.isUser && isCurrentResponse && (message.isStreaming || smithAgent.currentStatus != .idle) {
                        StatusIndicatorBubble()
                    }
                    
                    Spacer()
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
            }
            
            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
    }
}

struct MessageContentView: View {
    let content: String
    let isUser: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let parts = parseMessageContent(content)
            
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                switch part {
                case .text(let text):
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(.init(text))
                            .textSelection(.enabled)
                            .padding(.horizontal, isUser ? 12 : 0)
                            .padding(.vertical, isUser ? 8 : 0)
                            .background(
                                Group {
                                    if isUser {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.blue)
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                            .foregroundColor(.white)
                    }
                    
                case .code(let code, let language):
                    CodeBlockView(code: code, language: language)
                }
            }
        }
    }
}

struct CodeBlockView: View {
    let code: String
    let language: String?
    
    @State private var showingCopyConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(language?.uppercased() ?? "CODE")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Spacer()
                
                Button {
                    copyToClipboard()
                } label: {
                    Image(systemName: showingCopyConfirmation ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.black)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.gray.opacity(0.1))
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white)
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(.black.opacity(0.3))
        }
        .background(.gray.opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        
        showingCopyConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingCopyConfirmation = false
        }
    }
}

enum MessagePart {
    case text(String)
    case code(String, language: String?)
}

func parseMessageContent(_ content: String) -> [MessagePart] {
    var parts: [MessagePart] = []
    let lines = content.components(separatedBy: .newlines)
    var currentText = ""
    var inCodeBlock = false
    var currentCode = ""
    var currentLanguage: String?
    
    for line in lines {
        if line.hasPrefix("```") {
            if inCodeBlock {
                if !currentCode.isEmpty {
                    parts.append(.code(currentCode.trimmingCharacters(in: .newlines), language: currentLanguage))
                }
                currentCode = ""
                currentLanguage = nil
                inCodeBlock = false
            } else {
                if !currentText.isEmpty {
                    parts.append(.text(currentText))
                    currentText = ""
                }
                let language = String(line.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentLanguage = language.isEmpty ? nil : language
                inCodeBlock = true
            }
        } else if inCodeBlock {
            currentCode += line + "\n"
        } else {
            currentText += line + "\n"
        }
    }
    
    if !currentText.isEmpty {
        parts.append(.text(currentText))
    }
    
    if !currentCode.isEmpty {
        parts.append(.code(currentCode.trimmingCharacters(in: .newlines), language: currentLanguage))
    }
    
    return parts
}

struct StatusIndicatorBubble: View {
    @EnvironmentObject private var smithAgent: SmithAgent
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: smithAgent.currentStatus.icon)
                .foregroundColor(smithAgent.currentStatus.color)
                .font(.caption2)
            
            Text(smithAgent.currentStatus.displayText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            if !smithAgent.statusMessage.isEmpty {
                Text(smithAgent.statusMessage)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.gray.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        .opacity(smithAgent.currentStatus.isAnimated ? 1 : 0.7)
        .animation(.easeInOut(duration: 0.3), value: smithAgent.currentStatus)
    }
}

struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.cyan)
                        .frame(width: 6, height: 6)
                        .opacity(animating ? 1 : 0.3)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.gray.opacity(0.2))
            )
            
            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    ChatTabView()
        .environmentObject(SmithAgent())
        .background(.black)
}
