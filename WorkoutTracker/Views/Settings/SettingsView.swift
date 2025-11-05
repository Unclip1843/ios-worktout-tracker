import SwiftUI
import SwiftData
import OSLog
import PhotosUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Exercise.createdAt) private var exercises: [Exercise]

    @State private var newName: String = ""
    @State private var kind: Exercise.Kind = .strength
    @State private var renaming: Exercise?
    @State private var renameText: String = ""
    @State private var errorAlert: UserFacingError?

    @AppStorage("distanceUnit") private var distanceUnitRaw: String = "mi"
    @AppStorage("weightUnit") private var weightUnitRaw: String = "lb"
    private let logger = AppLogger.settings

    var body: some View {
        Form {
            Section("Units") {
                Picker("Distance", selection: $distanceUnitRaw) {
                    Text("Miles").tag("mi")
                    Text("Kilometers").tag("km")
                }
                Picker("Weight", selection: $weightUnitRaw) {
                    Text("Pounds").tag("lb")
                    Text("Kilograms").tag("kg")
                }
            }

            Section("Tracking Catalog") {
                NavigationLink {
                    TrackableCatalogView()
                } label: {
                    Label("Manage Templates", systemImage: "list.bullet.rectangle")
                }
            }
            Section("Exercises") {
                ForEach(exercises) { ex in
                    HStack {
                        Text(ex.name)
                        Spacer()
                        Text(ex.kind == .strength ? "Strength" : "Cardio").foregroundStyle(.secondary)
                    }
                    .contextMenu {
                        Button("Rename") {
                            renaming = ex
                            renameText = ex.name
                            logger.debug("Preparing to rename exercise \(ex.id)")
                        }
                        Button(ex.isActive ? "Archive" : "Unarchive") {
                            let willActivate = !ex.isActive
                            ex.isActive.toggle()
                            let action = willActivate ? "activate" : "archive"
                            if let error = ctx.saveOrRollback(action: "\(action) exercise", logger: logger) {
                                presentSaveFailure(actionDescription: "update \(ex.name) status", error: error)
                            } else {
                                logger.notice("\(willActivate ? "Activated" : "Archived") exercise \(ex.name)")
                            }
                        }
                        Button(role: .destructive) {
                            deleteExercise(ex)
                        } label: { Text("Delete") }
                    }
                }
                .onDelete { idx in
                    let toRemove = idx.map { exercises[$0] }
                    deleteExercises(toRemove)
                }

                HStack {
                    TextField("New exercise name", text: $newName)
                    Picker("Kind", selection: $kind) {
                        Text("Strength").tag(Exercise.Kind.strength)
                        Text("Cardio").tag(Exercise.Kind.cardio)
                    }.pickerStyle(.segmented).frame(maxWidth: 180)
                    Button("Add") { add() }.disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

        }
        .alert(item: $errorAlert) { info in
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(item: $renaming) { ex in
            NavigationStack {
                Form {
                    TextField("Name", text: $renameText)
                }
                .navigationTitle("Rename")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { renaming = nil } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                            if let ex = renaming, !trimmed.isEmpty {
                                ex.name = trimmed
                                if let error = ctx.saveOrRollback(action: "rename exercise", logger: logger) {
                                    presentSaveFailure(actionDescription: "rename \(ex.name)", error: error)
                                } else {
                                    logger.notice("Renamed exercise \(ex.id) to \(trimmed)")
                                }
                            }
                            renaming = nil
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }

    private func add() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let ex = Exercise(name: name, kind: kind)
        ctx.insert(ex)
        if let error = ctx.saveOrRollback(action: "create exercise from settings", logger: logger) {
            presentSaveFailure(actionDescription: "add \(name)", error: error)
            return
        }
        logger.notice("Added exercise \(ex.name) from settings")
        newName = ""
    }

    private func presentSaveFailure(actionDescription: String, error: Error) {
        errorAlert = UserFacingError(
            title: "Save Failed",
            message: "Unable to \(actionDescription). \(error.localizedDescription)"
        )
    }

    private func deleteExercise(_ exercise: Exercise) {
        removeLinkedTrackable(for: exercise)
        ctx.delete(exercise)
        if let error = ctx.saveOrRollback(action: "delete exercise", logger: logger) {
            presentSaveFailure(actionDescription: "delete \(exercise.name)", error: error)
        } else {
            logger.notice("Deleted exercise \(exercise.name)")
        }
    }

    private func deleteExercises(_ exercises: [Exercise]) {
        exercises.forEach { removeLinkedTrackable(for: $0); ctx.delete($0) }
        if let error = ctx.saveOrRollback(action: "delete selected exercises", logger: logger) {
            presentSaveFailure(actionDescription: "delete selected exercises", error: error)
        } else {
            logger.notice("Deleted \(exercises.count) exercises from settings list")
        }
    }

    private func removeLinkedTrackable(for exercise: Exercise) {
        guard let trackableID = exercise.trackableID else { return }
        var descriptor = FetchDescriptor<TrackableItem>(predicate: #Predicate { $0.id == trackableID })
        descriptor.fetchLimit = 1
        guard let match = try? ctx.fetch(descriptor).first else { return }
        ctx.delete(match)
        logger.notice("Deleted trackable \(match.name) linked to exercise \(exercise.name)")
    }
}

// MARK: quick weight log helper view
struct QuickWeightLogView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var weightUnitRaw: String = "lb"
    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lb }

    @Query(sort: \TrackableItem.createdAt, order: .reverse) private var trackables: [TrackableItem]

    let entryToEdit: WeightEntry?

    @State private var now = Date()
    @State private var weightInput: String = ""
    @State private var errorMessage: String?
    @State private var photoErrorMessage: String?
    @State private var pickedImageItem: PhotosPickerItem?
    @State private var imagePreview: UIImage?
    @State private var imageFilename: String?
    @State private var imageCommitted = false
    @State private var originalImageFilename: String?
    @FocusState private var focusedField: Field?
    @State private var weightTrackable: TrackableItem?

    private enum Field { case weight }
    private let logger = AppLogger.settings

    init(entry: WeightEntry? = nil) {
        self.entryToEdit = entry
        if let entry {
            _now = State(initialValue: entry.at)
            _weightInput = State(initialValue: String(format: "%.2f", entry.kg))
            _imageFilename = State(initialValue: entry.imageFilename)
            _originalImageFilename = State(initialValue: entry.imageFilename)
            if let filename = entry.imageFilename, let image = ImageStore.load(filename) {
                _imagePreview = State(initialValue: image)
            }
        }
    }

    var body: some View {
        Form {
            DatePicker("Time", selection: $now, displayedComponents: [.date, .hourAndMinute])
            TextField("Weight (\(weightUnit.label))", text: $weightInput)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .weight)
                .onChange(of: weightInput) { _, _ in errorMessage = nil }
            PhotosPicker(selection: $pickedImageItem, matching: .images) {
                Label(imagePreview == nil ? "Attach Photo" : "Replace Photo", systemImage: "photo")
            }
            .onChange(of: pickedImageItem) { _, newValue in
                Task { await loadImage(from: newValue) }
            }
            if let preview = imagePreview {
                WeightPhotoPreview(image: preview)
                    .frame(maxHeight: 200)
                    .padding(.vertical, 4)
                Button(role: .destructive) { removeAttachedImage() } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            if let photoErrorMessage {
                Text(photoErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Button("Save") { save() }
                .buttonStyle(.borderedProminent)
                .disabled(weightInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .navigationTitle("Log Weight")
        .onDisappear {
            if !imageCommitted {
                removeAttachedImage()
            }
            imageCommitted = false
        }
        .onAppear {
            ensureDefaultWeightTrackable()
            if let entry = entryToEdit {
                let converted = fromKilograms(entry.kg, to: weightUnit)
                weightInput = formatDecimal(converted)
                weightTrackable = trackables.first(where: { $0.id == entry.trackableID }) ?? weightTrackable
            }
        }
        .toolbar {
            if entryToEdit != nil {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) { deleteEntry() }
                }
            }
        }
    }

    private func save() {
        let trimmed = weightInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let val = Double(normalized), val > 0 else {
            errorMessage = "Enter a positive number for your weight."
            focusedField = .weight
            return
        }
        let kg = toKilograms(from: val, unit: weightUnit)
        ensureDefaultWeightTrackable()
        guard let trackable = weightTrackable else {
            errorMessage = "Unable to find the weight tracker. Please try again."
            logger.error("Missing weight trackable when attempting to log weight")
            return
        }
        if let entryToEdit {
            if let originalImageFilename, originalImageFilename != imageFilename {
                ImageStore.delete(originalImageFilename)
            }
            entryToEdit.at = now
            entryToEdit.kg = kg
            entryToEdit.imageFilename = imageFilename
            entryToEdit.trackableID = trackable.id
            logger.notice("Updated weight entry \(entryToEdit.id)")
        } else {
            let entry = WeightEntry(at: now, kg: kg, imageFilename: imageFilename, trackableID: trackable.id)
            ctx.insert(entry)
            logger.notice("Logged weight entry at \(now)")
        }
        if let error = ctx.saveOrRollback(action: "log weight entry", logger: logger) {
            errorMessage = "Unable to save the weight entry. Please try again."
            logger.error("Failed to log weight: \(error.localizedDescription)")
            if let filename = imageFilename {
                ImageStore.delete(filename)
                imageFilename = nil
                imagePreview = nil
            }
            return
        }
        imageCommitted = true
        imageFilename = nil
        imagePreview = nil
        pickedImageItem = nil
        weightInput = ""
        dismiss()
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else {
            removeAttachedImage()
            return
        }
        do {
            photoErrorMessage = nil
            if let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                let filename = try ImageStore.save(data: data)
                replaceImage(filename: filename, preview: image)
            } else {
                throw PhotoLoadingError.unsupported
            }
        } catch {
            photoErrorMessage = "Failed to attach photo. Please try again."
            logger.error("Failed to load weight log photo: \(error.localizedDescription)")
        }
    }

    private func replaceImage(filename: String, preview: UIImage) {
        if let existing = imageFilename, existing != filename {
            ImageStore.delete(existing)
        }
        imageFilename = filename
        imagePreview = preview
        photoErrorMessage = nil
    }

    private func removeAttachedImage() {
        if let filename = imageFilename {
            ImageStore.delete(filename)
        }
        imageFilename = nil
        imagePreview = nil
        pickedImageItem = nil
        photoErrorMessage = nil
    }

    private enum PhotoLoadingError: Error { case unsupported }

    private func ensureDefaultWeightTrackable() {
        if let current = weightTrackable,
           trackables.contains(where: { $0.id == current.id }) {
            return
        }
        weightTrackable = nil
        if let entry = entryToEdit,
           let match = trackables.first(where: { $0.id == entry.trackableID }) {
            weightTrackable = match
            return
        }
        if let existing = trackables.first(where: { $0.kind == .weight }) {
            weightTrackable = existing
            return
        }

        let item = TrackableItem(
            name: "Body Weight",
            kind: .weight,
            defaultTags: ["body"],
            notes: "Logs created from the quick weight sheet."
        )
        ctx.insert(item)
        if let error = ctx.saveOrRollback(action: "ensure default weight trackable", logger: logger) {
            logger.error("Failed to create default weight trackable: \(error.localizedDescription)")
            return
        }
        weightTrackable = item
    }

    private func deleteEntry() {
        guard let entryToEdit else { return }
        if let filename = entryToEdit.imageFilename {
            ImageStore.delete(filename)
        }
        ctx.delete(entryToEdit)
        if let error = ctx.saveOrRollback(action: "delete weight entry", logger: logger) {
            errorMessage = "Unable to delete the entry. \(error.localizedDescription)"
            logger.error("Failed to delete weight entry: \(error.localizedDescription)")
            return
        }
        dismiss()
    }
}

private struct WeightPhotoPreview: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .cornerRadius(8)
    }
}
