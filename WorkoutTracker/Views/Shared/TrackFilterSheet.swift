import SwiftUI
import SwiftData

struct TrackFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: TrackScreenViewModel
    let sections: [TrackFilterSection]
    let exercisesByTrackable: [UUID: Exercise]

    var body: some View {
        NavigationStack {
            List {
                allTrackersSection
                ForEach(sections) { sectionView(for: $0) }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filter Trackers")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private extension TrackFilterSheet {
    var allTrackersSection: some View {
        Section {
            Button {
                viewModel.setFilterAll()
                dismiss()
            } label: {
                SelectableRow(title: "All Trackers", iconName: nil, isSelected: viewModel.filter == .all)
            }
        }
    }

    func sectionView(for section: TrackFilterSection) -> some View {
        Section(header: Text(section.title)) {
            Button {
                viewModel.setFilter(kind: section.kind)
                dismiss()
            } label: {
                SelectableRow(title: "All \(section.title)", iconName: section.iconName, isSelected: viewModel.filter == .kind(section.kind))
            }

            ForEach(section.items) { item in
                Button {
                    viewModel.setFilter(trackableID: item.id)
                    dismiss()
                } label: {
                    SelectableRow(title: item.name, iconName: nil, isSelected: viewModel.filter == .trackable(item.id))
                }
            }
        }
    }
}

private struct SelectableRow: View {
    let title: String
    let iconName: String?
    let isSelected: Bool

    var body: some View {
        HStack {
            if let iconName {
                Image(systemName: iconName)
            }
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
    }
}
