import SwiftUI
import SwiftData

enum AnalyzeMode: String, CaseIterable, Identifiable {
    case exercise
    case weight

    var id: String { rawValue }
}

struct AnalyzeView: View {
    @Query(sort: \Exercise.createdAt) private var exercises: [Exercise]
    @Query(sort: \StrengthSet.date) private var strengthSets: [StrengthSet]
    @Query(sort: \CardioSession.date) private var cardioSessions: [CardioSession]
    @Query(sort: \WeightEntry.at) private var weightEntries: [WeightEntry]

    @State private var mode: AnalyzeMode = .exercise
    @State private var range: AnalyzeRange = .ninety
    @State private var selectedExercise: Exercise?

    @AppStorage("distanceUnit") private var distanceUnitRaw: String = "mi"
    @AppStorage("weightUnit") private var weightUnitRaw: String = "lb"

    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .mi }
    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lb }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AnalyzeHeaderView(mode: $mode, range: $range)

                Group {
                    switch mode {
                    case .exercise:
                        ExerciseAnalyzeSection(
                            exercises: exercises,
                            strengthSets: strengthSets,
                            cardioSessions: cardioSessions,
                            distanceUnit: distanceUnit,
                            range: range,
                            selectedExercise: $selectedExercise
                        )
                    case .weight:
                        WeightAnalyzeSection(
                            weightEntries: weightEntries,
                            weightUnit: weightUnit,
                            range: range
                        )
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: mode)

                Spacer(minLength: 16)
            }
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Analyze")
    }
}
