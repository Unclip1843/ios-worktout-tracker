import SwiftUI

@MainActor
final class AddTrackingCustomViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var kind: TrackableItem.Kind = .strengthExercise
    @Published var selectedMuscleGroups: Set<String> = []
    @Published var tagInput: String = ""
    @Published var coingeckoID: String = ""
    @Published var coinmarketcapID: String = ""
    @Published var wikipediaURL: String = ""
    @Published var websiteURL: String = ""
    @Published var notes: String = ""

    func reset() {
        name = ""
        kind = .strengthExercise
        selectedMuscleGroups.removeAll()
        tagInput = ""
        coingeckoID = ""
        coinmarketcapID = ""
        wikipediaURL = ""
        websiteURL = ""
        notes = ""
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var tagList: [String] {
        tagInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var trimmedNotes: String? {
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var trimmedCoingeckoID: String? {
        let trimmed = coingeckoID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var trimmedCoinmarketcapID: String? {
        let trimmed = coinmarketcapID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var trimmedWikipediaURL: String? {
        let trimmed = wikipediaURL.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var trimmedWebsiteURL: String? {
        let trimmed = websiteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var muscleGroupsArray: [String] {
        Array(selectedMuscleGroups).sorted()
    }
}

struct AddTrackingCustomView: View {
    @ObservedObject var viewModel: AddTrackingCustomViewModel

    var body: some View {
        Group {
            Section("Name") {
                TextField("Title", text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }

            Section("Type") {
                Picker("Category", selection: $viewModel.kind) {
                    ForEach(TrackableItem.Kind.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.inline)
            }

            if viewModel.kind == .strengthExercise || viewModel.kind == .cardioExercise {
                Section("Muscle Groups") {
                    ForEach(MuscleCatalog.defaultGroups, id: \.self) { muscle in
                        Toggle(isOn: Binding(
                            get: { viewModel.selectedMuscleGroups.contains(muscle) },
                            set: { isOn in
                                if isOn {
                                    viewModel.selectedMuscleGroups.insert(muscle)
                                } else {
                                    viewModel.selectedMuscleGroups.remove(muscle)
                                }
                            }
                        )) {
                            Text(muscle)
                        }
                    }
                }
            }

            Section("Tags") {
                TextField("Comma separated tags", text: $viewModel.tagInput)
                    .autocorrectionDisabled()
            }

            Section("External Links (optional)") {
                TextField("CoinGecko ID", text: $viewModel.coingeckoID)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("CoinMarketCap ID", text: $viewModel.coinmarketcapID)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("Wikipedia URL", text: $viewModel.wikipediaURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("Website URL", text: $viewModel.websiteURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            Section("Notes") {
                TextField("Optional notes", text: $viewModel.notes, axis: .vertical)
            }
        }
    }
}
