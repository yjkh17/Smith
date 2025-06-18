import Foundation

enum BackgroundIntensity: String, CaseIterable, Codable, Sendable {
    case minimal = "minimal"
    case medium = "medium"
    case balanced = "balanced"
    case comprehensive = "comprehensive"

    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .medium: return "Medium"
        case .balanced: return "Balanced"
        case .comprehensive: return "Comprehensive"
        }
    }

    var updateInterval: TimeInterval {
        switch self {
        case .minimal: return 300 // 5 minutes
        case .medium: return 120  // 2 minutes
        case .balanced: return 60  // 1 minute
        case .comprehensive: return 15 // 15 seconds
        }
    }

    var description: String {
        switch self {
        case .minimal: return "Basic monitoring every 5 minutes"
        case .medium: return "Moderate monitoring every 2 minutes"
        case .balanced: return "Regular monitoring every minute"
        case .comprehensive: return "Detailed monitoring every 15 seconds"
        }
    }
}
