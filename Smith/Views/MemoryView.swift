import SwiftUI

struct MemoryView: View {
    @StateObject private var memoryMonitor = MemoryMonitor()
    @EnvironmentObject private var smithAgent: SmithAgent

    private var usagePercentage: Double {
        guard memoryMonitor.totalMemory > 0 else { return 0 }
        let pct = Double(memoryMonitor.usedMemory) / Double(memoryMonitor.totalMemory) * 100
        return pct
    }

    private var usageColor: Color {
        switch usagePercentage {
        case ..<60: return .green
        case ..<80: return .yellow
        case ..<90: return .orange
        default: return .red
        }
    }

    private func byteString(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .binary)
    }

    var body: some View {
        VStack(spacing: 4) {
            VStack(spacing: 6) {
                HStack {
                    Text("Memory Monitor")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(memoryMonitor.isMonitoring ? "Stop" : "Start") {
                        if memoryMonitor.isMonitoring {
                            memoryMonitor.stopMonitoring()
                        } else {
                            memoryMonitor.startMonitoring()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }

                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(.gray.opacity(0.3), lineWidth: 3)
                            .frame(width: 40, height: 40)

                        Circle()
                            .trim(from: 0, to: min(usagePercentage / 100, 1))
                            .stroke(usageColor, lineWidth: 3)
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: usagePercentage)

                        Text("\(Int(usagePercentage))%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Used: \(byteString(memoryMonitor.usedMemory))")
                            .font(.caption2)
                            .foregroundColor(.primary)
                        Text("Free: \(byteString(memoryMonitor.freeMemory))")
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
            }
            .padding(Spacing.small)
            .background(.gray.opacity(0.1))

            ScrollView(showsIndicators: false) {
                if !memoryMonitor.topMemoryProcesses.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Top Processes")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Ask") { askAboutProcesses() }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                        }
                        ForEach(memoryMonitor.topMemoryProcesses.prefix(5)) { process in
                            MemoryProcessRowView(process: process)
                        }
                    }
                    .padding(.horizontal, Spacing.small)
                }
            }
            .frame(maxHeight: 80)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(maxHeight: 200)
        .onAppear { memoryMonitor.startMonitoring() }
        .onDisappear { memoryMonitor.stopMonitoring() }
    }

    private func askAboutProcesses() {
        let processes = memoryMonitor.topMemoryProcesses.prefix(5).map { "\($0.displayName): \(Int($0.memoryMB)) MB" }.joined(separator: "\n")
        Task {
            await smithAgent.sendMessage("Which apps are consuming the most memory?\n\n\(processes)")
        }
    }
}

struct MemoryProcessRowView: View {
    let process: MemoryProcessInfo

    var body: some View {
        HStack {
            Text(process.displayName)
                .foregroundColor(.primary)
            Spacer()
            Text("\(Int(process.memoryMB)) MB")
                .foregroundColor(process.statusColor)
        }
        .font(.caption2)
    }
}

#Preview {
    MemoryView()
        .environmentObject(SmithAgent())
}
