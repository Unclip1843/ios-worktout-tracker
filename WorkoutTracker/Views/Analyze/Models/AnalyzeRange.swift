import Foundation

enum AnalyzeRange: CaseIterable, Identifiable {
    case thirty
    case ninety
    case year
    case all

    var id: Self { self }

    var label: String {
        switch self {
        case .thirty: return "Last 30 Days"
        case .ninety: return "Last 90 Days"
        case .year: return "Last Year"
        case .all: return "All Time"
        }
    }

    var days: Int {
        switch self {
        case .thirty: return 30
        case .ninety: return 90
        case .year: return 365
        case .all: return .max
        }
    }

    func cutoffDate(relativeTo reference: Date = Date()) -> Date {
        guard days != .max else { return .distantPast }
        let interval = TimeInterval(days * 86_400)
        return reference.addingTimeInterval(-interval).dayOnly
    }
}
