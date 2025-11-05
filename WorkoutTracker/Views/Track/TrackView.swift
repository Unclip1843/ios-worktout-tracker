import SwiftUI
import SwiftData
import OSLog
import AVKit
import UniformTypeIdentifiers

struct TrackView: View {
    @Environment(\.modelContext) private var ctx

    @Query(sort: \TrackableItem.sortOrder) private var trackables: [TrackableItem]
    @Query(sort: \Exercise.createdAt) private var exercises: [Exercise]
    @Query(sort: \StrengthSet.createdAt, order: .reverse) private var allSets: [StrengthSet]
    @Query(sort: \CardioSession.createdAt, order: .reverse) private var allSessions: [CardioSession]
    @Query(sort: \WeightEntry.at, order: .reverse) private var weightEntries: [WeightEntry]
    @Query(sort: \TrackableLog.loggedAt, order: .reverse) private var trackableLogs: [TrackableLog]

    @StateObject private var viewModel = TrackScreenViewModel()
    @State private var trackableOrder: [TrackableItem] = []
    @State private var draggingTrackable: TrackableItem?
    @State private var showAddTracking = false
    @State private var showQuickWeight = false
    @State private var showSettings = false
    @State private var showDayPicker = false
    @State private var showFilterSheet = false
    @State private var strengthSheetExercise: Exercise?
    @State private var cardioSheetExercise: Exercise?
    @State private var editingSet: StrengthSet?
    @State private var editingSession: CardioSession?
    @State private var loggingTrackable: TrackableItem?
    @State private var editingLogContext: LogEditContext?
    @State private var editingWeightEntry: WeightEntry?
    @State private var mediaPreview: StrengthMediaPresentation?
    @State private var errorAlert: UserFacingError?

    @AppStorage("distanceUnit") private var distanceUnitRaw: String = "mi"
    @AppStorage("weightUnit") private var weightUnitRaw: String = "lb"
    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .mi }
    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lb }
    private let logger = AppLogger.track

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if displayedTrackables.isEmpty {
                emptyStateCard
            } else {
                let canReorder = viewModel.filter == .all

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(displayedTrackables, id: \.id) { trackable in
                            if canReorder {
                                trackableCard(for: trackable, canReorder: canReorder)
                                    .onDrop(
                                        of: [UTType.text],
                                        delegate: TrackableReorderDelegate(
                                            target: trackable,
                                            items: $trackableOrder,
                                            dragging: $draggingTrackable,
                                            persist: persistOrder,
                                            isEnabled: canReorder
                                        )
                                    )
                            } else {
                                trackableCard(for: trackable, canReorder: canReorder)
                            }
                        }

                        if canReorder {
                            Color.clear
                                .frame(height: 1)
                                .onDrop(
                                    of: [UTType.text],
                                    delegate: TrackableReorderDelegate(
                                        target: nil,
                                        items: $trackableOrder,
                                        dragging: $draggingTrackable,
                                        persist: persistOrder,
                                        isEnabled: canReorder
                                    )
                                )
                        }
                    }
                    .padding(.vertical, 8)
                }

                tipsCard
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Track")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showDayPicker = true
                    logger.notice("Opening day picker")
                } label: {
                    Label(viewModel.day.formatted(.dateTime.month().day().year()), systemImage: "calendar")
                        .labelStyle(.titleAndIcon)
                }
                .accessibilityIdentifier("day-picker-button")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilterSheet = true
                    logger.notice("Opening track filter sheet")
                } label: {
                    Label(viewModel.filterLabel(using: trackables, exercisesByTrackableID: exerciseByTrackable), systemImage: "line.3.horizontal.decrease.circle")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                }
                .accessibilityIdentifier("filter-sheet-button")
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    showQuickWeight = true
                    logger.notice("Opening quick weight log from toolbar")
                } label: {
                    Label("Log Weight", systemImage: "scalemass")
                }
                .accessibilityIdentifier("log-weight-toolbar-button")

                Spacer()

                Button {
                    showAddTracking = true
                    logger.notice("Opening add tracking sheet")
                } label: {
                    Label("Add Tracking", systemImage: "plus")
                }
                .accessibilityIdentifier("add-tracking-toolbar-button")

                Spacer()

                Button {
                    showSettings = true
                    logger.notice("Opening settings from TrackView")
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .accessibilityIdentifier("settings-toolbar-button")
            }
        }
        .sheet(isPresented: $showAddTracking) {
            AddTrackingSheet { exercise in
                logger.notice("Created exercise \(exercise.name, privacy: .public) of type \(exercise.kind.rawValue, privacy: .public)")
            }
        }
        .sheet(isPresented: $showQuickWeight) {
            NavigationStack { QuickWeightLogView() }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
        .sheet(item: $strengthSheetExercise) { exercise in
            AddSetSheet(exercise: exercise, day: viewModel.day)
        }
        .sheet(item: $cardioSheetExercise) { exercise in
            AddCardioSheet(exercise: exercise, day: viewModel.day)
        }
        .sheet(item: $editingSet) { set in
            EditSetSheet(set: set)
        }
        .sheet(item: $editingSession) { session in
            EditCardioSheet(session: session)
        }
        .sheet(item: $loggingTrackable) { trackable in
            LogTrackableEntrySheet(trackable: trackable)
        }
        .sheet(item: $editingLogContext) { context in
            LogTrackableEntrySheet(trackable: context.trackable, existingLog: context.log)
        }
        .sheet(item: $editingWeightEntry) { entry in
            NavigationStack { QuickWeightLogView(entry: entry) }
        }
        .sheet(item: $mediaPreview) { preview in
            SetMediaViewer(preview: preview)
        }
        .sheet(isPresented: $showDayPicker) { dayPickerSheet }
        .sheet(isPresented: $showFilterSheet) { filterSheet }
        .alert(item: $errorAlert) { context in
            Alert(
                title: Text(context.title),
                message: Text(context.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < -40 {
                        viewModel.day = viewModel.day.addingDays(1)
                        logger.notice("Day advanced to \(viewModel.day, privacy: .public)")
                    } else if value.translation.width > 40 {
                        viewModel.day = viewModel.day.addingDays(-1)
                        logger.notice("Day moved back to \(viewModel.day, privacy: .public)")
                    }
                }
        )
        .onAppear {
            viewModel.ensureDefaultTrackablesIfNeeded(in: ctx, existing: trackables)
            syncTrackables()
        }
        .onChange(of: trackables) { _ in syncTrackables() }
    }
}

// MARK: - UI Sections
private extension TrackView {
    var filterBar: some View {
        HStack(spacing: 12) {
            DatePicker(
                "Day",
                selection: Binding(
                    get: { viewModel.day },
                    set: { viewModel.day = $0.dayOnly }
                ),
                displayedComponents: .date
            )
                .datePickerStyle(.compact)

            Menu {
                Button {
                    viewModel.setFilterAll()
                    logger.notice("Filter cleared to show all trackers")
                } label: {
                    Label("All Trackers", systemImage: "circle.grid.2x2")
                }
                ForEach(trackableFilterSections, id: \.title) { section in
                    Section(header: Text(section.title)) {
                        Button {
                            viewModel.setFilter(kind: section.kind)
                            logger.notice("Filter set to category \(section.title, privacy: .public)")
                        } label: {
                            Label("All \(section.title)", systemImage: section.iconName)
                        }

                        ForEach(section.items) { item in
                            Button {
                                viewModel.setFilter(trackableID: item.id)
                                logger.notice("Filter set to tracker \(item.name, privacy: .public)")
                            } label: {
                                Label(filterLabel(for: item), systemImage: item.kind.iconName)
                            }
                        }
                    }
                }
            } label: {
                Label(selectedFilterLabel, systemImage: "line.3.horizontal.decrease.circle")
                    .labelStyle(.titleAndIcon)
                    .padding(.horizontal, 8)
            }

            Spacer()

            Button("Today") {
                viewModel.resetToToday()
                logger.notice("Day reset to today")
            }
            .buttonStyle(.bordered)
        }
    }

    var emptyStateCard: some View {
        VStack(spacing: 12) {
            Text("No trackers yet.")
                .font(.headline)
                .foregroundStyle(.secondary)

            Button {
                showAddTracking = true
            } label: {
                Label("Add Tracking", systemImage: "plus.circle.fill")
                    .font(.title3.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)

            Text("Tip: Start with an exercise, hydration log, or body weight. Swipe left/right on the background to move between days.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
    }

    var tipsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.orange)
                Text("Tip")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text("Tap totals to explore charts, or long-press entries for quick delete.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.tertiarySystemBackground)))
    }

    @ViewBuilder
    func trackableCard(for trackable: TrackableItem, canReorder: Bool) -> some View {
        let isDragging = draggingTrackable?.id == trackable.id
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(trackable.name)
                        .font(.headline)

                    headerMetadata(for: trackable)
                }

                Spacer()

                dragHandle(for: trackable, isDragging: isDragging, isEnabled: canReorder)
            }

            switch trackable.kind {
            case .strengthExercise:
                if let exercise = exerciseByTrackable[trackable.id] {
                    strengthContent(trackable: trackable, exercise: exercise)
                } else {
                    missingLinkText
                }
            case .cardioExercise:
                if let exercise = exerciseByTrackable[trackable.id] {
                    cardioContent(trackable: trackable, exercise: exercise)
                } else {
                    missingLinkText
                }
            case .weight:
                weightContent(trackable)
            case .meal, .custom:
                generalContent(trackable)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isDragging ? Color.accentColor : Color.clear, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .contextMenu {
            switch trackable.kind {
            case .strengthExercise:
                if let exercise = exerciseByTrackable[trackable.id] {
                    Button("Add Set") { strengthSheetExercise = exercise }
                    Button("Log Entry") { loggingTrackable = trackable }
                }
            case .cardioExercise:
                if let exercise = exerciseByTrackable[trackable.id] {
                    Button("Add Session") { cardioSheetExercise = exercise }
                    Button("Log Entry") { loggingTrackable = trackable }
                }
            case .weight:
                Button("Log Weight") { showQuickWeight = true }
            case .meal, .custom:
                Button("Log Entry") { loggingTrackable = trackable }
            }

            Button(role: .destructive) {
                deleteTrackable(trackable)
            } label: {
                Label("Delete Tracker", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    func headerMetadata(for trackable: TrackableItem) -> some View {
        switch trackable.kind {
        case .strengthExercise, .cardioExercise:
            if !trackable.defaultMuscleGroups.isEmpty {
                Text(trackable.defaultMuscleGroups.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .meal, .custom, .weight:
            if !trackable.defaultTags.isEmpty {
                Text(trackable.defaultTags.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        if let notes = trackable.notes, !notes.isEmpty {
            Text(notes)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    var missingLinkText: some View {
        Text("Linked exercise missing.")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    func dragHandle(for trackable: TrackableItem, isDragging: Bool, isEnabled: Bool) -> some View {
        let base = Image(systemName: "line.3.horizontal")
            .font(.system(size: 16, weight: .semibold))
            .padding(8)
            .background(isDragging ? Color.accentColor.opacity(0.2) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(isEnabled ? 1 : 0.35)

        return Group {
            if isEnabled {
                base.onDrag {
                    draggingTrackable = trackable
                    return NSItemProvider(object: trackable.id.uuidString as NSString)
                }
            } else {
                base
            }
        }
    }
}

// MARK: - Strength & Cardio
private extension TrackView {
    func strengthContent(trackable: TrackableItem, exercise: Exercise) -> some View {
        let daySets = setsFor(exercise: exercise, on: viewModel.day)
        let totalReps = daySets.reduce(0) { $0 + $1.reps }
        let bestDailyTotal = bestDailyTotalReps(for: exercise)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today: \(totalReps) reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if totalReps > 0 && totalReps == bestDailyTotal {
                    Text("🎉 PR")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }

            if daySets.isEmpty {
                Text("No sets logged for this day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(daySets) { set in
                        strengthSetRow(set)
                    }
                }
            }

            Button {
                strengthSheetExercise = exercise
                logger.notice("Preparing to add strength set for \(trackable.name, privacy: .public)")
            } label: {
            Label("Add Set", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    func strengthSetRow(_ set: StrengthSet) -> some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(set.reps) reps")
                        .font(.body.weight(.semibold))
                    if let weight = set.weight {
                        Text("@ \(formatWeight(weight))")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
                if let note = set.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(set.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.tertiary)

            if isSetPR(set) {
                Text("PR")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }

            if let filename = set.mediaFilename {
                Button {
                    mediaPreview = StrengthMediaPresentation(filename: filename, isVideo: set.mediaIsVideo)
                } label: {
                    Image(systemName: set.mediaIsVideo ? "video.fill" : "photo.fill")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemBackground)))
        .onTapGesture {
            editingSet = set
            logger.debug("Editing strength set \(set.id, privacy: .public)")
        }
        .contextMenu {
            Button("Edit") {
                editingSet = set
            }
            Button("Delete", role: .destructive) {
                deleteStrengthSet(set)
            }
        }
    }

    func deleteStrengthSet(_ set: StrengthSet) {
        let mediaFilename = set.mediaFilename
        ctx.delete(set)
        if let error = ctx.saveOrRollback(action: "delete strength set", logger: logger) {
            presentSaveFailure(actionDescription: "delete strength set", error: error)
            if let filename = mediaFilename {
                ImageStore.delete(filename)
            }
        } else {
            logger.notice("Deleted strength set \(set.id, privacy: .public)")
        }
    }

    func cardioContent(trackable: TrackableItem, exercise: Exercise) -> some View {
        let daySessions = sessionsFor(exercise: exercise, on: viewModel.day)
        let totalSeconds = daySessions.reduce(0) { $0 + $1.durationSec }
        let totalKm = daySessions.compactMap(\.distanceKm).reduce(0, +)
        let displayDistance = fromKilometers(totalKm, to: distanceUnit)
        let bestDistanceKm = bestDailyTotalDistanceKm(for: exercise)
        let hasDistance = totalKm > 0
        let isPR = hasDistance && abs(totalKm - bestDistanceKm) < 0.001
        let distanceText = String(format: "%.2f", displayDistance)

        let todaySummary: String = {
            if hasDistance {
                if let pace = paceString(totalSeconds: totalSeconds, kilometers: totalKm) {
                    return "Today: \(distanceText) \(distanceUnit.label) (\(pace))"
                } else {
                    return "Today: \(distanceText) \(distanceUnit.label)"
                }
            } else if totalSeconds > 0 {
                return "Today: \(formatDuration(totalSeconds))"
            } else {
                return "Today: –"
            }
        }()

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(todaySummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if isPR {
                    Text("🎉 PR")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }

            if daySessions.isEmpty {
                Text("No sessions logged for this day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(daySessions) { session in
                        cardioSessionRow(session)
                    }
                }
            }

            Button {
                cardioSheetExercise = exercise
                logger.notice("Preparing to add cardio session for \(trackable.name, privacy: .public)")
            } label: {
                Label("Add Session", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    func cardioSessionRow(_ session: CardioSession) -> some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                if let km = session.distanceKm {
                    let distance = fromKilometers(km, to: distanceUnit)
                    Text(String(format: "%.2f %@", distance, distanceUnit.label))
                        .font(.body.weight(.semibold))
                    if let pace = paceString(totalSeconds: session.durationSec, kilometers: km) {
                        Text(pace)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(formatDuration(session.durationSec))
                        .font(.body.weight(.semibold))
                }

                if let note = session.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(session.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemBackground)))
        .onTapGesture {
            editingSession = session
            logger.debug("Editing cardio session \(session.id, privacy: .public)")
        }
        .contextMenu {
            Button("Edit") {
                editingSession = session
            }
            Button("Delete", role: .destructive) {
                deleteCardioSession(session)
            }
        }
    }

    func deleteCardioSession(_ session: CardioSession) {
        ctx.delete(session)
        if let error = ctx.saveOrRollback(action: "delete cardio session", logger: logger) {
            presentSaveFailure(actionDescription: "delete cardio session", error: error)
        } else {
            logger.notice("Deleted cardio session \(session.id, privacy: .public)")
        }
    }
}

// MARK: - General Trackables
private extension TrackView {
    func weightContent(_ trackable: TrackableItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let latest = latestWeightEntry(for: trackable) {
                let converted = fromKilograms(latest.kg, to: weightUnit)
                Button {
                    editingWeightEntry = latest
                } label: {
                    Text("Latest: \(formatWeight(converted)) \(weightUnit.label) • \(latest.at.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Text("No weight logged yet.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            let history = recentWeightEntries(for: trackable)
            if history.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(Array(history.dropFirst()), id: \.id) { entry in
                        Button {
                            editingWeightEntry = entry
                        } label: {
                            let converted = fromKilograms(entry.kg, to: weightUnit)
                            Text("\(entry.at.formatted(date: .abbreviated, time: .shortened)) – \(formatWeight(converted)) \(weightUnit.label)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }

    Button {
        showQuickWeight = true
        logger.notice("Opening quick weight log from card for \(trackable.name, privacy: .public)")
    } label: {
        Label("Log Weight", systemImage: "scalemass")
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
}
    }

    func generalContent(_ trackable: TrackableItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let latest = latestLog(for: trackable) {
                Button {
                    editingLogContext = LogEditContext(trackable: trackable, log: latest)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(latest.loggedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let quantity = latest.quantity {
                            let unit = latest.unit.map { " \($0)" } ?? ""
                            Text("Quantity: \(formatDecimal(quantity))\(unit)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let note = latest.note, !note.isEmpty {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else if let notes = trackable.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text("No logs yet.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            let history = recentLogs(for: trackable)
            if history.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(Array(history.dropFirst()), id: \.id) { log in
                        Button {
                            editingLogContext = LogEditContext(trackable: trackable, log: log)
                        } label: {
                            HStack(spacing: 6) {
                                Text(log.loggedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                if let quantity = log.quantity {
                                    Text(formatDecimal(quantity))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                if let unit = log.unit {
                                    Text(unit)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }

    Button {
        loggingTrackable = trackable
        logger.notice("Preparing to log entry for \(trackable.name, privacy: .public)")
    } label: {
        Label("Log Entry", systemImage: "plus.circle")
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
}
    }
}

// MARK: - Data helpers
private extension TrackView {
    var exerciseByTrackable: [UUID: Exercise] {
        exercises.reduce(into: [UUID: Exercise]()) { result, exercise in
            if let trackableID = exercise.trackableID {
                result[trackableID] = exercise
            }
        }
    }

    @ViewBuilder
    var dayPickerSheet: some View {
        DayPickerSheet(selectedDay: Binding(
            get: { viewModel.day },
            set: { viewModel.day = $0.dayOnly }
        ))
    }

    @ViewBuilder
    var filterSheet: some View {
        TrackFilterSheet(
            viewModel: viewModel,
            sections: trackableFilterSections,
            exercisesByTrackable: exerciseByTrackable
        )
    }

    var displayedTrackables: [TrackableItem] {
        viewModel.filteredTrackables(from: trackableOrder)
    }

    var selectedFilterLabel: String {
        viewModel.filterLabel(using: trackables, exercisesByTrackableID: exerciseByTrackable)
    }

    var trackableFilterSections: [TrackFilterSection] {
        viewModel.sections(for: trackables)
    }

    func filterLabel(for trackable: TrackableItem) -> String {
        if let exercise = exerciseByTrackable[trackable.id], !exercise.isActive {
            return "\(trackable.name) (Archived)"
        }
        return trackable.name
    }

    func setsFor(exercise: Exercise, on day: Date) -> [StrengthSet] {
        allSets
            .filter { $0.exercise.id == exercise.id && $0.date == day.dayOnly }
            .sorted(by: { $0.createdAt < $1.createdAt })
    }

    func sessionsFor(exercise: Exercise, on day: Date) -> [CardioSession] {
        allSessions
            .filter { $0.exercise.id == exercise.id && $0.date == day.dayOnly }
            .sorted(by: { $0.createdAt < $1.createdAt })
    }

    func isSetPR(_ set: StrengthSet) -> Bool {
        let sets = allSets.filter { $0.exercise.id == set.exercise.id }
        let maxReps = sets.map(\.reps).max() ?? 0
        return maxReps > 0 && set.reps == maxReps
    }

    func bestDailyTotalReps(for exercise: Exercise) -> Int {
        let grouped = Dictionary(grouping: allSets.filter { $0.exercise.id == exercise.id }, by: { $0.date })
        return grouped.values.map { $0.reduce(0) { $0 + $1.reps } }.max() ?? 0
    }

    func bestDailyTotalDistanceKm(for exercise: Exercise) -> Double {
        let grouped = Dictionary(grouping: allSessions.filter { $0.exercise.id == exercise.id }, by: { $0.date })
        return grouped.values.map { $0.compactMap(\.distanceKm).reduce(0, +) }.max() ?? 0
    }

    func paceString(totalSeconds: Int, kilometers: Double?) -> String? {
        guard let kilometers, kilometers > 0, totalSeconds > 0 else { return nil }
        let unitDistance = fromKilometers(kilometers, to: distanceUnit)
        guard unitDistance > 0 else { return nil }
        let paceSeconds = Double(totalSeconds) / unitDistance
        guard paceSeconds.isFinite else { return nil }
        let minutesPart = Int(paceSeconds) / 60
        let secondsPart = Int(paceSeconds) % 60
        return String(format: "%d:%02d per %@", minutesPart, secondsPart, distanceUnit == .mi ? "mile" : "km")
    }

    func recentLogs(for trackable: TrackableItem, limit: Int = 3) -> [TrackableLog] {
        Array(trackableLogs.filter { $0.trackableID == trackable.id }.prefix(limit))
    }

    func latestLog(for trackable: TrackableItem) -> TrackableLog? {
        trackableLogs.first { $0.trackableID == trackable.id }
    }

    func recentWeightEntries(for trackable: TrackableItem, limit: Int = 3) -> [WeightEntry] {
        Array(weightEntries.filter { $0.trackableID == trackable.id }.prefix(limit))
    }

    func latestWeightEntry(for trackable: TrackableItem) -> WeightEntry? {
        weightEntries.first { $0.trackableID == trackable.id }
    }

    func persistOrder(_ items: [TrackableItem]) {
        trackableOrder = items
        let now = Date()
        for (index, item) in items.enumerated() {
            item.sortOrder = Double(index)
            item.updatedAt = now
        }
        _ = ctx.saveOrRollback(action: "reorder trackables", logger: logger)
    }

    func syncTrackables() {
        let sorted = trackables.sorted { lhs, rhs in
            if abs(lhs.sortOrder - rhs.sortOrder) < 0.0001 {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.sortOrder < rhs.sortOrder
        }
        trackableOrder = sorted

        viewModel.syncFilterIfNeeded(with: trackables)
    }

    func deleteTrackable(_ trackable: TrackableItem) {
        logger.notice("Deleting trackable \(trackable.name, privacy: .public)")
        let trackableID = trackable.id

        trackableLogs
            .filter { $0.trackableID == trackableID }
            .forEach { ctx.delete($0) }

        weightEntries
            .filter { $0.trackableID == trackableID }
            .forEach { $0.trackableID = nil }

        if let linkedExercise = exercises.first(where: { $0.trackableID == trackableID }) {
            allSets
                .filter { $0.exercise.id == linkedExercise.id }
                .forEach { ctx.delete($0) }
            allSessions
                .filter { $0.exercise.id == linkedExercise.id }
                .forEach { ctx.delete($0) }
            ctx.delete(linkedExercise)
        }

        ctx.delete(trackable)

        if let error = ctx.saveOrRollback(action: "delete trackable item", logger: logger) {
            presentSaveFailure(actionDescription: "delete tracker", error: error)
        } else {
            syncTrackables()
        }
    }

    func presentSaveFailure(actionDescription: String, error: Error) {
        errorAlert = UserFacingError(
            title: "Save Failed",
            message: "Unable to \(actionDescription). \(error.localizedDescription)"
        )
    }
}

// MARK: - Supporting types
private struct LogEditContext: Identifiable {
    let trackable: TrackableItem
    let log: TrackableLog

    var id: UUID { log.id }
}

struct StrengthMediaPresentation: Identifiable {
    let id = UUID()
    let filename: String
    let isVideo: Bool
}

struct SetMediaViewer: View {
    let preview: StrengthMediaPresentation
    @State private var player: AVPlayer?

    var body: some View {
        NavigationStack {
            Group {
                if preview.isVideo {
                    if let player {
                        VideoPlayer(player: player)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        ProgressView()
                    }
                } else if let image = ImageStore.load(preview.filename) {
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
                        Text("Unable to load media.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(preview.isVideo ? "Video" : "Photo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if preview.isVideo {
                player = AVPlayer(url: ImageStore.fileURL(for: preview.filename))
                player?.play()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

// MARK: - Drag & drop reorder
private struct TrackableReorderDelegate: DropDelegate {
    let target: TrackableItem?
    @Binding var items: [TrackableItem]
    @Binding var dragging: TrackableItem?
    let persist: ([TrackableItem]) -> Void
    let isEnabled: Bool

    func dropEntered(info: DropInfo) {
        guard isEnabled, let dragging else { return }
        guard let fromIndex = items.firstIndex(where: { $0.id == dragging.id }) else { return }

        if let target,
           let toIndex = items.firstIndex(where: { $0.id == target.id }),
           dragging.id != target.id {
            withAnimation(.default) {
                items.move(
                    fromOffsets: IndexSet(integer: fromIndex),
                    toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
                )
            }
        } else if target == nil {
            withAnimation(.default) {
                items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: items.count)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard isEnabled else { return nil }
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard isEnabled else { return false }
        dragging = nil
        persist(items)
        return true
    }

    func dropExited(info: DropInfo) {
        // Keep current ordering; nothing to do.
    }

    func dropEnded(info: DropInfo) {
        if isEnabled {
            dragging = nil
        }
    }
}
