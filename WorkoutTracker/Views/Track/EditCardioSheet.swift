import SwiftUI
import SwiftData
import OSLog

struct EditCardioSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @Bindable var session: CardioSession

    @AppStorage("distanceUnit") private var distanceUnitRaw: String = "mi"
    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .mi }

    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @State private var distanceInput: String = ""
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case distance }
    private let logger = AppLogger.sheets

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") { Text(session.exercise.name) }
                Section("Session") {
                    Stepper("Minutes: \(minutes)", value: $minutes, in: 0...600)
                    Stepper("Seconds: \(seconds)", value: $seconds, in: 0...59)
                    TextField("Distance (\(distanceUnit.label), optional)", text: $distanceInput)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .distance)
                        .onChange(of: distanceInput) { _, _ in errorMessage = nil }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                minutes = session.durationSec / 60
                seconds = session.durationSec % 60
                if let km = session.distanceKm {
                    distanceInput = String(format: "%.2f", fromKilometers(km, to: distanceUnit))
                }
            }
        }
    }

    private func save() {
        let totalSec = minutes * 60 + seconds
        let parsedDistance = parseDistanceValue()

        if case .some(let value) = parsedDistance, value.isNaN {
            errorMessage = "Please enter a valid distance using numbers only."
            focusedField = .distance
            return
        }

        session.durationSec = totalSec
        if let parsed = parsedDistance, parsed > 0 {
            session.distanceKm = parsed
        } else {
            session.distanceKm = nil
        }

        if let error = ctx.saveOrRollback(action: "update cardio session", logger: logger) {
            errorMessage = "Unable to update the session. Please try again."
            logger.error("Save failed for cardio session \(session.id): \(error.localizedDescription)")
            return
        }
        logger.notice("Updated cardio session \(session.id)")
        dismiss()
    }

    private func parseDistanceValue() -> Double? {
        let trimmed = distanceInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0 else { return Double.nan }
        if value == 0 { return nil }
        return toKilometers(from: value, unit: distanceUnit)
    }
}
