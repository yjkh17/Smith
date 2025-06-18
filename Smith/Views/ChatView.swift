//
//  ChatView.swift
//  Smith - Your AI Coding Craftsman
//
//  Created by Yousef Jawdat on 14/06/2025.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var smithAgent: SmithAgent
    @State private var messageText = ""
    @State private var isTyping = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern Chat Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chat with Smith")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primary)
                    
                    Text("Your AI coding assistant")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Connection Status with Modern Indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(.green.gradient)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(.green, lineWidth: BorderWidth.thin)
                                .scaleEffect(1.5)
                                .opacity(0.3)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: smithAgent.isProcessing)
                        )
                    
                    Text("Connected")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(.green.opacity(0.1), in: Capsule())
                .overlay(Capsule().stroke(.green.opacity(0.3), lineWidth: BorderWidth.thin))
            }
            .padding()
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: CornerRadius.massive)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.massive)
                    .stroke(.quaternary, lineWidth: BorderWidth.thin)
            )
            .padding()
            
            // Messages List with Modern Styling
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(smithAgent.messages) { message in
                            ModernMessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if smithAgent.isProcessing {
                            ModernTypingIndicator()
                        }
                    }
                    .padding()
                }
                .onChange(of: smithAgent.messages.count) {
                    if let lastMessage = smithAgent.messages.last {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Modern Message Input
            VStack(spacing: 12) {
                if let focusedFile = smithAgent.focusedFile {
                    CompactFocusedFileCard(file: focusedFile) {
                        smithAgent.setFocusedFile(nil)
                    }
                }
                
                HStack(spacing: 12) {
                    TextField("Message Smith...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            .thinMaterial,
                            in: RoundedRectangle(cornerRadius: CornerRadius.xxlarge)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.xxlarge)
                                .stroke(.cyan.opacity(0.3), lineWidth: BorderWidth.thin)
                        )
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: smithAgent.isProcessing ? "stop.circle.fill" : "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(smithAgent.isProcessing ? .red : .cyan)
                    }
                    .buttonStyle(.plain)
                    .padding()
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                smithAgent.isProcessing ? .red.opacity(0.5) : .cyan.opacity(0.5),
                                lineWidth: BorderWidth.thin
                            )
                    )
                    .disabled(messageText.isEmpty && !smithAgent.isProcessing)
                    .animation(.easeInOut(duration: 0.2), value: smithAgent.isProcessing)
                }
            }
            .padding()
            .background(.black.opacity(0.1))
        }
        .background(.black)
        .dynamicTypeSize(.medium ... .accessibility3)
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else {
            // Stop processing if button is pressed while processing
            return
        }
        
        let message = messageText
        messageText = ""
        
        Task {
            await smithAgent.sendMessage(message)
        }
    }
}

struct ModernMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if !message.isUser {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.cyan)
                            .font(.caption)
                    }
                    
                    Text(message.isUser ? "You" : "Smith")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(message.isUser ? .blue : .cyan)
                    
                    if message.isUser {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                if message.isUser {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(Color.primary)
                        .padding()
                        .background(
                            .blue.opacity(0.2),
                            in: RoundedRectangle(cornerRadius: CornerRadius.massive)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.massive)
                                .stroke(.blue.opacity(0.3), lineWidth: BorderWidth.thin)
                        )
                } else {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(Color.primary)
                        .padding()
                }
            }
            .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: message.id)
    }
}

struct ModernTypingIndicator: View {
    @State private var dotScale1: CGFloat = 1.0
    @State private var dotScale2: CGFloat = 1.0
    @State private var dotScale3: CGFloat = 1.0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.cyan)
                        .font(.caption)
                    
                    Text("Smith")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.cyan)
                }
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(.cyan)
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == 0 ? dotScale1 : (index == 1 ? dotScale2 : dotScale3))
                    }
                }
                .padding()
                .background(
                    .cyan.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: CornerRadius.massive)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.massive)
                        .stroke(.cyan.opacity(0.3), lineWidth: BorderWidth.thin)
                )
            }
            .frame(maxWidth: 300, alignment: .leading)
            
            Spacer()
        }
        .onAppear {
            startTypingAnimation()
        }
    }
    
    private func startTypingAnimation() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
            dotScale1 = 1.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                dotScale2 = 1.5
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                dotScale3 = 1.5
            }
        }
    }
}

struct FocusedFileCard: View {
    let file: FileItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: file.icon)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Focused File")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(file.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.small)
        .background(
            .orange.opacity(0.1),
            in: RoundedRectangle(cornerRadius: CornerRadius.large)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(.orange.opacity(0.3), lineWidth: BorderWidth.thin)
        )
    }
}

// MARK: - Optimized Chat Components
struct OptimizedMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                // Compact Message Header
                HStack(spacing: 6) {
                    if !message.isUser {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.cyan)
                            .font(.caption2)
                    }
                    
                    Text(message.isUser ? "You" : "Smith")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(message.isUser ? .blue : .cyan)
                    
                    if message.isUser {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption2)
                    }
                }
                
                // Message Content
                Text(message.content)
                    .font(Font.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(
                        message.isUser ? .blue.opacity(0.2) : .cyan.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: CornerRadius.huge)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.huge)
                            .stroke(
                                message.isUser ? .blue.opacity(0.3) : .cyan.opacity(0.3),
                                lineWidth: BorderWidth.hairline
                            )
                    )
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer(minLength: 40)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: message.id)
    }
}

struct CompactTypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.cyan)
                        .font(.caption2)
                    
                    Text("Smith")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.cyan)
                }
                
                HStack(spacing: 3) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(.cyan)
                            .frame(width: 6, height: 6)
                            .scaleEffect(animationPhase == index ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 0.4).repeatForever(), value: animationPhase)
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(
                    .cyan.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: CornerRadius.huge)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.huge)
                        .stroke(.cyan.opacity(0.3), lineWidth: BorderWidth.hairline)
                )
            }
            .frame(maxWidth: 280, alignment: .leading)
            
            Spacer(minLength: 40)
        }
        .onAppear {
            startTypingAnimation()
        }
    }
    
    private func startTypingAnimation() {
        Task { @MainActor in
            while true {
                for i in 0..<3 {
                    animationPhase = i
                    try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
                }
            }
        }
    }
}

struct CompactFocusedFileCard: View {
    let file: FileItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Focused File")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text(file.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.small)
        .background(
            .orange.opacity(0.1),
            in: RoundedRectangle(cornerRadius: CornerRadius.large)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(.orange.opacity(0.3), lineWidth: BorderWidth.hairline)
        )
    }
}

#Preview {
    ChatView()
        .environmentObject(SmithAgent())
        .background(.black)
}
