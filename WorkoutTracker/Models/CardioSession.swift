import SwiftData
import Foundation

@Model
final class CardioSession {
    @Attribute(.unique) var id: UUID
    var exercise: Exercise
    var date: Date              // startOfDay
    var durationSec: Int
    var distanceKm: Double?     // stored in kilometers
    var note: String?
    var createdAt: Date = Date.now

    init(exercise: Exercise, date: Date, durationSec: Int, distanceKm: Double? = nil, note: String? = nil) {
        self.id = UUID()
        self.exercise = exercise
        self.date = date
        self.durationSec = durationSec
        self.distanceKm = distanceKm
        self.note = note
    }
}
