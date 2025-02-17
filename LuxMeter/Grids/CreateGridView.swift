import SwiftUI

struct CreateGridView: View {
    @State private var jobName: String = ""
    @State private var userGridId: String = UUID().uuidString
    @State private var businessName: String = ""
    @State private var address: String = ""
    @State private var town: String = ""
    @State private var city: String = ""
    @State private var postcode: String = ""
    @State private var startDate = Date()

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Create Heat Map")
                            .font(.title)
                            .bold()
                            .foregroundColor(.gold)
                            .padding(.top, 20)

                        // 🆕 Editable Job Name Input
                        customTextField("Job Reference", text: $jobName)

                        // 📝 Input Fields
                        inputFields

                        // 🔍 Display Grid ID (read-only)
                        Text("Grid ID: \(userGridId)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top)

                        // 💾 Save Button
                        Button(action: createGrid) {
                            Text("Create Heat Map")
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
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.red)
                        .padding()

                        Spacer()
                    }
                    .padding()
                    .background(Color.black)
                }
                .ignoresSafeArea(.keyboard)
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationBarHidden(true)
        }
    }

    /// **Creates a new grid and saves it locally**
    func createGrid() {
        let newGrid = Grid(
            jobName: jobName,
            gridId: userGridId,
            businessName: businessName,
            address: address,
            town: town,
            city: city,
            postcode: postcode,
            startDate: startDate
        )

        var grids = loadGrids()
        grids.append(newGrid)
        saveGrids(grids)
        saveGridAsCSV(gridId: newGrid.gridId)

        presentationMode.wrappedValue.dismiss()
    }

    /// **Loads saved grids from JSON**
    func loadGrids() -> [Grid] {
        let fileName = "grids.json"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: filePath)
            return try JSONDecoder().decode([Grid].self, from: data)
        } catch {
            return []
        }
    }

    /// **Saves grids to JSON**
    func saveGrids(_ grids: [Grid]) {
        let fileName = "grids.json"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            let data = try JSONEncoder().encode(grids)
            try data.write(to: filePath)
        } catch {
            print("❌ Failed to save grids: \(error.localizedDescription)")
        }
    }

    /// **Creates an empty CSV file for grid data**
    func saveGridAsCSV(gridId: String) {
        let fileName = "\(gridId).csv"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        var csvString = "row,column,luxValue,lightReference\n"
        for row in 0..<8 {
            for col in 0..<8 {
                csvString.append("\(row),\(col),,\n")
            }
        }
        do {
            try csvString.write(to: filePath, atomically: true, encoding: .utf8)
            print("✅ Created empty grid CSV: \(filePath)")
        } catch {
            print("❌ Failed to create CSV: \(error.localizedDescription)")
        }
    }
}

// MARK: - 🔹 Input Fields
extension CreateGridView {
    private var inputFields: some View {
        VStack(spacing: 15) {
            customTextField("Business/Resident Name", text: $businessName)
            customTextField("Street Address", text: $address)
            customTextField("Town", text: $town)
            customTextField("City", text: $city)
            customTextField("Postcode", text: $postcode)

            // 📆 Date Picker
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
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
            .background(Color.white.opacity(0.7))
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
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
