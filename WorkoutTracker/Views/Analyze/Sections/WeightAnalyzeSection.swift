import SwiftUI
import Charts

struct WeightAnalyzeSection: View {
    let weightEntries: [WeightEntry]
    let weightUnit: WeightUnit
    let range: AnalyzeRange

    var body: some View {
        let cutoff = range.cutoffDate()
        let ordered = weightEntries
            .filter { $0.at >= cutoff }
            .sorted(by: { $0.at < $1.at })
        let chartData = ordered.map { (date: $0.at, value: fromKilograms($0.kg, to: weightUnit)) }

        VStack(spacing: 16) {
            WeightSummaryView(weights: weightEntries, weightUnit: weightUnit)
                .padding(.horizontal)

            if chartData.isEmpty {
                SummaryCard("Keep logging", value: "No weigh-ins yet", footnote: "Add a weight entry to unlock insights.")
                    .padding(.horizontal)
            } else {
                Chart(chartData, id: \.date) {
                    LineMark(x: .value("Date", $0.date), y: .value("Weight", $0.value))
                    PointMark(x: .value("Date", $0.date), y: .value("Weight", $0.value))
                }
                .frame(height: 260)
                .padding(.horizontal)
            }
        }
    }
}

private struct WeightSummaryView: View {
    let weights: [WeightEntry]
    let weightUnit: WeightUnit

    var body: some View {
        if let latest = weights.max(by: { $0.at < $1.at }) {
            let latestValue = fromKilograms(latest.kg, to: weightUnit)
            let sevenDayCutoff = Date().addingTimeInterval(-7 * 86_400)
            let reference = weights.filter { $0.at <= sevenDayCutoff }.max(by: { $0.at < $1.at })
            let referenceValue = reference.map { fromKilograms($0.kg, to: weightUnit) }
            let delta = referenceValue.map { latestValue - $0 }
            let deltaText: String = {
                guard let delta else { return "—" }
                if abs(delta) < 0.05 { return "No change" }
                let sign = delta > 0 ? "+" : "−"
                return String(format: "%@%.1f %@", sign, abs(delta), weightUnit.label)
            }()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                SummaryCard("Latest", value: String(format: "%.1f %@", latestValue, weightUnit.label),
                            footnote: latest.at.formatted(date: .abbreviated, time: .shortened))
                SummaryCard("Change (7d)", value: deltaText)
                SummaryCard("Entries", value: "\(weights.count)", footnote: "Lifetime logs")
            }
        } else {
            SummaryCard("Log weight", value: "No entries yet", footnote: "Tap the scale icon on Track to add one.")
        }
    }
}
