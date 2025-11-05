import SwiftData
import Foundation

@Model
final class StrengthSet {
    @Attribute(.unique) var id: UUID
    var exercise: Exercise
    var date: Date          // startOfDay for grouping
    var reps: Int
    var weight: Double?     // optional per-set load
    var note: String?
    var createdAt: Date = Date.now
    var mediaFilename: String?
    var mediaIsVideo: Bool = false

    init(
        exercise: Exercise,
        date: Date,
        reps: Int,
        weight: Double? = nil,
        note: String? = nil,
        mediaFilename: String? = nil,
        mediaIsVideo: Bool = false
    ) {
        self.id = UUID()
        self.exercise = exercise
        self.date = date
        self.reps = reps
        self.weight = weight
        self.note = note
        self.mediaFilename = mediaFilename
        self.mediaIsVideo = mediaIsVideo
    }
}
