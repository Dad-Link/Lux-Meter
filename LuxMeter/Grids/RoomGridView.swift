import SwiftUI
import UIKit
import FirebaseFirestore

struct RoomGridView: View {
    @Environment(\.dismiss) var dismiss // Use dismiss to go back manually
    @State private var luxGrid: [String: LuxCell] = [:]
    @Binding var is3DView: Bool
    @State private var selectedCell: (row: Int, column: Int)? = nil
    @State private var lightReference: String? = ""
    @State private var luxValue: String = ""
    @State private var showSaveSuccess: Bool = false
    @State private var gridId: String
    @State private var zoomScale: CGFloat = 1.0 // Track zoom level
    
    @State private var showPDFPreview = false
    @State private var generatedPDFURL: URL?
    
    @State private var businessName = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var businessAddress = ""
    @State private var businessEmail = ""
    @State private var businessNumber = ""
    
    @State private var jobName: String = ""
    @State private var userGridId: String = UUID().uuidString
    @State private var address: String = ""
    @State private var town: String = ""
    @State private var city: String = ""
    @State private var county: String = ""
    @State private var postcode: String = ""
    @State private var startDate = Date()
    
    init(is3DView: Binding<Bool>, gridId: String) {
        _is3DView = is3DView
        self.gridId = gridId
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar with Back Button
            HStack {
                Button(action: {
                    dismiss() // Go back to the previous screen
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red) // Red Back Button
                }
                .padding(.leading, 16)
                
                Spacer()
                
                Text("Room Grid Mapping")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                
                Spacer()
                
                // Hidden image to balance alignment
                Image(systemName: "chevron.left.circle.fill")
                    .opacity(0)
            }
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.top))
            
            Divider().background(Color.gray) // Separator
            
            // Instructional Text
            Text("Use the controls below to add or delete rows/columns. Then tap a cell to enter its lux reading.")
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            
            // Grid Content & Controls
            ZStack {
                VStack {
                    gridDisplayView
                    controlsView
                    Spacer()
                }
                .overlay(alignment: .bottom) {
                    if let cell = selectedCell {
                        CellInputView(
                            selectedCell: $selectedCell,
                            lightReference: $lightReference,
                            luxValue: $luxValue,
                            showSaveSuccess: $showSaveSuccess,
                            luxGrid: $luxGrid,
                            gridId: gridId,
                            onSave: { row, col in
                                saveCell(row: row, col: col)
                            },
                            onDismiss: {
                                selectedCell = nil
                            }
                        )
                        .transition(.move(edge: .bottom))
                    }
                }
            }
            .onAppear {
                loadGridData()
            }
        }
    }
    
    private var gridDisplayView: some View {
        ScrollView([.vertical, .horizontal]) {
            VStack {
                let rows = findMaxRow()
                let cols = findMaxColumn()
                
                VStack {
                    ForEach(0...rows, id: \.self) { row in
                        HStack {
                            ForEach(0...cols, id: \.self) { col in
                                gridCellView(row: row, column: col)
                            }
                        }
                    }
                }
                .scaleEffect(zoomScale) // Apply zoom level
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoomScale = max(0.5, min(value, 2.0)) // Allow zooming out (0.5x) & in (2.0x)
                        }
                )
            }
        }
        .frame(maxHeight: 500)
    }
    
    private func gridCellView(row: Int, column: Int) -> some View {
        let key = "\(row)_\(column)"
        let cell = luxGrid[key]
        let isSelected = selectedCell?.row == row && selectedCell?.column == column
        
        return Button(action: {
            selectedCell = (row, column)
            lightReference = cell?.lightReference
            luxValue = cell?.luxValue.map { String($0) } ?? ""
        }) {
            Text(cell?.luxValue.map { String($0) } ?? "")
                .frame(width: 40, height: 40)
                .foregroundColor(Color.yellow)
                .background(
                    isSelected ? Color.green.opacity(0.8) : Color.gray.opacity(0.5)
                )
                .border(Color.black)
        }
    }
    
    // Modified Controls View with a clickable export link below the row
    private var controlsView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // Add Row Button
                Button(action: { addRow() }) {
                    VStack {
                        Image(systemName: "plus.square.fill")
                        Text("Row")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.gold)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
                
                // Delete Row Button
                Button(action: { deleteRow() }) {
                    VStack {
                        Image(systemName: "minus.square.fill")
                        Text("Row")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Add Column Button
                Button(action: { addColumn() }) {
                    VStack {
                        Image(systemName: "plus.rectangle.fill")
                        Text("Column")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.gold)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
                
                // Delete Column Button
                Button(action: { deleteColumn() }) {
                    VStack {
                        Image(systemName: "minus.rectangle.fill")
                        Text("Column")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            // Clickable Export PDF Link below the control buttons
            Button(action: {
                exportGridToPDF()
            }) {
                Text("Export PDF")
                    .font(.caption)
                    .underline()
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
        .padding()
        .sheet(isPresented: $showPDFPreview) {
            if let pdfURL = generatedPDFURL, FileManager.default.fileExists(atPath: pdfURL.path) {
                PDFPreviewView(pdfURL: pdfURL) // Show full-screen preview when ready
            } else {
                VStack {
                    Text("Generating PDF, please wait...")
                        .foregroundColor(.red)
                        .font(.headline)
                    ProgressView()
                }
                .onAppear {
                    print("⚠️ PDF is still generating...")
                }
            }
        }
    }
    
    private func backButton() -> some View {
        Button(action: {
            dismiss() // Correctly dismiss the view
        }) {
            HStack {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
                Text("Back")
                    .font(.headline)
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Grid Helper Functions
    
    private func findMaxRow() -> Int {
        luxGrid.keys.compactMap { Int($0.split(separator: "_")[0]) }.max() ?? 7
    }
    
    private func findMaxColumn() -> Int {
        luxGrid.keys.compactMap { Int($0.split(separator: "_")[1]) }.max() ?? 7
    }
    
    private func addRow() {
        let newRow = findMaxRow() + 1
        let maxColumn = findMaxColumn()
        for col in 0...maxColumn {
            let key = "\(newRow)_\(col)"
            luxGrid[key] = LuxCell()
        }
        saveGridData()
    }
    
    private func addColumn() {
        let maxRow = findMaxRow()
        let newCol = findMaxColumn() + 1
        for row in 0...maxRow {
            let key = "\(row)_\(newCol)"
            luxGrid[key] = LuxCell()
        }
        saveGridData()
    }
    
    private func deleteRow() {
        let maxRow = findMaxRow()
        guard maxRow > 0 else { return }
        for col in 0...findMaxColumn() {
            let key = "\(maxRow)_\(col)"
            luxGrid.removeValue(forKey: key)
        }
        saveGridData()
    }
    
    private func deleteColumn() {
        let maxCol = findMaxColumn()
        guard maxCol > 0 else { return }
        for row in 0...findMaxRow() {
            let key = "\(row)_\(maxCol)"
            luxGrid.removeValue(forKey: key)
        }
        saveGridData()
    }
    
    private func saveCell(row: Int, col: Int) {
        let key = "\(row)_\(col)"
        luxGrid[key] = LuxCell(luxValue: Int(luxValue) ?? nil, lightReference: lightReference)
        saveGridData()
    }
    
    private func saveGridData() {
        let fileName = "\(gridId).csv"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        var csvString = "row,column,luxValue,lightReference\n"
        for (key, cell) in luxGrid {
            let parts = key.split(separator: "_")
            if let row = Int(parts[0]), let col = Int(parts[1]) {
                let lux = cell.luxValue.map { String($0) } ?? ""
                let ref = cell.lightReference ?? ""
                csvString.append("\(row),\(col),\(lux),\(ref)\n")
            }
        }
        do {
            try csvString.write(to: filePath, atomically: true, encoding: .utf8)
            print("✅ Grid data saved to \(filePath)")
        } catch {
            print("❌ Failed to save grid data: \(error.localizedDescription)")
        }
    }
    
    private func loadGridData() {
        let csvFileName = "\(gridId).csv"
        let csvFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(csvFileName)
        guard FileManager.default.fileExists(atPath: csvFilePath.path) else {
            print("⚠️ CSV file does not exist for gridId: \(gridId)")
            return
        }
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
                print("✅ Successfully loaded \(loadedGrid.count) grid cells for gridId: \(gridId)")
            }
        } catch {
            print("❌ Failed to load CSV for gridId: \(gridId). Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - PDF Export Functions
    
    private func exportGridToPDF() {
        self.showPDFPreview = true
        
        // Retrieve details from UserDefaults (if any)
        let businessName = UserDefaults.standard.string(forKey: "businessName") ?? "N/A"
        let address = UserDefaults.standard.string(forKey: "address") ?? "N/A"
        let town = UserDefaults.standard.string(forKey: "town") ?? "N/A"
        let city = UserDefaults.standard.string(forKey: "city") ?? "N/A"
        let county = UserDefaults.standard.string(forKey: "county") ?? "N/A"
        let postcode = UserDefaults.standard.string(forKey: "postcode") ?? "N/A"
        let startDateString = UserDefaults.standard.string(forKey: "startDate") ?? ""
        let startDate = ISO8601DateFormatter().date(from: startDateString) ?? Date()
        
        guard let pdfData = GridPDFMaker.generatePDF(
            jobName: jobName,
            userGridId: gridId,
            businessName: businessName,
            address: address,
            town: town,
            city: city,
            county: county,
            postcode: postcode,
            startDate: startDate,
            from: convertLuxGridTo2DArray(),
            title: "Heat Map Report",
            businessLogo: UIImage(named: "businessLogo"),
            firstName: firstName,
            lastName: lastName,
            businessAddress: businessAddress,
            businessEmail: businessEmail,
            businessNumber: businessNumber,
            siteLocation: gridId
        ) else {
            print("❌ Failed to generate PDF data")
            return
        }
        
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileName = "HeatMapReport_\(gridId).pdf"
            let fileURL = documentsURL.appendingPathComponent(fileName)
            
            DispatchQueue.global(qos: .background).async {
                do {
                    try pdfData.write(to: fileURL)
                    print("✅ PDF successfully saved to: \(fileURL.path)")
                    DispatchQueue.main.async {
                        self.generatedPDFURL = fileURL
                    }
                } catch {
                    print("❌ Failed to save PDF: \(error.localizedDescription)")
                }
            }
        } else {
            print("❌ Failed to get documents directory")
        }
    }
    
    private func convertLuxGridTo2DArray() -> [[LuxCell]] {
        let maxRow = findMaxRow()
        let maxColumn = findMaxColumn()
        var gridArray = Array(repeating: Array(repeating: LuxCell(), count: maxColumn + 1), count: maxRow + 1)
        for (key, cell) in luxGrid {
            let parts = key.split(separator: "_")
            if let row = Int(parts[0]), let col = Int(parts[1]) {
                gridArray[row][col] = cell
            }
        }
        return gridArray
    }
    
    // MARK: - Business Details
    
    private func loadBusinessDetails() {
        let userId = "12345" // Replace with actual user ID
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error fetching business details: \(error.localizedDescription)")
                return
            }
            if let data = snapshot?.data() {
                self.businessName = data["businessName"] as? String ?? ""
                self.firstName = data["firstName"] as? String ?? ""
                self.lastName = data["lastName"] as? String ?? ""
                self.businessAddress = data["businessAddress"] as? String ?? ""
                self.businessEmail = data["businessEmail"] as? String ?? ""
                self.businessNumber = data["businessNumber"] as? String ?? ""
            }
        }
    }
    
    private func exportGridToCSV() {
        let fileName = "\(gridId)_export.csv"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            let data = try String(contentsOf: filePath, encoding: .utf8)
            let activityVC = UIActivityViewController(activityItems: [data], applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
        } catch {
            print("❌ Failed to export CSV: \(error.localizedDescription)")
        }
    }
}
