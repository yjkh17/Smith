//
//  ContentView.swift
//  Smith - Your AI Coding Craftsman  
//
//  Created by Yousef Jawdat on 14/06/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var smithAgent = SmithAgent()
    
    var body: some View {
        ChatView()
            .environmentObject(smithAgent)
            .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    ContentView()
}
