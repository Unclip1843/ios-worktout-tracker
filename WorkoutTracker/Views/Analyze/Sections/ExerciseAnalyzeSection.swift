import SwiftUI
import Charts

struct ExerciseAnalyzeSection: View {
    let exercises: [Exercise]
    let strengthSets: [StrengthSet]
    let cardioSessions: [CardioSession]
    let distanceUnit: DistanceUnit
    let range: AnalyzeRange

    @Binding var selectedExercise: Exercise?

    private var orderedExercises: [Exercise] {
        exercises.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            exercisePicker

            Group {
                if let exercise = selectedExercise {
                    switch exercise.kind {
                    case .strength:
                        StrengthAnalyzeContent(
                            exercise: exercise,
                            sets: strengthSets.filter { $0.exercise.id == exercise.id },
                            range: range
                        )
                        .transition(.opacity)
                    case .cardio:
                        CardioAnalyzeContent(
                            exercise: exercise,
                            sessions: cardioSessions.filter { $0.exercise.id == exercise.id },
                            range: range,
                            distanceUnit: distanceUnit
                        )
                        .transition(.opacity)
                    }
                } else {
                    Text("Pick an exercise to see charts.")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
        }
    }
        }
        .onAppear {
            if selectedExercise == nil {
                selectedExercise = orderedExercises.first(where: \.isActive) ?? orderedExercises.first
            }
        }
    }

    private var exercisePicker: some View {
        HStack {
            Picker("Exercise", selection: $selectedExercise) {
                ForEach(orderedExercises) { exercise in
                    Text(exercise.isActive ? exercise.name : "\(exercise.name) (Archived)")
                        .tag(Optional(exercise))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            Spacer()
        }
        .padding(.horizontal)
    }
}

private struct StrengthAnalyzeContent: View {
    let exercise: Exercise
    let sets: [StrengthSet]
    let range: AnalyzeRange

    private var groupedByDay: [(day: Date, total: Int)] {
        Dictionary(grouping: sets, by: \.date)
            .map { (day: $0.key, total: $0.value.reduce(0) { $0 + $1.reps }) }
            .sorted { $0.day < $1.day }
    }

    private var filtered: [(day: Date, total: Int)] {
        let cutoff = range.cutoffDate()
        return groupedByDay.filter { $0.day >= cutoff }
    }

    var body: some View {
        VStack(spacing: 16) {
            StrengthSummaryView(exercise: exercise, sets: sets)
                .padding(.horizontal)

            if filtered.isEmpty {
                SummaryCard("Keep logging", value: "No data yet", footnote: "Track a set to see trends here.")
                    .padding(.horizontal)
            } else {
                Chart(filtered, id: \.day) {
                    LineMark(x: .value("Day", $0.day), y: .value("Total Reps", $0.total))
                    PointMark(x: .value("Day", $0.day), y: .value("Total Reps", $0.total))
                }
                .frame(height: 260)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Best Single Set: \(sets.map(\.reps).max() ?? 0)")
                    if let bestDay = filtered.max(by: { $0.total < $1.total }) {
                        Text("Best Day: \(bestDay.total) on \(bestDay.day.formatted(date: .abbreviated, time: .omitted))")
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct CardioAnalyzeContent: View {
    let exercise: Exercise
    let sessions: [CardioSession]
    let range: AnalyzeRange
    let distanceUnit: DistanceUnit

    private var groupedByDayKm: [(day: Date, totalKm: Double)] {
        Dictionary(grouping: sessions, by: \.date)
            .map { (day: $0.key, totalKm: $0.value.compactMap(\.distanceKm).reduce(0, +)) }
            .sorted { $0.day < $1.day }
    }

    private var filtered: [(day: Date, totalKm: Double)] {
        let cutoff = range.cutoffDate()
        return groupedByDayKm.filter { $0.day >= cutoff }
    }

    var body: some View {
        VStack(spacing: 16) {
            CardioSummaryView(exercise: exercise,
                              sessions: sessions,
                              distanceUnit: distanceUnit)
                .padding(.horizontal)

            if filtered.isEmpty {
                SummaryCard("Log a session", value: "No cardio yet", footnote: "Add a run, ride, or row to see insights.")
                    .padding(.horizontal)
            } else {
                let converted = filtered.map { (day: $0.day, total: fromKilometers($0.totalKm, to: distanceUnit)) }

                Chart(converted, id: \.day) {
                    LineMark(x: .value("Day", $0.day), y: .value("Distance", $0.total))
                    PointMark(x: .value("Day", $0.day), y: .value("Distance", $0.total))
                }
                .frame(height: 260)
                .padding(.horizontal)

                let bestSessionKm = sessions.compactMap(\.distanceKm).max() ?? 0
                let bestDayKm = filtered.max(by: { $0.totalKm < $1.totalKm })?.totalKm ?? 0

                VStack(alignment: .leading, spacing: 6) {
                    Text(String(format: "Best Session: %.2f %@", fromKilometers(bestSessionKm, to: distanceUnit), distanceUnit.label))
                    Text(String(format: "Best Day: %.2f %@", fromKilometers(bestDayKm, to: distanceUnit), distanceUnit.label))
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Summary Helpers

private struct StrengthSummaryView: View {
    let exercise: Exercise
    let sets: [StrengthSet]

    private var lastSet: StrengthSet? {
        sets.max(by: { $0.createdAt < $1.createdAt })
    }

    var body: some View {
        if sets.isEmpty {
            SummaryCard("Keep logging", value: "No data yet", footnote: "Track a set to see trends here.")
        } else {
            let sevenDayCutoff = Date().addingTimeInterval(-7 * 86_400).dayOnly
            let weekSets = sets.filter { $0.date >= sevenDayCutoff }
            let weekTotal = weekSets.reduce(0) { $0 + $1.reps }
            let workouts = Set(weekSets.map(\.date)).count
            let avgReps = workouts > 0 ? weekTotal / workouts : 0
            let bestSingle = sets.map(\.reps).max() ?? 0
            let lastPerformed = lastSet?.createdAt.formatted(date: .abbreviated, time: .shortened) ?? "—"

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                SummaryCard("Last session", value: lastPerformed)
                SummaryCard("7-day volume", value: "\(weekTotal) reps", footnote: workouts > 0 ? "\(workouts) sessions" : "No sessions yet")
                SummaryCard("Avg per session", value: "\(avgReps) reps", footnote: "past 7 days")
                SummaryCard("Best set", value: "\(bestSingle) reps")
            }
        }
    }
}

private struct CardioSummaryView: View {
    let exercise: Exercise
    let sessions: [CardioSession]
    let distanceUnit: DistanceUnit

    var body: some View {
        if sessions.isEmpty {
            SummaryCard("Log a session", value: "No cardio yet", footnote: "Add a run, ride, or row to see insights.")
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                SummaryCard("Last session", value: lastSessionSummary)
                SummaryCard("7-day distance",
                            value: String(format: "%.2f %@", fromKilometers(recentDistanceKm, to: distanceUnit), distanceUnit.label),
                            footnote: recentPaceText ?? "—")
                if let fastest = fastestPaceText {
                    SummaryCard("Fastest pace", value: fastest)
                }
            }
        }
    }

    private var sevenDayCutoff: Date {
        Date().addingTimeInterval(-7 * 86_400).dayOnly
    }

    private var recentSessions: [CardioSession] {
        sessions.filter { $0.date >= sevenDayCutoff }
    }

    private var recentDistanceKm: Double {
        recentSessions.compactMap(\.distanceKm).reduce(0, +)
    }

    private var recentDuration: Int {
        recentSessions.reduce(0) { $0 + $1.durationSec }
    }

    private var recentPaceText: String? {
        paceString(distanceKm: recentDistanceKm, durationSec: recentDuration)
    }

    private var fastestPaceText: String? {
        guard let best = sessions.compactMap({ session -> (Double, Int)? in
            guard let km = session.distanceKm else { return nil }
            return (km, session.durationSec)
        }).min(by: { paceSeconds(distanceKm: $0.0, durationSec: $0.1) < paceSeconds(distanceKm: $1.0, durationSec: $1.1) }) else {
            return nil
        }
        return paceString(distanceKm: best.0, durationSec: best.1)
    }

    private var lastSessionSummary: String {
        guard let session = sessions.max(by: { $0.createdAt < $1.createdAt }) else { return "—" }
        let dateText = session.createdAt.formatted(date: .abbreviated, time: .shortened)
        if let km = session.distanceKm {
            let distance = String(format: "%.2f %@", fromKilometers(km, to: distanceUnit), distanceUnit.label)
            let paceSuffix = paceString(distanceKm: km, durationSec: session.durationSec).map { " (\($0))" } ?? ""
            return "\(dateText) • \(distance)\(paceSuffix)"
        } else if session.durationSec > 0 {
            return "\(dateText) • \(formatDuration(session.durationSec))"
        } else {
            return dateText
        }
    }

    private func paceString(distanceKm: Double, durationSec: Int) -> String? {
        guard distanceKm > 0, durationSec > 0 else { return nil }
        let unitDistance = fromKilometers(distanceKm, to: distanceUnit)
        guard unitDistance > 0 else { return nil }
        let paceSeconds = Double(durationSec) / unitDistance
        guard paceSeconds.isFinite else { return nil }
        let minutesPart = Int(paceSeconds) / 60
        let secondsPart = Int(paceSeconds) % 60
        return String(format: "%d:%02d per %@", minutesPart, secondsPart, distanceUnit == .mi ? "mile" : "km")
    }

    private func paceSeconds(distanceKm: Double, durationSec: Int) -> Double {
        guard distanceKm > 0, durationSec > 0 else { return Double.greatestFiniteMagnitude }
        let unitDistance = fromKilometers(distanceKm, to: distanceUnit)
        guard unitDistance > 0 else { return Double.greatestFiniteMagnitude }
        return Double(durationSec) / unitDistance
    }
}
