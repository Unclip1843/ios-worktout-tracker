import SwiftUI
import SwiftData
import OSLog
import PhotosUI
import AVKit
import AVFoundation

struct EditSetSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @Bindable var set: StrengthSet
    @State private var saveError: UserFacingError?
    @State private var pickedMediaItem: PhotosPickerItem?
    @State private var attachedMedia: StrengthMediaAttachment?
    @State private var mediaErrorMessage: String?
    @State private var newMediaFilename: String?
    @State private var newMediaIsVideo: Bool = false
    @State private var mediaCommitted = false
    @State private var removeExistingMedia = false

    private let logger = AppLogger.sheets

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") { Text(set.exercise.name) }
                Section("Set") {
                    Stepper("Reps: \(set.reps)", value: $set.reps, in: 1...10000)
                    TextField("Weight (optional)", text: Binding(
                        get: { set.weight.map { String($0) } ?? "" },
                        set: { set.weight = Double($0) }
                    ))
                    .keyboardType(.decimalPad)
                    TextField("Note (optional)", text: Binding(
                        get: { set.note ?? "" },
                        set: { set.note = $0.isEmpty ? nil : $0 }
                    ))
                }
                Section("Media (optional)") {
                    PhotosPicker(selection: $pickedMediaItem, matching: .any(of: [.images, .videos])) {
                        Label(attachedMedia == nil ? "Attach Photo or Video" : "Replace Media", systemImage: attachedMedia?.isVideo == true ? "video" : "photo")
                    }
                    .onChange(of: pickedMediaItem) { _, newValue in
                        Task { await loadMedia(from: newValue) }
                    }

                    if let media = attachedMedia {
                        StrengthMediaPreview(media: media)
                            .frame(maxHeight: media.isVideo ? 220 : 200)
                            .padding(.vertical, 4)
                        Button(role: .destructive) {
                            removeMediaAttachment()
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
            .navigationTitle("Edit Set")
            .alert(item: $saveError) { info in
                Alert(
                    title: Text(info.title),
                    message: Text(info.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cleanupAndDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear(perform: prepareInitialMedia)
            .onDisappear {
                if !mediaCommitted, let temp = newMediaFilename {
                    ImageStore.delete(temp)
                    newMediaFilename = nil
                }
            }
        }
    }

    private func save() {
        let previousFilename = set.mediaFilename
        let previousIsVideo = set.mediaIsVideo

        if let newFilename = newMediaFilename {
            set.mediaFilename = newFilename
            set.mediaIsVideo = newMediaIsVideo
        } else if removeExistingMedia {
            set.mediaFilename = nil
            set.mediaIsVideo = false
        }

        if let error = ctx.saveOrRollback(action: "update strength set", logger: logger) {
            saveError = UserFacingError(
                title: "Save Failed",
                message: "Unable to update the set. \(error.localizedDescription)"
            )
            if let newFilename = newMediaFilename {
                ImageStore.delete(newFilename)
                newMediaFilename = nil
            }
            set.mediaFilename = previousFilename
            set.mediaIsVideo = previousIsVideo
            return
        }
        mediaCommitted = true
        logger.notice("Updated strength set \(set.id)")
        if let newFilename = newMediaFilename {
            if let previousFilename, previousFilename != newFilename {
                ImageStore.delete(previousFilename)
            }
            newMediaFilename = nil
        } else if removeExistingMedia, let previousFilename {
            ImageStore.delete(previousFilename)
        }
        dismiss()
    }

    private func prepareInitialMedia() {
        guard attachedMedia == nil else { return }
        if let filename = set.mediaFilename {
            let preview: UIImage?
            if set.mediaIsVideo {
                preview = generateVideoThumbnail(for: ImageStore.fileURL(for: filename))
            } else {
                preview = ImageStore.load(filename)
            }
            attachedMedia = StrengthMediaAttachment(filename: filename, isVideo: set.mediaIsVideo, previewImage: preview)
        }
    }

    private func loadMedia(from item: PhotosPickerItem?) async {
        guard let item else {
            removeMediaAttachment()
            return
        }
        do {
            mediaErrorMessage = nil
            if let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                let filename = try ImageStore.save(data: data)
                replaceWithNewMedia(StrengthMediaAttachment(filename: filename, isVideo: false, previewImage: image))
            } else if let url = try await item.loadTransferable(type: URL.self) {
                let filename = try ImageStore.saveVideo(from: url)
                let preview = generateVideoThumbnail(for: ImageStore.fileURL(for: filename))
                replaceWithNewMedia(StrengthMediaAttachment(filename: filename, isVideo: true, previewImage: preview))
            } else {
                throw MediaLoadingError.unsupported
            }
        } catch {
            mediaErrorMessage = "Failed to attach media. Please try a different item."
            logger.error("Failed to load media while editing set: \(error.localizedDescription)")
        }
    }

    private func replaceWithNewMedia(_ media: StrengthMediaAttachment) {
        if let temp = newMediaFilename, temp != media.filename {
            ImageStore.delete(temp)
        }
        if removeExistingMedia {
            removeExistingMedia = false
        }
        newMediaFilename = media.filename
        newMediaIsVideo = media.isVideo
        attachedMedia = media
        mediaCommitted = false
    }

    private func removeMediaAttachment() {
        mediaErrorMessage = nil
        if let temp = newMediaFilename {
            ImageStore.delete(temp)
            newMediaFilename = nil
        } else if attachedMedia != nil {
            removeExistingMedia = true
        }
        attachedMedia = nil
        pickedMediaItem = nil
        mediaCommitted = false
    }

    private func cleanupAndDismiss() {
        if !mediaCommitted, let temp = newMediaFilename {
            ImageStore.delete(temp)
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
