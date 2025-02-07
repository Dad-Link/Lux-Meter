import SwiftUI

struct RoomGridContainerView: View {
    var gridId: String
    @State private var luxGrid: [String: LuxCell] = [:] // Stores grid data
    @State private var is3DView: Bool = false
    @State private var gridName: String = "Loading..."

    var body: some View {
        ZStack {
            HeatmapBackgroundView()
            VStack {
                // ✅ Centered Grid Name
                Text(gridName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                    .frame(maxWidth: .infinity, alignment: .center) // ✅ This centers it

                if is3DView {
                    Heatmap3DView(luxGrid: convertTo2DArray(from: luxGrid))
                } else {
                    RoomGridView(is3DView: $is3DView, gridId: gridId)
                }
            }
            .onAppear {
                if gridId.isEmpty {
                    print("❌ ERROR: gridId is empty in RoomGridContainerView")
                } else {
                    print("✅ RoomGridContainerView gridId: \(gridId), Loading grid data...")
                    loadGridData()
                }
            }
        }
        .navigationBarHidden(true)
    }

    func loadGridData() {
        let jsonFileName = "grids.json"
        let jsonFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(jsonFileName)

        // Load grids from JSON to find the correct grid name
        do {
            let data = try Data(contentsOf: jsonFilePath)
            let grids = try JSONDecoder().decode([Grid].self, from: data)
            
            // Find the grid with the matching gridId
            if let matchingGrid = grids.first(where: { $0.id == gridId }) {
                self.gridName = matchingGrid.gridName
            } else {
                self.gridName = "Unnamed Grid"
            }
        } catch {
            print("⚠️ No JSON file found or error reading: \(error.localizedDescription)")
            self.gridName = "Unnamed Grid"
        }
        
        let csvFileName = "\(gridId).csv"
        let csvFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(csvFileName)

        // Load the actual grid data from CSV
        do {
            let csvString = try String(contentsOf: csvFilePath, encoding: .utf8)
            let rows = csvString.components(separatedBy: "\n").dropFirst()

            var loadedGrid: [String: LuxCell] = [:]

            for row in rows {
                let columns = row.components(separatedBy: ",")
                guard columns.count >= 4 else { continue }

                if let rowNum = Int(columns[0]), let colNum = Int(columns[1]) {
                    let luxValue = Int(columns[2]) ?? nil
                    let lightReference = columns[3].isEmpty ? nil : columns[3]
                    let key = "\(rowNum)_\(colNum)"
                    loadedGrid[key] = LuxCell(luxValue: luxValue, lightReference: lightReference)
                }
            }

            DispatchQueue.main.async {
                self.luxGrid = loadedGrid
                print("✅ Successfully loaded \(loadedGrid.count) grid cells for \(gridId), Grid Name: \(self.gridName)")
            }
        } catch {
            print("⚠️ No CSV file found for grid \(gridId). A new one will be created when saving.")
        }
    }

    /// **Convert the dictionary to a 2D array for heatmap visualization**
    private func convertTo2DArray(from dictionary: [String: LuxCell]) -> [[Int]] {
        guard !dictionary.isEmpty else { return [] }

        var maxRow = 0
        var maxCol = 0
        for key in dictionary.keys {
            let parts = key.split(separator: "_")
            if parts.count == 2, let row = Int(parts[0]), let col = Int(parts[1]) {
                maxRow = max(maxRow, row)
                maxCol = max(maxCol, col)
            }
        }

        var grid = Array(repeating: Array(repeating: 0, count: maxCol + 1), count: maxRow + 1)

        for (key, luxCell) in dictionary {
            let parts = key.split(separator: "_")
            if parts.count == 2,
               let row = Int(parts[0]),
               let col = Int(parts[1]),
               let luxValue = luxCell.luxValue {
                grid[row][col] = luxValue
            }
        }

        return grid
    }
}
