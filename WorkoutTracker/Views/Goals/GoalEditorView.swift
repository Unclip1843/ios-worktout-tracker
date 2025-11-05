import SwiftUI
import SwiftData
import OSLog

struct GoalEditorView: View {
    enum Mode {
        case create
        case edit(Goal)

        var isEditing: Bool {
            if case .edit = self { return true }
            return false
        }

        var title: String {
            switch self {
            case .create: return "New Goal"
            case .edit: return "Edit Goal"
            }
        }
    }

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.createdAt) private var exercises: [Exercise]
    @Query(sort: \TrackableItem.createdAt) private var trackables: [TrackableItem]

    @AppStorage("distanceUnit") private var distanceUnitRaw: String = "mi"
    @AppStorage("weightUnit") private var weightUnitRaw: String = "lb"

    private var defaultDistanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .mi }
    private var defaultWeightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lb }

    let mode: Mode

    @State private var titleText: String
    @State private var kind: Goal.Kind
    @State private var cadence: Goal.Cadence
    @State private var direction: Goal.Direction
    @State private var selectedExerciseID: UUID?
    @State private var selectedTrackableID: UUID?
    @State private var targetValueText: String
    @State private var unitText: String
    @State private var includeDeadline: Bool
    @State private var deadline: Date
    @State private var noteText: String
    @State private var errorMessage: String?

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .create:
            _titleText = State(initialValue: "")
            _kind = State(initialValue: .strengthMaxReps)
            _cadence = State(initialValue: .oneTime)
            _direction = State(initialValue: .atLeast)
            _selectedExerciseID = State(initialValue: nil)
            _selectedTrackableID = State(initialValue: nil)
            _targetValueText = State(initialValue: "")
            _unitText = State(initialValue: "reps")
            _includeDeadline = State(initialValue: false)
            _deadline = State(initialValue: Date().addingTimeInterval(7 * 24 * 60 * 60))
            _noteText = State(initialValue: "")
        case .edit(let goal):
            _titleText = State(initialValue: goal.title)
            _kind = State(initialValue: goal.kind)
            _cadence = State(initialValue: goal.cadence)
            _direction = State(initialValue: goal.direction)
            _selectedExerciseID = State(initialValue: goal.exerciseID)
            _selectedTrackableID = State(initialValue: goal.trackableID)
            _targetValueText = State(initialValue: formatDecimal(goal.targetValue, maxFractionDigits: goal.kind == .strengthMaxReps ? 0 : 2))
            _unitText = State(initialValue: goal.unit)
            if let deadline = goal.deadline {
                _includeDeadline = State(initialValue: true)
                _deadline = State(initialValue: deadline)
            } else {
                _includeDeadline = State(initialValue: false)
                _deadline = State(initialValue: Date().addingTimeInterval(7 * 24 * 60 * 60))
            }
            _noteText = State(initialValue: goal.note ?? "")
        }
    }

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Title", text: $titleText)
                Picker("Kind", selection: $kind) {
                    ForEach(Goal.Kind.allCases, id: \.id) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                Picker("Direction", selection: $direction) {
                    ForEach(Goal.Direction.allCases, id: \.id) { option in
                        Text(option.description).tag(option)
                    }
                }
            }

            Section("Cadence") {
                Picker("Cadence", selection: $cadence) {
                    ForEach(Goal.Cadence.allCases, id: \.id) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.navigationLink)

                if cadence != .oneTime {
                    Text("Progress resets each \(cadence.displayName.lowercased()). Hitting the target keeps your streak alive.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Track this goal until you reach the target once.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if requiresExercise(kind) {
                Section("Exercise") {
                    Picker("Exercise", selection: $selectedExerciseID) {
                        Text("Choose Exercise").tag(UUID?.none)
                        ForEach(exercisesForKind(kind), id: \.id) { exercise in
                            Text(exercise.name).tag(Optional(exercise.id))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }

            if kind == .custom {
                Section("Trackable") {
                    Picker("Trackable", selection: $selectedTrackableID) {
                        Text("Choose Item").tag(UUID?.none)
                        ForEach(trackables, id: \.id) { item in
                            Text(item.name).tag(Optional(item.id))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }

            Section("Target") {
                TextField("Target Value", text: $targetValueText)
                    .keyboardType(.decimalPad)

                switch kind {
                case .weightTarget, .strengthMaxWeight:
                    Picker("Unit", selection: $unitText) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.label).tag(unit.rawValue)
                        }
                    }
                case .cardioDistance:
                    Picker("Unit", selection: $unitText) {
                        ForEach(DistanceUnit.allCases) { unit in
                            Text(unit.label).tag(unit.rawValue)
                        }
                    }
                case .strengthMaxReps:
                    HStack {
                        Text("Unit")
                        Spacer()
                        Text("reps")
                            .foregroundStyle(.secondary)
                    }
                case .cardioDuration:
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("minutes")
                            .foregroundStyle(.secondary)
                    }
                case .custom:
                    TextField("Unit (optional)", text: $unitText)
                }
            }

            Section("Extras") {
                Toggle("Add deadline", isOn: $includeDeadline.animation())
                if includeDeadline {
                    DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                }
                TextField("Note", text: $noteText, axis: .vertical)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
            }
        }
        .onAppear(perform: applyDefaultsIfNeeded)
        .onChange(of: kind) { _, newValue in
            applyDefaults(for: newValue)
            validateSelections()
        }
    }

    private func save() {
        errorMessage = nil
        let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Please provide a title."
            return
        }

        guard let target = parseTargetValue() else {
            errorMessage = "Enter a valid target number."
            return
        }

        var resolvedUnit = resolvedUnitText()
        var resolvedExerciseID: UUID? = nil
        var resolvedTrackableID: UUID? = nil

        switch kind {
        case .strengthMaxReps, .strengthMaxWeight, .cardioDistance, .cardioDuration:
            guard let exerciseID = selectedExerciseID,
                  exercises.contains(where: { $0.id == exerciseID }) else {
                errorMessage = "Select an exercise to track."
                return
            }
            resolvedExerciseID = exerciseID
            if let exercise = exercises.first(where: { $0.id == exerciseID }) {
                resolvedTrackableID = exercise.trackableID
            }
        case .custom:
            guard let trackableID = selectedTrackableID,
                  trackables.contains(where: { $0.id == trackableID }) else {
                errorMessage = "Select an item to track."
                return
            }
            resolvedTrackableID = trackableID
        case .weightTarget:
            resolvedExerciseID = nil
            resolvedTrackableID = nil
        }

        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let deadlineValue = includeDeadline ? deadline : nil

        switch mode {
        case .create:
            let goal = Goal(
                title: trimmedTitle,
                kind: kind,
                cadence: cadence,
                direction: direction,
                exerciseID: resolvedExerciseID,
                trackableID: resolvedTrackableID,
                targetValue: target,
                unit: resolvedUnit,
                deadline: deadlineValue,
                note: trimmedNote.isEmpty ? nil : trimmedNote
            )
            ctx.insert(goal)
            if let error = ctx.saveOrRollback(action: "create goal", logger: AppLogger.goals) {
                errorMessage = "Unable to save. \(error.localizedDescription)"
                return
            }
            AppLogger.goals.notice("Created goal \(goal.title, privacy: .public)")
        case .edit(let goal):
            goal.title = trimmedTitle
            goal.kind = kind
            goal.cadence = cadence
            goal.direction = direction
            goal.exerciseID = resolvedExerciseID
            goal.trackableID = resolvedTrackableID
            goal.targetValue = target
            goal.unit = resolvedUnit
            goal.deadline = deadlineValue
            goal.note = trimmedNote.isEmpty ? nil : trimmedNote

            if let error = ctx.saveOrRollback(action: "update goal", logger: AppLogger.goals) {
                errorMessage = "Unable to update. \(error.localizedDescription)"
                return
            }
            AppLogger.goals.notice("Updated goal \(goal.title, privacy: .public)")
        }

        dismiss()
    }

    private func parseTargetValue() -> Double? {
        let trimmed = targetValueText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(trimmed), value >= 0 else { return nil }
        switch kind {
        case .cardioDuration:
            // Stored in minutes
            return value
        default:
            return value
        }
    }

    private func resolvedUnitText() -> String {
        switch kind {
        case .strengthMaxReps:
            return "reps"
        case .cardioDuration:
            return "min"
        case .weightTarget, .strengthMaxWeight, .cardioDistance:
            return unitText
        case .custom:
            return unitText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func requiresExercise(_ kind: Goal.Kind) -> Bool {
        switch kind {
        case .strengthMaxReps, .strengthMaxWeight, .cardioDistance, .cardioDuration:
            return true
        default:
            return false
        }
    }

    private func exercisesForKind(_ kind: Goal.Kind) -> [Exercise] {
        switch kind {
        case .strengthMaxReps, .strengthMaxWeight:
            return exercises.filter { $0.kind == .strength }
        case .cardioDistance, .cardioDuration:
            return exercises.filter { $0.kind == .cardio }
        default:
            return exercises
        }
    }

    private func applyDefaultsIfNeeded() {
        if case .create = mode {
            applyDefaults(for: kind)
        }
        validateSelections()
    }

    private func applyDefaults(for kind: Goal.Kind) {
        switch kind {
        case .strengthMaxReps:
            unitText = "reps"
            direction = .atLeast
            if selectedExerciseID == nil {
                selectedExerciseID = exercisesForKind(kind).first?.id
            }
        case .strengthMaxWeight:
            if !WeightUnit.allCases.map(\.rawValue).contains(unitText) {
                unitText = defaultWeightUnit.rawValue
            }
            direction = .atLeast
            if selectedExerciseID == nil {
                selectedExerciseID = exercisesForKind(kind).first?.id
            }
        case .cardioDistance:
            if !DistanceUnit.allCases.map(\.rawValue).contains(unitText) {
                unitText = defaultDistanceUnit.rawValue
            }
            direction = .atLeast
            if selectedExerciseID == nil {
                selectedExerciseID = exercisesForKind(kind).first?.id
            }
        case .cardioDuration:
            unitText = "min"
            direction = .atLeast
            if selectedExerciseID == nil {
                selectedExerciseID = exercisesForKind(kind).first?.id
            }
        case .weightTarget:
            if !WeightUnit.allCases.map(\.rawValue).contains(unitText) {
                unitText = defaultWeightUnit.rawValue
            }
            direction = .atMost
        case .custom:
            if selectedTrackableID == nil {
                selectedTrackableID = trackables.first?.id
            }
        }
    }

    private func validateSelections() {
        if requiresExercise(kind),
           let exerciseID = selectedExerciseID,
           !exercises.contains(where: { $0.id == exerciseID }) {
            selectedExerciseID = exercisesForKind(kind).first?.id
        }
        if kind == .custom,
           let trackableID = selectedTrackableID,
           !trackables.contains(where: { $0.id == trackableID }) {
            selectedTrackableID = trackables.first?.id
        }
    }
}
