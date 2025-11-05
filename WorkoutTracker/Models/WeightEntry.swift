import SwiftData
import Foundation

@Model
final class WeightEntry {
    @Attribute(.unique) var id: UUID
    var at: Date            // includes time for charting
    var kg: Double          // stored in kilograms
    var imageFilename: String?
    var trackableID: UUID?

    init(at: Date, kg: Double, imageFilename: String? = nil, trackableID: UUID? = nil) {
        self.id = UUID()
        self.at = at
        self.kg = kg
        self.imageFilename = imageFilename
        self.trackableID = trackableID
    }
}
