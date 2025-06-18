import Foundation

enum QuestionCategory: String {
    case cpu = "CPU"
    case memory = "Memory"
    case storage = "Storage"
    case battery = "Battery"
    case network = "Network"
    case fileSystem = "File System"
    case identity = "Agent Identity"
    case general = "General"
}

struct QuestionAnalyzer {
    static func categorize(_ text: String) -> QuestionCategory {
        let lower = text.lowercased()

        if lower.contains("cpu") || lower.contains("processor") {
            return .cpu
        }
        if lower.contains("memory") || lower.contains("ram") {
            return .memory
        }
        if lower.contains("storage") || lower.contains("disk") || lower.contains("ssd") {
            return .storage
        }
        if lower.contains("battery") || lower.contains("power") {
            return .battery
        }
        if lower.contains("network") || lower.contains("wifi") || lower.contains("internet") {
            return .network
        }
        if lower.contains("file") || lower.contains("folder") || lower.contains("directory") {
            return .fileSystem
        }

        if lower.contains("who are you") ||
            lower.contains("what are you") ||
            lower.contains("your name") ||
            lower.contains("what is smith") ||
            lower.contains("introduce yourself") {
            return .identity
        }

        return .general
    }
}
