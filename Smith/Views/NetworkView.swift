import SwiftUI

struct NetworkView: View {
    @StateObject private var networkMonitor = NetworkMonitor()
    @ObservedObject private var permissions = PermissionsManager.shared

    private func speedString(_ value: Double) -> String {
        String(format: "%.1f Mbps", value)
    }

    var body: some View {
        VStack(spacing: 4) {
            VStack(spacing: 6) {
                HStack {
                    Text("Network Monitor")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primary)
                    Spacer()
                    Button(networkMonitor.isMonitoring ? "Stop" : "Start") {
                        if networkMonitor.isMonitoring {
                            networkMonitor.stopMonitoring()
                        } else {
                            networkMonitor.startMonitoring()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(networkMonitor.networkQuality.color)
                        .frame(width: 8, height: 8)

                    Text(networkMonitor.connectionType.rawValue)
                        .font(.caption2)
                        .foregroundColor(Color.primary)
                    if !networkMonitor.networkName.isEmpty {
                        Text("(\(networkMonitor.networkName))")
                            .font(.caption2)
                            .foregroundColor(Color.primary)
                    } else if !permissions.locationAuthorized {
                        Button("Allow Location") {
                            permissions.requestLocationAccess()
                        }
                        .font(.caption2)
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                    Spacer()

                    Text(speedString(networkMonitor.downloadSpeed))
                        .font(.caption2)
                        .foregroundColor(Color.primary)
                }
            }
            .padding(Spacing.small)
            .background(Color.panelBackground)

            Spacer()
        }
        .background(.black)
        .frame(maxHeight: 120)
        .onAppear { networkMonitor.startMonitoring() }
        .onDisappear { networkMonitor.stopMonitoring() }
    }
}

#Preview {
    NetworkView()
}
