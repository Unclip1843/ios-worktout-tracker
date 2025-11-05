import SwiftUI
import SwiftData
import OSLog

enum TrackFilter: Equatable {
    case all
    case kind(TrackableItem.Kind)
    case trackable(UUID)
}

struct TrackFilterSection: Identifiable {
    let kind: TrackableItem.Kind
    let title: String
    let iconName: String
    let items: [TrackableItem]

    var id: TrackableItem.Kind { kind }
}

@MainActor
final class TrackScreenViewModel: ObservableObject {
    @Published var day: Date
    @Published var filter: TrackFilter

    private let logger = AppLogger.track

    init(day: Date = Date().dayOnly, filter: TrackFilter = .all) {
        self.day = day
        self.filter = filter
    }

    func resetToToday() {
        day = Date().dayOnly
    }

    func setFilterAll() {
        filter = .all
    }

    func setFilter(kind: TrackableItem.Kind) {
        filter = .kind(kind)
    }

    func setFilter(trackableID: UUID) {
        filter = .trackable(trackableID)
    }

    func filteredTrackables(from trackableOrder: [TrackableItem]) -> [TrackableItem] {
        switch filter {
        case .all:
            return trackableOrder
        case .kind(let kind):
            return trackableOrder.filter { $0.kind == kind }
        case .trackable(let id):
            return trackableOrder.filter { $0.id == id }
        }
    }

    func filterLabel(using trackables: [TrackableItem], exercisesByTrackableID: [UUID: Exercise]) -> String {
        switch filter {
        case .all:
            return "All Trackers"
        case .kind(let kind):
            return kind.displayTitle
        case .trackable(let id):
            if let trackable = trackables.first(where: { $0.id == id }) {
                if let exercise = exercisesByTrackableID[trackable.id], !exercise.isActive {
                    return "\(trackable.name) (Archived)"
                }
                return trackable.name
            }
            return "All Trackers"
        }
    }

    func sections(for trackables: [TrackableItem]) -> [TrackFilterSection] {
        let grouped = Dictionary(grouping: trackables) { $0.kind }
        let orderedKinds: [TrackableItem.Kind] = [.strengthExercise, .cardioExercise, .weight, .meal, .custom]

        return orderedKinds.compactMap { kind in
            guard let items = grouped[kind], !items.isEmpty else { return nil }
            return TrackFilterSection(kind: kind, title: kind.displayTitle, iconName: kind.iconName, items: items)
        }
    }

    func syncFilterIfNeeded(with trackables: [TrackableItem]) {
        switch filter {
        case .all:
            return
        case .kind(let kind):
            guard trackables.contains(where: { $0.kind == kind }) else {
                filter = .all
                return
            }
        case .trackable(let id):
            guard trackables.contains(where: { $0.id == id }) else {
                filter = .all
                return
            }
        }
    }

    func ensureDefaultTrackablesIfNeeded(in context: ModelContext, existing trackables: [TrackableItem]) {
        let defaults: [(name: String, kind: TrackableItem.Kind, tags: [String], notes: String?)] = [
            ("Body Weight", .weight, ["body", "progress"], "Daily body weight entry."),
            ("Hydration Log", .meal, ["hydration", "wellness"], "Track daily hydration.")
        ]

        let existingNames = Set(trackables.map { $0.name.lowercased() })
        var inserted = false
        var nextSortOrder = (trackables.map(\.sortOrder).max() ?? 0) + 1

        for def in defaults where !existingNames.contains(def.name.lowercased()) {
            let trackable = TrackableItem(
                name: def.name,
                kind: def.kind,
                defaultTags: def.tags,
                defaultMuscleGroups: [],
                coingeckoID: nil,
                coinmarketcapID: nil,
                wikipediaURLString: nil,
                websiteURLString: nil,
                notes: def.notes
            )
            trackable.sortOrder = nextSortOrder
            nextSortOrder += 1
            context.insert(trackable)
            inserted = true
            logger.notice("Seeded default tracker \(def.name, privacy: .public)")
        }

        if inserted, let error = context.saveOrRollback(action: "seed default trackers", logger: logger) {
            logger.error("Failed to seed default trackers: \(error.localizedDescription, privacy: .public)")
        }
    }
}

extension TrackableItem.Kind {
    var displayTitle: String {
        switch self {
        case .strengthExercise: return "Strength"
        case .cardioExercise: return "Cardio"
        case .weight: return "Body Metrics"
        case .meal: return "Meals"
        case .custom: return "Custom"
        }
    }

    var iconName: String {
        switch self {
        case .strengthExercise: return "dumbbell"
        case .cardioExercise: return "figure.run"
        case .weight: return "scalemass"
        case .meal: return "fork.knife"
        case .custom: return "slider.horizontal.3"
        }
    }
}
