import SwiftData
import Foundation

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var day: Date           // startOfDay
    var text: String = ""
    var imageFilenames: [String] = []

    init(day: Date) {
        self.id = UUID()
        self.day = day
    }
}
