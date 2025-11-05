import SwiftUI
import SwiftData
import OSLog

struct AddExerciseSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    var onCreate: ((Exercise) -> Void)?

    @State private var name: String = ""
    @State private var kind: Exercise.Kind = .strength
    @State private var saveError: UserFacingError?

    private let logger = AppLogger.sheets

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $kind) {
                        Text("Strength").tag(Exercise.Kind.strength)
                        Text("Cardio").tag(Exercise.Kind.cardio)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Exercise")
            .alert(item: $saveError) { info in
                Alert(
                    title: Text(info.title),
                    message: Text(info.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let exercise = Exercise(name: trimmed, kind: kind)
        ctx.insert(exercise)
        if let error = ctx.saveOrRollback(action: "create exercise", logger: logger) {
            saveError = UserFacingError(
                title: "Save Failed",
                message: "Unable to create the exercise. \(error.localizedDescription)"
            )
            return
        }
        logger.notice("Created exercise \(exercise.name) of type \(exercise.kind.rawValue)")
        if let onCreate {
            DispatchQueue.main.async {
                onCreate(exercise)
            }
        }
        dismiss()
    }
}
