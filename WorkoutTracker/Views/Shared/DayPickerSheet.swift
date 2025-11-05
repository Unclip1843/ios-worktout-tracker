import SwiftUI

struct DayPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDay: Date

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker(
                    "",
                    selection: $selectedDay,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()

                Button("Today") {
                    selectedDay = Date().dayOnly
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Select Day")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
