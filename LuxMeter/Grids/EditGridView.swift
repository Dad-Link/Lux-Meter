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
                Color.black.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Edit Grid Details")
                            .font(.title)
                            .bold()
                            .foregroundColor(.gold)
                            .padding(.top, 20)

                        // 🆕 Editable Job Name Input
                        customTextField("Job Reference", text: $editedGrid.jobName)

                        // 📝 Input Fields
                        inputFields

                        // 🔍 Display Grid ID (read-only)
                        Text("Grid ID: \(editedGrid.gridId)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top)

                        // 💾 Save Button
                        Button(action: {
                            onSave(editedGrid) // ✅ Simplified logic
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
                .ignoresSafeArea(.keyboard)
            }
            .onAppear {
                if editedGrid.gridId.isEmpty {
                    editedGrid.gridId = UUID().uuidString
                }
            }
        }
    }
}

// MARK: - 🔹 Input Fields
extension EditGridView {
    private var inputFields: some View {
        VStack(spacing: 15) {
            customTextField("Business/Resident Name", text: $editedGrid.businessName)
            customTextField("Street Address", text: $editedGrid.address)
            customTextField("Town", text: $editedGrid.town)
            customTextField("City", text: $editedGrid.city)
            customTextField("Postcode", text: $editedGrid.postcode)

            // 📅 Date Picker
            DatePicker("Start Date", selection: $editedGrid.startDate, displayedComponents: .date)
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
                .foregroundColor(.white)
                .padding(.horizontal)
        }
    }

    private func customTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding()
            .background(Color.gray.opacity(0.6))
            .cornerRadius(10)
            .foregroundColor(.white)
            .accentColor(.yellow)
            .padding(.horizontal)
            .font(.system(size: 18, weight: .regular))
            .multilineTextAlignment(.leading)
            .textInputAutocapitalization(.words)
    }
}

// MARK: - 🔹 Keyboard Dismiss Helper
extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
