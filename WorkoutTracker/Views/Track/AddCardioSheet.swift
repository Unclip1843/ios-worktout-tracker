import SwiftUI
import SwiftData
import OSLog

struct AddCardioSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise
    let day: Date

    @AppStorage("distanceUnit") private var distanceUnitRaw: String = "mi"
    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .mi }

    @State private var minutes: Int = 30
    @State private var seconds: Int = 0
    @State private var distanceInput: String = ""   // typed in selected unit
    @State private var note: String = ""
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case distance, note }
    private let logger = AppLogger.sheets

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") { Text(exercise.name) }
                Section("Session") {
                    Stepper("Minutes: \(minutes)", value: $minutes, in: 0...600)
                    Stepper("Seconds: \(seconds)", value: $seconds, in: 0...59)
                    TextField("Distance (\(distanceUnit.label), optional)", text: $distanceInput)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .distance)
                        .onChange(of: distanceInput) { _, _ in errorMessage = nil }
                    TextField("Note (optional)", text: $note)
                        .focused($focusedField, equals: .note)
                    if let pace = paceText {
                        Label(pace, systemImage: "speedometer")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Session")
            .onAppear(perform: loadDefaults)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard validateInputs() else { return }
        let totalSec = minutes * 60 + seconds
        let km = parseDistanceValue()
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let s = CardioSession(
            exercise: exercise,
            date: day.dayOnly,
            durationSec: totalSec,
            distanceKm: km,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )
        ctx.insert(s)
        if let error = ctx.saveOrRollback(action: "create cardio session", logger: logger) {
            errorMessage = "Unable to save the cardio session. Please try again."
            logger.error("Save failed for cardio session \(s.id): \(error.localizedDescription)")
            return
        }
        let loggedDistance = km.map { String(format: "%.2f", $0) } ?? "0"
        logger.notice("Logged cardio session \(s.id) for \(exercise.name) with \(totalSec) seconds and \(loggedDistance) km")
        dismiss()
    }

    private var canSave: Bool {
        (minutes > 0 || seconds > 0 || !(distanceInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)) && validateDistanceOnly()
    }

    private var paceText: String? {
        guard let km = parseDistanceValue(), km > 0 else { return nil }
        let total = minutes * 60 + seconds
        guard total > 0 else { return nil }
        let unitDistance = fromKilometers(km, to: distanceUnit)
        let paceSeconds = Double(total) / unitDistance
        guard paceSeconds.isFinite else { return nil }
        let minutesPart = Int(paceSeconds) / 60
        let secondsPart = Int(paceSeconds) % 60
        return String(format: "Pace: %d:%02d per %@", minutesPart, secondsPart, distanceUnit == .mi ? "mile" : "km")
    }

    private func parseDistanceValue() -> Double? {
        let trimmed = distanceInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0 else { return Double.nan }
        if value == 0 { return nil }
        return toKilometers(from: value, unit: distanceUnit)
    }

    @discardableResult
    private func validateDistanceOnly() -> Bool {
        let parsed = parseDistanceValue()
        if case .some(let value) = parsed, value.isNaN {
            return false
        }
        return true
    }

    private func validateInputs() -> Bool {
        if !validateDistanceOnly() {
            errorMessage = "Please enter a valid distance using numbers only."
            focusedField = .distance
            return false
        }

        if minutes == 0 && seconds == 0 && parseDistanceValue() == nil {
            errorMessage = "Add either a duration or a distance so the session isn’t empty."
            focusedField = .distance
            return false
        }

        errorMessage = nil
        return true
    }

    private func loadDefaults() {
        guard distanceInput.isEmpty else { return }
        var descriptor = FetchDescriptor<CardioSession>(
            sortBy: [SortDescriptor(\CardioSession.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 25
        if let last = try? ctx.fetch(descriptor).first(where: { $0.exercise.id == exercise.id }) {
            minutes = max(0, last.durationSec / 60)
            seconds = max(0, last.durationSec % 60)
            if let km = last.distanceKm {
                let display = fromKilometers(km, to: distanceUnit)
                distanceInput = String(format: "%.2f", display)
            }
        }
    }
}
