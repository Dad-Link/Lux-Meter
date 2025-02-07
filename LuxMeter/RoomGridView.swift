import SwiftUI
import UIKit
import FirebaseFirestore

struct RoomGridView: View {
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

    
    init(is3DView: Binding<Bool>, gridId: String) {
        _is3DView = is3DView
        self.gridId = gridId
    }
    
    var body: some View {
        ZStack {
            VStack {
                // Title
                Text("Room Grid Mapping")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                    .padding(.bottom, 10)
                
                // Grid Display
                gridDisplayView
                
                // Controls
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
                .scaleEffect(zoomScale) // ✅ Apply zoom level
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoomScale = max(0.5, min(value, 2.0)) // ✅ Allow zooming out (0.5x) & in (2.0x)
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
                .foregroundColor(Color.yellow) // ✅ Yellow text instead of yellow background
                .background(
                    isSelected ? Color.green.opacity(0.8) : Color.gray.opacity(0.5) // ✅ Brighter gray background
                )
                .border(Color.black)
        }
    }


    private var controlsView: some View {
        HStack(spacing: 10) {
            // ✅ Add Row Button
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
            
            // ✅ Delete Row Button
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
            
            // ✅ Add Column Button
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
            
            // ✅ Delete Column Button
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

            // ✅ Export PDF Button
            Button(action: { exportGridToPDF() }) {
                VStack {
                    Image(systemName: "doc.richtext")
                    Text("Export PDF")
                        .font(.caption)
                }
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            // ✅ Share PDF Button
            Button(action: { sharePDF() }) {
                VStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share PDF")
                        .font(.caption)
                }
                .frame(width: 60, height: 60)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .sheet(isPresented: $showPDFPreview) {
            if let pdfURL = generatedPDFURL, FileManager.default.fileExists(atPath: pdfURL.path) {
                PDFPreviewView(pdfURL: pdfURL) // ✅ Show full-screen preview when ready
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

    
    private func sharePDF() {
        guard let fileURL = generatedPDFURL else { return }
        
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        if let topController = UIApplication.shared.windows.first?.rootViewController {
            topController.present(activityViewController, animated: true, completion: nil)
        }
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
    
    // MARK: - Helper Functions
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
        let fileName = "\(gridId).csv"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            let csvString = try String(contentsOf: filePath, encoding: .utf8)
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
                print("✅ Successfully loaded \(loadedGrid.count) grid cells for \(gridId)")
            }
        } catch {
            print("⚠️ No CSV file found for grid \(gridId). A new one will be created when saving.")
        }
    }
    
    private func exportGridToPDF() {
        self.showPDFPreview = true  // ✅ Show preview immediately, even if the PDF is still generating

        guard let pdfData = GridPDFMaker.generatePDF(
            from: convertLuxGridTo2DArray(),
            title: "Heat Map Report",
            businessLogo: UIImage(named: "businessLogo"),
            businessName: businessName,
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
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
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

    
    private static func getColorForLuxValue(_ lux: Int?) -> UIColor {
        guard let luxValue = lux else { return UIColor.lightGray } // Default gray for empty cells

        switch luxValue {
        case 0...100:
            return UIColor.blue  // Low light (blue)
        case 101...300:
            return UIColor.green  // Moderate light (green)
        case 301...600:
            return UIColor.yellow  // Bright light (yellow)
        case 601...1000:
            return UIColor.orange  // Very bright light (orange)
        default:
            return UIColor.red  // Extremely bright (red)
        }
    }


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
