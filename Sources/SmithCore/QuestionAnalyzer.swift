import Foundation
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

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
    private static let keywords: [QuestionCategory: [String]] = [
        .cpu: ["cpu", "processor", "core", "cores", "performance"],
        .memory: ["memory", "ram", "swap", "memory usage"],
        .storage: ["storage", "disk", "ssd", "hard drive", "hard disk", "hard drive space", "disk space"],
        .battery: ["battery", "power", "charge", "charging"],
        .network: ["network", "wifi", "internet", "connection"],
        .fileSystem: ["file", "files", "folder", "directory", "finder"],
        .identity: ["who are you", "what are you", "your name", "what is smith", "introduce yourself"]
    ]

    static func categorize(_ text: String) -> QuestionCategory {
#if canImport(NaturalLanguage)
        if #available(macOS 10.15, iOS 13, *) {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(text)
            if recognizer.dominantLanguage != .english {
                return .general
            }
        }
#endif
        let lower = text.lowercased()

        for (category, phrases) in keywords {
            for phrase in phrases {
                if lower.contains(phrase) {
                    return category
                }
            }
        }

        let words = lower.split { !$0.isLetter }.map(String.init)
        for word in words {
            for (category, phrases) in keywords {
                if phrases.contains(word) {
                    return category
                }
            }
        }

        return .general
    }
}
