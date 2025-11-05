import SwiftUI
import SwiftData

@main
struct WorkoutTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - SwiftData ModelContainer
fileprivate var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        Exercise.self,
        StrengthSet.self,
        CardioSession.self,
        WeightEntry.self,
        JournalEntry.self,
        TrackableItem.self,
        TrackableLog.self,
        Goal.self
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: false)
    return try! ModelContainer(for: schema, configurations: [config])
}()
