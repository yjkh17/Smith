//
//  FileTreeSheet.swift
//  Smith - Your AI Coding Craftsman
//
//  Created by Yousef Jawdat on 15/06/2025.
//

import SwiftUI

struct FileTreeSheet: View {
    @EnvironmentObject private var smithAgent: SmithAgent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Project Files")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.black)
            
            Divider()
                .overlay(.gray.opacity(0.5))
            
            // Use the new IndexedFilesView
            IndexedFilesView()
                .environmentObject(smithAgent)
                .background(.black)
        }
        .background(.black)
    }
}

#Preview {
    FileTreeSheet()
        .environmentObject(SmithAgent())
}
