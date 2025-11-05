import SwiftUI
import SwiftData
import Foundation

struct AddTrackingSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    private let logger = AppLogger.sheets

    enum Mode: String, CaseIterable, Identifiable {
        case catalog
        case custom

        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }

    @State private var mode: Mode = .catalog
    @StateObject private var customViewModel = AddTrackingCustomViewModel()
    @State private var errorMessage: String?
    @State private var duplicateAlertMessage: String?

    var onCreateExercise: ((Exercise) -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if mode == .catalog {
                    catalogContent
                } else {
                    customContent
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Tracking")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if mode == .custom {
                        Button("Save") { saveCustom() }
                            .disabled(customViewModel.trimmedName.isEmpty)
                    }
                }
            }
        }
        .onAppear {
            customViewModel.reset()
        }
        .onChange(of: mode) { _, newMode in
            errorMessage = nil
            logger.notice("AddTrackingSheet mode changed to \(newMode.rawValue, privacy: .public)")
        }
        .alert("Already Added", isPresented: Binding(
            get: { duplicateAlertMessage != nil },
            set: { if !$0 { duplicateAlertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { duplicateAlertMessage = nil }
        } message: {
            Text(duplicateAlertMessage ?? "")
        }
    }

    @ViewBuilder
    private var catalogContent: some View {
        ForEach(TrackableCatalog.groupedTemplates, id: \.title) { group in
            Section(group.title) {
                ForEach(group.items) { template in
                    Button {
                        addTemplate(template)
                    } label: {
                        CatalogTemplateRow(template: template)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var customContent: some View {
        AddTrackingCustomView(viewModel: customViewModel)
    }

    private func saveCustom() {
        errorMessage = nil
        let trimmedName = customViewModel.trimmedName
        guard !trimmedName.isEmpty else {
            errorMessage = "Please provide a name."
            logger.error("Attempted to save custom trackable without a name")
            return
        }

        let trackable = TrackableItem(
            name: trimmedName,
            kind: customViewModel.kind,
            defaultTags: customViewModel.tagList,
            defaultMuscleGroups: customViewModel.muscleGroupsArray,
            coingeckoID: customViewModel.trimmedCoingeckoID,
            coinmarketcapID: customViewModel.trimmedCoinmarketcapID,
            wikipediaURLString: customViewModel.trimmedWikipediaURL,
            websiteURLString: customViewModel.trimmedWebsiteURL,
            notes: customViewModel.trimmedNotes
        )

        logger.notice("Saving custom trackable \(trackable.name, privacy: .public) of type \(trackable.kind.rawValue, privacy: .public)")
        persist(trackable: trackable)
    }

    private func exerciseForTrackable(_ trackable: TrackableItem) -> Exercise? {
        switch trackable.kind {
        case .strengthExercise:
            let exercise = Exercise(name: trackable.name, kind: .strength)
            exercise.trackableID = trackable.id
            return exercise
        case .cardioExercise:
            let exercise = Exercise(name: trackable.name, kind: .cardio)
            exercise.trackableID = trackable.id
            return exercise
        default:
            return nil
        }
    }

    private func addTemplate(_ template: TrackableTemplate) {
        errorMessage = nil

        logger.notice("Selected catalog template \(template.name, privacy: .public)")
        let trackable = TrackableItem(
            name: template.name,
            kind: template.kind,
            defaultTags: template.tags,
            defaultMuscleGroups: template.muscleGroups,
            coingeckoID: nil,
            coinmarketcapID: nil,
            wikipediaURLString: nil,
            websiteURLString: nil,
            notes: template.notes
        )

        persist(trackable: trackable)
    }

    private func persist(trackable: TrackableItem) {
        let normalizedName = trackable.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canCreateTrackable(named: normalizedName, kind: trackable.kind) else {
            logger.error("Duplicate trackable prevented for \(normalizedName, privacy: .public)")
            return
        }

        trackable.name = normalizedName
        ctx.insert(trackable)

        if let exercise = exerciseForTrackable(trackable) {
            ctx.insert(exercise)
            onCreateExercise?(exercise)
            logger.notice("Created exercise \(exercise.name, privacy: .public) linked to trackable \(trackable.name, privacy: .public)")
        }

        if let error = ctx.saveOrRollback(action: "create trackable item", logger: logger) {
            errorMessage = "Unable to save. \(error.localizedDescription)"
            logger.error("Failed to persist trackable \(trackable.name, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return
        }

        logger.notice("Persisted trackable \(trackable.name, privacy: .public)")
        dismiss()
    }

    private func canCreateTrackable(named name: String, kind: TrackableItem.Kind) -> Bool {
        if trackableExists(named: name) {
            errorMessage = nil
            duplicateAlertMessage = "\"\(name)\" is already in your tracking list."
            return false
        }

        if let exerciseKind = exerciseKind(for: kind), exerciseExists(named: name, kind: exerciseKind) {
            errorMessage = nil
            duplicateAlertMessage = "\"\(name)\" is already in your tracking list."
            return false
        }

        return true
    }

    private func trackableExists(named name: String) -> Bool {
        let descriptor = FetchDescriptor<TrackableItem>()
        guard let existing = try? ctx.fetch(descriptor) else { return false }
        return existing.contains {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    private func exerciseExists(named name: String, kind: Exercise.Kind) -> Bool {
        let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { $0.kind == kind })
        guard let existing = try? ctx.fetch(descriptor) else { return false }
        return existing.contains {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    private func exerciseKind(for kind: TrackableItem.Kind) -> Exercise.Kind? {
        switch kind {
        case .strengthExercise: return .strength
        case .cardioExercise: return .cardio
        default: return nil
        }
    }
}

private struct CatalogTemplateRow: View {
    let template: TrackableTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(template.kind.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !template.muscleGroups.isEmpty {
                Text("Muscles: \(template.muscleGroups.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !template.tags.isEmpty {
                Text("Tags: \(template.tags.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let notes = template.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
