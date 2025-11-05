import SwiftUI

struct AnalyzeHeaderView: View {
    @Binding var mode: AnalyzeMode
    @Binding var range: AnalyzeRange

    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $mode) {
                ForEach(AnalyzeMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: .infinity)

            Menu {
                Picker("Range", selection: $range) {
                    ForEach(AnalyzeRange.allCases) { Text($0.label).tag($0) }
                }
            } label: {
                Label(range.label, systemImage: "calendar")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
}

private extension AnalyzeMode {
    var title: String {
        switch self {
        case .exercise: return "Exercise"
        case .weight: return "Weight"
        }
    }
}
