import SwiftUI
import SwiftData

struct LogTrackableEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    let trackable: TrackableItem
    let existingLog: TrackableLog?
    var onDelete: (() -> Void)?

    @State private var loggedAt: Date = Date()
    @State private var quantityInput: String = ""
    @State private var unitInput: String = ""
    @State private var note: String = ""
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private let logger = AppLogger.track
    private enum Field { case quantity, unit, note }

    init(trackable: TrackableItem, existingLog: TrackableLog? = nil, onDelete: (() -> Void)? = nil) {
        self.trackable = trackable
        self.existingLog = existingLog
        self.onDelete = onDelete
        if let log = existingLog {
            _loggedAt = State(initialValue: log.loggedAt)
            _quantityInput = State(initialValue: log.quantity.map { formatDecimal($0) } ?? "")
            _unitInput = State(initialValue: log.unit ?? Self.defaultUnit(for: trackable.kind))
            _note = State(initialValue: log.note ?? "")
        } else {
            _unitInput = State(initialValue: Self.defaultUnit(for: trackable.kind))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tracker") {
                    LabeledContent("Type", value: trackable.kind.displayName)
                    if !trackable.defaultTags.isEmpty {
                        TagsGrid(tags: trackable.defaultTags)
                    }
                    if let notes = trackable.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Details") {
                    DatePicker("Time", selection: $loggedAt, displayedComponents: [.date, .hourAndMinute])
                    TextField("Quantity (optional)", text: $quantityInput)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .quantity)
                    TextField("Unit", text: $unitInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .unit)
                }

                if !suggestedUnits.isEmpty {
                    Section("Quick Units") {
                        TagsGrid(tags: suggestedUnits, isButton: true) { unit in
                            unitInput = unit
                            focusedField = .quantity
                        }
                    }
                }

                Section("Notes") {
                    TextField("What happened?", text: $note, axis: .vertical)
                        .focused($focusedField, equals: .note)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Log \(trackable.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
                if existingLog != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive) { deleteExistingLog() }
                    }
                }
            }
        }
    }

    private func save() {
        errorMessage = nil

        var quantity: Double?
        if !quantityInput.trimmingCharacters(in: .whitespaces).isEmpty {
            let normalized = quantityInput.replacingOccurrences(of: ",", with: ".")
            guard let value = Double(normalized) else {
                errorMessage = "Quantity must be a number."
                return
            }
            quantity = value
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = unitInput.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existingLog {
            existingLog.loggedAt = loggedAt
            existingLog.quantity = quantity
            existingLog.unit = trimmedUnit.isEmpty ? nil : trimmedUnit
            existingLog.note = trimmedNote.isEmpty ? nil : trimmedNote
            logger.notice("Updated log \(existingLog.id, privacy: .public) for \(trackable.name, privacy: .public)")
        } else {
            let log = TrackableLog(
                trackableID: trackable.id,
                loggedAt: loggedAt,
                quantity: quantity,
                unit: trimmedUnit.isEmpty ? nil : trimmedUnit,
                note: trimmedNote.isEmpty ? nil : trimmedNote
            )
            ctx.insert(log)
            logger.notice("Logged \(trackable.name, privacy: .public) entry at \(loggedAt)")
        }

        if let error = ctx.saveOrRollback(action: "log entry for \(trackable.name)", logger: logger) {
            errorMessage = "Unable to save. \(error.localizedDescription)"
            logger.error("Failed to save trackable log for \(trackable.name, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return
        }

        dismiss()
    }

    private static func defaultUnit(for kind: TrackableItem.Kind) -> String {
        switch kind {
        case .meal:
            return "meal"
        case .custom:
            return ""
        case .weight:
            return "kg"
        case .strengthExercise, .cardioExercise:
            return ""
        }
    }

    private var suggestedUnits: [String] {
        switch trackable.kind {
        case .meal:
            return ["meal", "kcal", "serving"]
        case .custom:
            let lowerTags = trackable.defaultTags.map { $0.lowercased() }
            if lowerTags.contains(where: { $0.contains("hydration") || $0.contains("water") }) {
                return ["oz", "ml", "cups"]
            }
            if lowerTags.contains(where: { $0.contains("sleep") }) {
                return ["hours"]
            }
            if lowerTags.contains(where: { $0.contains("meditation") || $0.contains("breath") }) {
                return ["minutes"]
            }
            return []
        case .weight, .strengthExercise, .cardioExercise:
            return []
        }
    }

    private func deleteExistingLog() {
        guard let existingLog else { return }
        ctx.delete(existingLog)
        if let error = ctx.saveOrRollback(action: "delete log for \(trackable.name)", logger: logger) {
            errorMessage = "Unable to delete. \(error.localizedDescription)"
            logger.error("Failed to delete trackable log for \(trackable.name, privacy: .public): \(error.localizedDescription, privacy: .public)")
            ctx.insert(existingLog)
            return
        }
        onDelete?()
        dismiss()
    }
}

private struct TagsGrid: View {
    let tags: [String]
    var isButton: Bool = false
    var action: ((String) -> Void)?

    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                if isButton, let action {
                    Button {
                        action(tag)
                    } label: {
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
