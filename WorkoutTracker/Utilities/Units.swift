import Foundation
import SwiftUI

enum DistanceUnit: String, CaseIterable, Identifiable {
    case mi, km
    var id: String { rawValue }
    var label: String { rawValue.uppercased() }
}

enum WeightUnit: String, CaseIterable, Identifiable {
    case lb, kg
    var id: String { rawValue }
    var label: String { rawValue.uppercased() }
}

// Conversion helpers
func toKilometers(from value: Double, unit: DistanceUnit) -> Double {
    unit == .mi ? value * 1.60934 : value
}
func fromKilometers(_ km: Double, to unit: DistanceUnit) -> Double {
    unit == .mi ? km / 1.60934 : km
}
func toKilograms(from value: Double, unit: WeightUnit) -> Double {
    unit == .lb ? value * 0.45359237 : value
}
func fromKilograms(_ kg: Double, to unit: WeightUnit) -> Double {
    unit == .lb ? kg / 0.45359237 : kg
}
