import SwiftData
import Foundation

@Model
final class TrackableItem {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case strengthExercise
        case cardioExercise
        case weight
        case meal
        case custom

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .strengthExercise: return "Strength Exercise"
            case .cardioExercise: return "Cardio Exercise"
            case .weight: return "Weight"
            case .meal: return "Meal"
            case .custom: return "Custom"
            }
        }
    }

    @Attribute(.unique) var id: UUID
    var name: String
    var kind: Kind
    var defaultTags: [String]
    var defaultMuscleGroups: [String]
    var coingeckoID: String?
    var coinmarketcapID: String?
    var wikipediaURLString: String?
    var websiteURLString: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Double

    init(
        name: String,
        kind: Kind,
        defaultTags: [String] = [],
        defaultMuscleGroups: [String] = [],
        coingeckoID: String? = nil,
        coinmarketcapID: String? = nil,
        wikipediaURLString: String? = nil,
        websiteURLString: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.kind = kind
        self.defaultTags = defaultTags
        self.defaultMuscleGroups = defaultMuscleGroups
        self.coingeckoID = coingeckoID
        self.coinmarketcapID = coinmarketcapID
        self.wikipediaURLString = wikipediaURLString
        self.websiteURLString = websiteURLString
        self.notes = notes
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.sortOrder = now.timeIntervalSince1970
    }
}
