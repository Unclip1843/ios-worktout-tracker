import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "WorkoutTracker"

    static let track = Logger(subsystem: subsystem, category: "Track")
    static let sheets = Logger(subsystem: subsystem, category: "Sheets")
    static let settings = Logger(subsystem: subsystem, category: "Settings")
    static let journal = Logger(subsystem: subsystem, category: "Journal")
    static let goals = Logger(subsystem: subsystem, category: "Goals")
    static let streaks = Logger(subsystem: subsystem, category: "Streaks")
}
