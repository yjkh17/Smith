//
//  SharedTypes.swift
//  Smith - Your AI System Assistant
//
//  Created by Yousef Jawdat on 17/06/2025.
//

import Foundation
import SwiftUI

// MARK: - ProcessInfo Extension for CPUMonitor
extension ProcessInfo {
    var displayName: String {
        if name.isEmpty {
            return "Unknown Process"
        }
        
        switch name.lowercased() {
        case "windowserver":
            return "Window Server"
        case "kernel_task":
            return "Kernel Task"
        case "mds", "mds_stores":
            return "Spotlight"
        case "coreaudiod":
            return "Core Audio"
        case "backupd":
            return "Time Machine"
        case "hidd":
            return "HID Server"
        case "loginwindow":
            return "Login Window"
        default:
            return name
        }
    }
    
    var statusColor: Color {
        switch cpuUsage {
        case 0..<2:
            return .green
        case 2..<8:
            return .yellow
        case 8..<20:
            return .orange
        default:
            return .red
        }
    }
    
    var priorityLevel: String {
        switch cpuUsage {
        case 0..<2:
            return "Normal"
        case 2..<8:
            return "Elevated"
        case 8..<20:
            return "High"
        default:
            return "Critical"
        }
    }
}
