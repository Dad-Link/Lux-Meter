import SwiftUI

struct CreateGridView: View {
    @State private var gridName: String = ""
    @State private var userGridId: String = UUID().uuidString
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var postcode: String = ""
    @State private var startDate = Date()
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            HeatmapBackgroundView()
            VStack {
                // 🔥 Exciting Title
                Text("Create Your Heat Map!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                    .padding(.top, 20)
                
                // ✨ Engaging Description
                Text("Map out the light intensity of your space! Create a grid, take readings, and generate a stunning heatmap. Perfect for lighting analysis, energy audits, and optimizing your workspace!")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                
                // 🔹 Grid Name Input
                TextField("Enter Grid Name", text: $gridName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // 🔹 Grid ID Input (Optional)
                TextField("Enter Grid ID (Optional)", text: $userGridId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // 🔹 Location Inputs
                TextField("Road Name", text: $address)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("City", text: $city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Postcode", text: $postcode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // 📆 Start Date Picker
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    .padding()
                
                // 🚀 Create Button
                Button(action: createGrid) {
                    Text("Create Heat Map")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gold)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.gold)
                    }
                }
            }
        }
    }
    
    /// **Creates a new grid and saves it locally**
    func createGrid() {
        let newGrid = Grid(
            id: userGridId,
            gridName: gridName.isEmpty ? "Unnamed Grid" : gridName,
            address: address,
            city: city,
            postcode: postcode,
            startDate: startDate
        )
        
        // Load existing grids, append new one, then save
        var grids = loadGrids()
        grids.append(newGrid)
        saveGrids(grids)
        
        // Create and save an empty CSV file for this grid
        saveGridAsCSV(gridId: newGrid.id)

        DispatchQueue.main.async {
            presentationMode.wrappedValue.dismiss()
        }
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
                csvString.append("\(row),\(col),,\n") // Empty Lux Value & Light Reference
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
