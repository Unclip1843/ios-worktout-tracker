import SwiftUI
import SwiftData

struct PRsView: View {
    @Query(sort: \Exercise.createdAt) private var exercises: [Exercise]
    @Query(sort: \StrengthSet.createdAt, order: .reverse) private var sets: [StrengthSet]
    @Query(sort: \CardioSession.createdAt, order: .reverse) private var sessions: [CardioSession]

    @AppStorage("distanceUnit") private var distanceUnitRaw: String = "mi"
    @AppStorage("weightUnit") private var weightUnitRaw: String = "lb"
    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .mi }
    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lb }

    var body: some View {
        List {
            Section("Strength") {
                if strengthExercises.isEmpty {
                    SummaryCard("Log Strength", value: "No strength PRs yet", footnote: "Track sets to begin surfacing personal records.")
                } else {
                    ForEach(strengthExercises, id: \.id) { exercise in
                        StrengthPRRow(exercise: exercise,
                                      sets: sets.filter { $0.exercise.id == exercise.id },
                                      unit: weightUnit)
                    }
                }
            }

            Section("Cardio") {
                if cardioExercises.isEmpty {
                    SummaryCard("Log Cardio", value: "No cardio PRs yet", footnote: "Track runs, rides, or rows to view pace and distance records.")
                } else {
                    ForEach(cardioExercises, id: \.id) { exercise in
                        CardioPRRow(exercise: exercise,
                                    sessions: sessions.filter { $0.exercise.id == exercise.id },
                                    unit: distanceUnit)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("PRs")
    }

    private var strengthExercises: [Exercise] { exercises.filter { $0.kind == .strength } }
    private var cardioExercises: [Exercise] { exercises.filter { $0.kind == .cardio } }
}

private struct StrengthPRRow: View {
    let exercise: Exercise
    let sets: [StrengthSet]
    let unit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.headline)
            if sets.isEmpty {
                SummaryCard("Keep logging", value: "No PRs yet", footnote: "Track a set to surface PRs.")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    if let maxReps = sets.max(by: { $0.reps < $1.reps }) {
                        SummaryCard("Max reps",
                                    value: "\(maxReps.reps) reps",
                                    footnote: maxReps.date.formatted(.dateTime.month(.abbreviated).day()))
                    }
                    if let heaviest = sets.filter({ $0.weight != nil }).max(by: { ($0.weight ?? 0) < ($1.weight ?? 0) }) {
                        let converted = unit == .kg ? (heaviest.weight ?? 0) : fromKilograms(heaviest.weight ?? 0, to: .lb)
                        SummaryCard("Heaviest set",
                                    value: String(format: "%.1f %@", converted, unit.label),
                                    footnote: heaviest.date.formatted(.dateTime.month(.abbreviated).day()))
                    }
                    if let volume = bestVolumeDay(sets) {
                        SummaryCard("Best volume",
                                    value: "\(volume.total) reps",
                                    footnote: volume.date.formatted(.dateTime.month(.abbreviated).day()))
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func bestVolumeDay(_ sets: [StrengthSet]) -> (date: Date, total: Int)? {
        let grouped = Dictionary(grouping: sets, by: { $0.date })
        return grouped
            .map { (date: $0.key, total: $0.value.reduce(0) { $0 + $1.reps }) }
            .max(by: { $0.total < $1.total })
    }
}

private struct CardioPRRow: View {
    let exercise: Exercise
    let sessions: [CardioSession]
    let unit: DistanceUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.headline)
            if sessions.isEmpty {
                SummaryCard("Keep logging", value: "No PRs yet", footnote: "Add a session to surface pace or distance PRs.")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    if let longestDistance = sessions.compactMap({ session -> (CardioSession, Double)? in
                        guard let km = session.distanceKm else { return nil }
                        return (session, km)
                    }).max(by: { $0.1 < $1.1 }) {
                        let converted = fromKilometers(longestDistance.1, to: unit)
                        SummaryCard("Longest distance",
                                    value: String(format: "%.2f %@", converted, unit.label),
                                    footnote: longestDistance.0.date.formatted(.dateTime.month(.abbreviated).day()))
                    }
                    if let longestDuration = sessions.max(by: { $0.durationSec < $1.durationSec }) {
                        SummaryCard("Longest duration",
                                    value: formatDuration(longestDuration.durationSec),
                                    footnote: longestDuration.date.formatted(.dateTime.month(.abbreviated).day()))
                    }
                    if let fastest = fastestPace(sessions, unit: unit) {
                        SummaryCard("Fastest pace",
                                    value: fastest.pace,
                                    footnote: fastest.date.formatted(.dateTime.month(.abbreviated).day()))
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func fastestPace(_ sessions: [CardioSession], unit: DistanceUnit) -> (pace: String, date: Date)? {
        let candidates = sessions.compactMap { session -> (CardioSession, Double)? in
            guard let km = session.distanceKm, km > 0 else { return nil }
            return (session, km)
        }
        guard let best = candidates.min(by: { paceSeconds($0.0.durationSec, $0.1, unit) < paceSeconds($1.0.durationSec, $1.1, unit) }) else {
            return nil
        }
        let seconds = paceSeconds(best.0.durationSec, best.1, unit)
        let minutesPart = Int(seconds) / 60
        let secondsPart = Int(seconds) % 60
        let paceString = String(format: "%d:%02d per %@", minutesPart, secondsPart, unit == .mi ? "mile" : "km")
        return (paceString, best.0.date)
    }

    private func paceSeconds(_ duration: Int, _ kilometers: Double, _ unit: DistanceUnit) -> Double {
        let distance = fromKilometers(kilometers, to: unit)
        guard distance > 0 else { return Double.greatestFiniteMagnitude }
        return Double(duration) / distance
    }
}
