import SwiftUI

struct EditGridView: View {
    @State private var editedGrid: Grid
    var onSave: (Grid) -> Void
    @Environment(\.dismiss) var dismiss

    init(grid: Grid, onSave: @escaping (Grid) -> Void) {
        self._editedGrid = State(initialValue: grid)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all) // 🌙 Dark background
                
                VStack {
                    Text("Edit Grid Details")
                        .font(.title)
                        .bold()
                        .foregroundColor(.gold)
                        .padding(.top, 20)

                    // 📝 Input Fields
                    inputFields

                    // 💾 Save Button
                    Button(action: {
                        onSave(editedGrid)
                        dismiss()
                    }) {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gold)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding()

                    // ❌ Cancel Button
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                    .padding()

                    Spacer()
                }
                .padding()
            }
        }
    }
}

// MARK: - 🔹 Input Fields
extension EditGridView {
    private var inputFields: some View {
        VStack(spacing: 15) {
            customTextField("Grid Name", text: $editedGrid.gridName)
            customTextField("Road Name", text: $editedGrid.address)
            customTextField("City", text: $editedGrid.city)
            customTextField("Postcode", text: $editedGrid.postcode)

            // 📅 Date Picker
            DatePicker("Start Date", selection: $editedGrid.startDate, displayedComponents: .date)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(.white)
        }
    }

    // 📌 Custom Styled TextField
    private func customTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding()
            .background(Color.gray.opacity(0.4))
            .cornerRadius(8)
            .foregroundColor(.white)
            .padding(.horizontal)
    }
}
