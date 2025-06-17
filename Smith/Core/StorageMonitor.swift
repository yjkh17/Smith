//
//  StorageMonitor.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 16/06/2025.
//

import Foundation
import SwiftUI

@MainActor
class StorageMonitor: ObservableObject {
    @Published var totalSpace: Int64 = 0
    @Published var usedSpace: Int64 = 0
    @Published var availableSpace: Int64 = 0
    @Published var isMonitoring = false

    nonisolated(unsafe) private var timer: Timer?

    init() {
        updateStorageInfo()
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateStorageInfo()
            }
        }

        // Initial update
        updateStorageInfo()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func updateStorageInfo() {
        guard let info = StorageMonitor.getRootDiskInfo() else { return }
        totalSpace = info.total
        availableSpace = info.free
        usedSpace = info.total - info.free
    }

    nonisolated private static func getRootDiskInfo() -> (total: Int64, free: Int64)? {
        // Use the Data volume to avoid APFS container virtualization
        let path = "/System/Volumes/Data"
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: path)
            if let size = attrs[.systemSize] as? NSNumber,
               let free = attrs[.systemFreeSize] as? NSNumber {
                return (size.int64Value, free.int64Value)
            }
        } catch {
            print("StorageMonitor error: \(error)")
        }
        return nil
    }
}

