import SwiftData
import Foundation

@Model
final class Goal {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case weightTarget
        case strengthMaxReps
        case strengthMaxWeight
        case cardioDistance
        case cardioDuration
        case custom

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .weightTarget: return "Weight Target"
            case .strengthMaxReps: return "Total Reps"
            case .strengthMaxWeight: return "Heaviest Set"
            case .cardioDistance: return "Distance"
            case .cardioDuration: return "Duration"
            case .custom: return "Custom"
            }
        }
    }

    enum Cadence: String, Codable, CaseIterable, Identifiable {
        case oneTime
        case daily
        case weekly
        case monthly
        case yearly

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .oneTime: return "One-Time"
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }

        var periodLabel: String {
            switch self {
            case .oneTime: return "Overall"
            case .daily: return "Today"
            case .weekly: return "This Week"
            case .monthly: return "This Month"
            case .yearly: return "This Year"
            }
        }

        func streakUnit(for count: Int) -> String {
            let plural = count == 1 ? "" : "s"
            switch self {
            case .oneTime: return "completion\(plural)"
            case .daily: return "day\(plural)"
            case .weekly: return "week\(plural)"
            case .monthly: return "month\(plural)"
            case .yearly: return "year\(plural)"
            }
        }
    }

    enum Direction: String, Codable, Identifiable, CaseIterable {
        case atLeast
        case atMost

        var id: String { rawValue }
        var description: String {
            switch self {
            case .atLeast: return "At Least"
            case .atMost: return "At Most"
            }
        }
    }

    @Attribute(.unique) var id: UUID
    var title: String
    var kind: Kind
    var cadence: Cadence = Goal.Cadence.oneTime
    var direction: Direction
    var exerciseID: UUID?
    var trackableID: UUID?
    var targetValue: Double
    var unit: String
    var deadline: Date?
    var note: String?
    var createdAt: Date

    init(title: String,
         kind: Kind,
         cadence: Cadence = .oneTime,
         direction: Direction,
         exerciseID: UUID? = nil,
         trackableID: UUID? = nil,
         targetValue: Double,
         unit: String,
         deadline: Date? = nil,
         note: String? = nil) {
        self.id = UUID()
        self.title = title
        self.kind = kind
        self.cadence = cadence
        self.direction = direction
        self.exerciseID = exerciseID
        self.trackableID = trackableID
        self.targetValue = targetValue
        self.unit = unit
        self.deadline = deadline
        self.note = note
        self.createdAt = Date()
    }
}

extension Goal: Identifiable {}
