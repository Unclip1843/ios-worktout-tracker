import SwiftData
import Foundation

@Model
final class Exercise {
    enum Kind: String, Codable, CaseIterable { case strength, cardio }

    @Attribute(.unique) var id: UUID
    var name: String
    var kind: Kind
    var isActive: Bool = true
    var createdAt: Date = Date.now
    var trackableID: UUID?

    init(name: String, kind: Kind) {
        self.id = UUID()
        self.name = name
        self.kind = kind
    }
}

extension Exercise: Identifiable {}
