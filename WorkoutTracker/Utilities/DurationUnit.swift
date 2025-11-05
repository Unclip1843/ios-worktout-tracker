import Foundation

enum DurationUnit: String, CaseIterable, Identifiable {
    case minutes = "min"
    case hours = "hr"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .minutes: return "Minutes"
        case .hours: return "Hours"
        }
    }

    var displayLabel: String {
        switch self {
        case .minutes: return "min"
        case .hours: return "hr"
        }
    }

    func convert(seconds: Int) -> Double {
        switch self {
        case .minutes: return Double(seconds) / 60.0
        case .hours: return Double(seconds) / 3600.0
        }
    }

    func seconds(from value: Double) -> Double {
        switch self {
        case .minutes: return value * 60.0
        case .hours: return value * 3600.0
        }
    }

    func formatted(value: Double) -> String {
        let totalSeconds = Int(seconds(from: value))
        return formatDuration(totalSeconds)
    }
}
