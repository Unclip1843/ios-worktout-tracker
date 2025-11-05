import SwiftUI
import SwiftData
import PhotosUI
import OSLog

struct JournalView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \JournalEntry.day) private var entries: [JournalEntry]
    @Query(sort: \WeightEntry.at) private var weights: [WeightEntry]
    @Query(sort: \StrengthSet.date) private var sets: [StrengthSet]
    @Query(sort: \CardioSession.date) private var sessions: [CardioSession]

    @State private var day: Date = Date().dayOnly
    @State private var pickedItems: [PhotosPickerItem] = []
    @State private var errorAlert: UserFacingError?
    @State private var weightMediaPreview: WeightMediaPresentation?

    @AppStorage("distanceUnit") private var distanceUnitRaw: String = "mi"
    @AppStorage("weightUnit") private var weightUnitRaw: String = "lb"
    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .mi }
    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lb }
    private let logger = AppLogger.journal

    var body: some View {
        ZStack {
            Form {
                Section {
                    HStack {
                        DatePicker("Day", selection: $day, displayedComponents: .date)
                            .datePickerStyle(.compact)
                        Spacer()
                        Button("Today") {
                            day = Date().dayOnly
                            logger.notice("Journal day reset to today")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Section("Today’s Summary") {
                    let items = summaryEntries(for: day)
                    if items.isEmpty {
                        Text("No sets/sessions logged.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(items, id: \.self) { line in
                            Label(line, systemImage: "checkmark.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .foregroundStyle(.primary)
                        }
                    }
                    if let w = latestWeight(for: day) {
                        let disp = fromKilograms(w.kg, to: weightUnit)
                        HStack {
                            Text(String(format: "Weight: %.1f %@ @ %@", disp, weightUnit.label, w.at.formatted(date: .omitted, time: .shortened)))
                                .foregroundStyle(.secondary)
                            if let filename = w.imageFilename {
                                Spacer()
                                Button {
                                    weightMediaPreview = WeightMediaPresentation(filename: filename)
                                    logger.notice("Viewing weight photo for \(w.at)")
                                } label: {
                                    Image(systemName: "photo")
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("View weight photo")
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: Binding(
                        get: { entry(for: day).text },
                        set: { updateEntryText($0, for: day) }
                    ))
                    .frame(minHeight: 160)
                }

                Section("Photos") {
                    PhotosPicker(selection: $pickedItems, maxSelectionCount: 6, matching: .images) {
                        Label("Add Photos", systemImage: "photo.on.rectangle")
                    }
                    .onChange(of: pickedItems) { newItems in
                        guard !newItems.isEmpty else { return }
                        Task { @MainActor in
                            let journalEntry = entry(for: day)
                            for item in newItems {
                                do {
                                    guard let data = try await item.loadTransferable(type: Data.self) else {
                                        let error = NSError(domain: "JournalView", code: 0, userInfo: [NSLocalizedDescriptionKey: "Selected photo data was empty."])
                                        presentSaveFailure(actionDescription: "add the selected photo", error: error)
                                        logger.error("Photos picker returned empty data.")
                                        continue
                                    }
                                    let filename = try ImageStore.save(data: data)
                                    journalEntry.imageFilenames.append(filename)
                                    if let error = ctx.saveOrRollback(action: "add journal photo", logger: logger) {
                                        ImageStore.delete(filename)
                                        presentSaveFailure(actionDescription: "add the selected photo", error: error)
                                    } else {
                                        logger.notice("Added journal photo \(filename) for \(journalEntry.day)")
                                    }
                                } catch {
                                    logger.error("Failed to import journal photo: \(error.localizedDescription)")
                                    presentSaveFailure(actionDescription: "import the selected photo", error: error)
                                }
                            }
                            pickedItems.removeAll()
                        }
                    }

                    let files = entry(for: day).imageFilenames
                    if files.isEmpty {
                        Text("No photos yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(files, id: \.self) { name in
                                if let ui = ImageStore.load(name) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .clipped()
                                            .cornerRadius(6)
                                        Button {
                                            let journalEntry = entry(for: day)
                                            if let idx = journalEntry.imageFilenames.firstIndex(of: name) {
                                                journalEntry.imageFilenames.remove(at: idx)
                                                ImageStore.delete(name)
                                                if let error = ctx.saveOrRollback(action: "remove journal photo", logger: logger) {
                                                    presentSaveFailure(actionDescription: "remove the photo", error: error)
                                                } else {
                                                    logger.notice("Removed journal photo \(name)")
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill").imageScale(.small)
                                        }
                                        .offset(x: -4, y: 4)
                                    }
                                } else {
                                    Color.gray.frame(width: 90, height: 90).cornerRadius(6)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Swipe left/right to change day
            Color.clear
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 20).onEnded { value in
                    if value.translation.width < -40 {
                        day = day.addingDays(1)
                        logger.notice("Journal day advanced to \(day)")
                    }
                    if value.translation.width >  40 {
                        day = day.addingDays(-1)
                        logger.notice("Journal day moved back to \(day)")
                    }
                })
        }
        .navigationTitle("Journal")
        .alert(item: $errorAlert) { info in
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(item: $weightMediaPreview) { preview in
            WeightMediaViewer(preview: preview)
        }
        .onAppear { _ = entry(for: day) }
        .onChange(of: day) { _ in _ = entry(for: day) }
    }

    private func entry(for day: Date) -> JournalEntry {
        if let e = entries.first(where: { $0.day == day.dayOnly }) { return e }
        let e = JournalEntry(day: day.dayOnly)
        ctx.insert(e)
        if let error = ctx.saveOrRollback(action: "create journal entry", logger: logger) {
            presentSaveFailure(actionDescription: "create a journal entry", error: error)
        } else {
            logger.notice("Created journal entry for \(day.dayOnly)")
        }
        return e
    }

    private func latestWeight(for day: Date) -> WeightEntry? {
        let dayWeights = weights.filter { Calendar.current.isDate($0.at, inSameDayAs: day) }
        return dayWeights.sorted(by: { $0.at > $1.at }).first
    }

    private func summaryLine(for day: Date) -> String {
        let items = summaryEntries(for: day)
        return items.joined(separator: "   ")
    }

    private func summaryEntries(for day: Date) -> [String] {
        var results: [String] = []
        let dayOnly = day.dayOnly

        let daySets = sets.filter { $0.date == dayOnly }
        let strengthGroups = Dictionary(grouping: daySets, by: { $0.exercise.name })
        for (name, group) in strengthGroups.sorted(by: { $0.key < $1.key }) {
            let total = group.reduce(0) { $0 + $1.reps }
            let best = group.map(\.reps).max() ?? 0
            if total > 0 {
                var line = "\(name): \(total) reps"
                if best > 0 { line += " (best \(best))" }
                results.append(line)
            }
        }

        let daySessions = sessions.filter { $0.date == dayOnly }
        let cardioGroups = Dictionary(grouping: daySessions, by: { $0.exercise.name })
        for (name, group) in cardioGroups.sorted(by: { $0.key < $1.key }) {
            let distanceKm = group.compactMap(\.distanceKm).reduce(0, +)
            let duration = group.reduce(0) { $0 + $1.durationSec }
            if distanceKm > 0 {
                let distance = fromKilometers(distanceKm, to: distanceUnit)
                let durationNote = duration > 0 ? " in \(formatDuration(duration))" : ""
                results.append(String(format: "%@: %.2f %@%@", name, distance, distanceUnit.label, durationNote))
            } else if duration > 0 {
                results.append("\(name): \(formatDuration(duration))")
            }
        }

        return results
    }

    private func updateEntryText(_ text: String, for day: Date) {
        let journalEntry = entry(for: day)
        journalEntry.text = text
        if let error = ctx.saveOrRollback(action: "update journal text", logger: logger) {
            presentSaveFailure(actionDescription: "update the journal entry", error: error)
        } else {
            logger.debug("Updated journal entry text for \(journalEntry.day)")
        }
    }

    private func presentSaveFailure(actionDescription: String, error: Error) {
        errorAlert = UserFacingError(
            title: "Save Failed",
            message: "Unable to \(actionDescription). \(error.localizedDescription)"
        )
    }
}

private struct WeightMediaPresentation: Identifiable {
    let id = UUID()
    let filename: String
}

private struct WeightMediaViewer: View {
    let preview: WeightMediaPresentation

    var body: some View {
        NavigationStack {
            Group {
                if let image = ImageStore.load(preview.filename) {
                    ScrollView([.vertical, .horizontal], showsIndicators: true) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text("Unable to load photo.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Weight Photo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
