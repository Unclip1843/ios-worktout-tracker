import SwiftUI
import SwiftData
import OSLog
import PhotosUI
import AVKit
import AVFoundation

struct AddSetSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise
    let day: Date

    @State private var reps: Int = 10
    @State private var weightInput: String = ""
    @State private var note: String = ""
    @State private var errorMessage: String?
    @State private var mediaErrorMessage: String?
    @State private var pickedMediaItem: PhotosPickerItem?
    @State private var attachedMedia: StrengthMediaAttachment?
    @State private var mediaCommitted = false
    @FocusState private var focusedField: Field?

    private enum Field { case weight, note }
    private let logger = AppLogger.sheets

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") { Text(exercise.name) }
                Section("Set") {
                    Stepper("Reps: \(reps)", value: $reps, in: 1...10000)
                    TextField("Weight (optional)", text: $weightInput)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                        .onChange(of: weightInput) { _, _ in errorMessage = nil }
                    TextField("Note (optional)", text: $note)
                        .focused($focusedField, equals: .note)
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                Section("Media (optional)") {
                    PhotosPicker(selection: $pickedMediaItem, matching: .any(of: [.images, .videos])) {
                        Label(attachedMedia == nil ? "Attach Photo or Video" : "Replace Media", systemImage: attachedMedia?.isVideo == true ? "video" : "photo")
                    }
                    .onChange(of: pickedMediaItem) { _, newItem in
                        Task { await loadMedia(from: newItem) }
                    }

                    if let media = attachedMedia {
                        StrengthMediaPreview(media: media)
                            .frame(maxHeight: media.isVideo ? 220 : 200)
                            .padding(.vertical, 4)
                        Button(role: .destructive) {
                            removeAttachedMedia()
                        } label: {
                            Label("Remove Media", systemImage: "trash")
                        }
                    }
                    if let mediaErrorMessage {
                        Text(mediaErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Set")
            .onAppear(perform: loadDefaults)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cleanupAndDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(!canSave)
                }
            }
            .onDisappear {
                if !mediaCommitted, let media = attachedMedia {
                    ImageStore.delete(media.filename)
                }
            }
        }
    }

    private func save() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateWeightInput(silently: false) else {
            focusedField = .weight
            return
        }
        let weightValue = parseWeightValue()

        let set = StrengthSet(
            exercise: exercise,
            date: day.dayOnly,
            reps: reps,
            weight: weightValue,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            mediaFilename: attachedMedia?.filename,
            mediaIsVideo: attachedMedia?.isVideo ?? false
        )
        ctx.insert(set)
        if let error = ctx.saveOrRollback(action: "create strength set", logger: logger) {
            errorMessage = "Unable to save the set. Please try again."
            logger.error("Save failed for strength set \(set.id): \(error.localizedDescription)")
            if let media = attachedMedia {
                ImageStore.delete(media.filename)
                attachedMedia = nil
            }
            focusedField = .weight
            return
        }
        mediaCommitted = true
        logger.notice("Logged strength set \(set.id) with \(reps) reps for \(exercise.name)")
        dismiss()
    }

    private var canSave: Bool {
        reps > 0 && validateWeightInput(silently: true)
    }

    private func parseWeightValue() -> Double? {
        let trimmed = weightInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0 else { return Double.nan }
        return value == 0 ? nil : value
    }

    @discardableResult
    private func validateWeightInput(silently: Bool) -> Bool {
        let result = parseWeightValue()
        switch result {
        case .some(let value) where value.isNaN:
            if !silently { errorMessage = "Please enter a valid, non-negative weight." }
            return false
        default:
            if !silently { errorMessage = nil }
            return true
        }
    }

    private func loadDefaults() {
        guard reps == 10, weightInput.isEmpty else { return }
        var descriptor = FetchDescriptor<StrengthSet>(
            sortBy: [SortDescriptor(\StrengthSet.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 25
        if let lastSet = try? ctx.fetch(descriptor).first(where: { $0.exercise.id == exercise.id }) {
            reps = lastSet.reps
            if let weight = lastSet.weight {
                weightInput = String(format: "%.1f", weight)
            }
        }
    }

    private func loadMedia(from item: PhotosPickerItem?) async {
        guard let item else {
            removeAttachedMedia()
            return
        }
        do {
            mediaErrorMessage = nil
            if let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                let filename = try ImageStore.save(data: data)
                replaceAttachedMedia(with: StrengthMediaAttachment(filename: filename, isVideo: false, previewImage: image))
            } else if let url = try await item.loadTransferable(type: URL.self) {
                let filename = try ImageStore.saveVideo(from: url)
                let preview = generateVideoThumbnail(for: ImageStore.fileURL(for: filename))
                replaceAttachedMedia(with: StrengthMediaAttachment(filename: filename, isVideo: true, previewImage: preview))
            } else {
                throw MediaLoadingError.unsupported
            }
        } catch {
            mediaErrorMessage = "Failed to attach media. Please try a different item."
            logger.error("Failed to load media for strength set: \(error.localizedDescription)")
        }
    }

    private func replaceAttachedMedia(with media: StrengthMediaAttachment) {
        if let existing = attachedMedia, existing.filename != media.filename {
            ImageStore.delete(existing.filename)
        }
        attachedMedia = media
        mediaCommitted = false
    }

    private func removeAttachedMedia() {
        if !mediaCommitted, let media = attachedMedia {
            ImageStore.delete(media.filename)
        }
        attachedMedia = nil
        pickedMediaItem = nil
        mediaCommitted = false
    }

    private func cleanupAndDismiss() {
        if !mediaCommitted {
            if let media = attachedMedia {
                ImageStore.delete(media.filename)
            }
        }
        dismiss()
    }

    private func generateVideoThumbnail(for url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1, preferredTimescale: 600)
        if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }

    private enum MediaLoadingError: Error { case unsupported }
}

struct StrengthMediaAttachment: Identifiable, Equatable {
    let id = UUID()
    let filename: String
    let isVideo: Bool
    let previewImage: UIImage?
}

struct StrengthMediaPreview: View {
    let media: StrengthMediaAttachment

    var body: some View {
        if media.isVideo {
            VideoPlayer(player: AVPlayer(url: ImageStore.fileURL(for: media.filename)))
                .cornerRadius(8)
        } else if let image = media.previewImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .cornerRadius(8)
        } else {
            Label("Media attached", systemImage: "paperclip")
        }
    }
}
