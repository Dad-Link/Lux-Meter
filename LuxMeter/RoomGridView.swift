import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PDFKit

struct RoomGridView: View {
    @Binding var luxGrid: [[LuxCell]]
    @Binding var is3DView: Bool // 🔄 Toggle Binding
    
    @State private var selectedCell: (row: Int, column: Int)? = nil
    @State private var lightReference: String = ""
    @State private var luxValue: String = ""
    @State private var showSaveSuccess: Bool = false
    @State private var pdfURL: URL? = nil
    @State private var showPDFPreview = false
    @State private var exportFileName: String = "RoomGrid"

    @State private var userId: String? = Auth.auth().currentUser?.uid // ✅ User ID
    @State private var gridId: String = UUID().uuidString // ✅ Grid ID

    var body: some View {
        VStack {
            // **Title & Description**
            VStack(alignment: .leading, spacing: 5) {
                Text("Room Grid Mapping")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)

                Text("Tap a square to enter a lux value.")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.footnote)
            }
            .padding(.horizontal)

            // **Grid Display**
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gold, lineWidth: 3)
                    .padding(5)

                ScrollView([.vertical, .horizontal]) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: luxGrid.first?.count ?? 8)) {
                        ForEach(0..<luxGrid.count, id: \.self) { row in
                            ForEach(0..<luxGrid[row].count, id: \.self) { column in
                                ZStack {
                                    Rectangle()
                                        .fill(getCellColor(row: row, column: column))
                                        .frame(width: 40, height: 40)
                                        .cornerRadius(5)
                                        .onTapGesture {
                                            selectedCell = (row, column)
                                            lightReference = luxGrid[row][column].lightReference ?? ""
                                            luxValue = luxGrid[row][column].luxValue.map { String($0) } ?? ""
                                        }

                                    if let lux = luxGrid[row][column].luxValue {
                                        Text("\(lux)")
                                            .font(.footnote)
                                            .foregroundColor(.black)
                                    }
                                }
                                .border(Color.black, width: 1)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
            }

            // **Controls Row/Column & Export**
            HStack {
                Toggle(isOn: $is3DView) {
                    Text(is3DView ? "3D View" : "2D View")
                        .foregroundColor(.gold)
                }
                .toggleStyle(SwitchToggleStyle(tint: .gold))

                Spacer()

                Button(action: addRow) {
                    HStack { Image(systemName: "plus.square.fill"); Text("Row") }
                    .frame(width: 80, height: 40)
                    .background(Color.gold)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }

                Button(action: addColumn) {
                    HStack { Image(systemName: "plus.rectangle.fill"); Text("Column") }
                    .frame(width: 100, height: 40)
                    .background(Color.gold)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
            }
            .padding(.vertical)

            // **Export PDF Button**
            Button(action: exportGridToPDF) {
                HStack { Image(systemName: "doc.richtext"); Text("Preview & Export PDF") }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.gold)
                .foregroundColor(.black)
                .cornerRadius(10)
            }
            .padding()

            // **Cell Input**
            if let cell = selectedCell {
                VStack(spacing: 15) {
                    Text("Selected Cell: [\(cell.row), \(cell.column)]")
                        .font(.headline)
                        .foregroundColor(.gold)

                    TextField("Enter Light Reference", text: $lightReference)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    TextField("Enter Lux Value", text: $luxValue)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    // ✅ **Save Button (Stores in Firebase)**
                    Button(action: { saveGridToFirebase(); showSaveSuccess = true }) {
                        HStack {
                            Image(systemName: showSaveSuccess ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                            Text(showSaveSuccess ? "✅ Saved" : "Save")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gold)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }

    private func getCellColor(row: Int, column: Int) -> Color {
        if selectedCell?.row == row && selectedCell?.column == column { return Color.green }
        return Color.gold.opacity(0.8)
    }

    private func exportGridToPDF() {
        let pdfData = GridPDFExporter.generatePDF(from: luxGrid, title: "Room Grid")

        if let fileURL = GridPDFExporter.savePDF(pdfData, fileName: exportFileName) {
            print("📄 PDF saved at: \(fileURL.path)")
            self.pdfURL = fileURL
            self.showPDFPreview = true
        } else {
            print("❌ Failed to save PDF")
        }
    }

    private func addRow() {
        guard luxGrid.count < 50 else { return }
        luxGrid.append(Array(repeating: LuxCell(), count: luxGrid.first?.count ?? 8))
    }

    private func addColumn() {
        guard luxGrid.first?.count ?? 0 < 50 else { return }
        luxGrid = luxGrid.map { $0 + [LuxCell()] }
    }

    private func saveGridToFirebase() {
        guard let userId = userId else { return }
        let db = Firestore.firestore()

        var gridData: [[Int?]] = luxGrid.map { $0.map { $0.luxValue } }

        db.collection("users").document(userId).collection("grids").document(gridId).setData([
            "gridId": gridId,
            "timestamp": Timestamp(),
            "gridData": gridData
        ], merge: true)
    }
}
