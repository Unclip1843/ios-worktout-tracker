import SwiftData
import Foundation

@Model
final class TrackableLog {
    @Attribute(.unique) var id: UUID
    var trackableID: UUID
    var loggedAt: Date
    var quantity: Double?
    var unit: String?
    var note: String?

    init(
        trackableID: UUID,
        loggedAt: Date = Date(),
        quantity: Double? = nil,
        unit: String? = nil,
        note: String? = nil
    ) {
        self.id = UUID()
        self.trackableID = trackableID
        self.loggedAt = loggedAt
        self.quantity = quantity
        self.unit = unit
        self.note = note
    }
}
