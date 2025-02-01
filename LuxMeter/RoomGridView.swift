import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PDFKit
import UIKit

struct RoomGridView: View {
    @Binding var luxGrid: [[LuxCell]]
    @Binding var is3DView: Bool
    
    @State private var selectedCells: Set<[Int]> = []
    @State private var isMultiSelectMode: Bool = false
    
    @State private var selectedCell: (row: Int, column: Int)? = nil
    @State private var lightReference: String? = ""
    @State private var luxValue: String = ""
    @State private var showSaveSuccess: Bool = false
    @State private var pdfURL: URL? = nil
    @State private var showPDFPreview = false
    @State private var exportFileName: String = "RoomGrid"
    
    @State private var userId: String? = Auth.auth().currentUser?.uid
    @State private var gridId: String = ""
    var mapId: String
    
    
    init(luxGrid: Binding<[[LuxCell]]>, is3DView: Binding<Bool>, mapId: String) {
        _luxGrid = luxGrid
        _is3DView = is3DView
        self.mapId = mapId
    }
    
    var body: some View {
        ZStack {
            VStack {
                // **Title & Description**
                VStack(alignment: .center, spacing: 5) {
                     if let firstGrid = luxGrid.first {
                           Text("Welcome to \(firstGrid.first?.lightReference ?? "Your Map"), let's continue mapping this project!")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                 .padding(.horizontal, 30)
                                  .padding(.bottom, 12)
                         }
                    Text("Room Grid Mapping")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.gold)
                    
                    Text("Tap a square to enter a lux value.")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.vertical)
                
                // **Grid Display**
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gold, lineWidth: 3)
                        .padding(5)
                    
                    ScrollView([.vertical, .horizontal]) {
                        VStack {
                            ForEach(0..<luxGrid.count, id: \.self) { row in
                                HStack {
                                    ForEach(0..<luxGrid[row].count, id: \.self) { column in
                                        ZStack {
                                            Rectangle()
                                                .fill(getCellColor(row: row, column: column))
                                                .frame(width: 40, height: 40)
                                                .cornerRadius(5)
                                                .shadow(color: .green.opacity(0.2), radius: 4)
                                            .overlay(
                                                Rectangle()
                                                  .stroke(selectedCells.contains([row,column]) ? .blue : .clear, lineWidth: 3)
                                            )
                                            .gesture(
                                                LongPressGesture(minimumDuration: 0.5)
                                                .onEnded { _ in
                                                    handleCellLongPress(row: row, column: column)
                                                 }
                                                .simultaneously(with: TapGesture()
                                                    .onEnded { _ in
                                                        handleCellTap(row: row, column: column)
                                                    })
                                           )
                                          
                                            
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
                }
            
                // **Controls Row/Column & Export**
                 ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                         Toggle(isOn: $is3DView) {
                                Text(is3DView ? "3D" : "2D")
                                .font(.caption)
                                   .foregroundColor(.gold)
                         }
                         .toggleStyle(SwitchToggleStyle(tint: .gold))
                        .frame(width: 60, height: 60)
                         
                        
                         Button(action: addRow) {
                             VStack{
                                 Image(systemName: "plus.square.fill")
                                 Text("Row")
                                    .font(.caption)
                             }
                             .frame(width: 60, height: 60)
                             .background(Color.gold)
                             .foregroundColor(.black)
                             .cornerRadius(10)
                            
                         }
                         Button(action: deleteRow) {
                                  VStack{
                                      Image(systemName: "minus.square.fill")
                                      Text("Row")
                                       .font(.caption)
                                  }
                                  .frame(width: 60, height: 60)
                                  .background(Color.red)
                                  .foregroundColor(.black)
                                  .cornerRadius(10)
                           }
                         
                         Button(action: addColumn) {
                                  VStack{
                                      Image(systemName: "plus.rectangle.fill")
                                     Text("Column")
                                        .font(.caption)
                                  }
                                 .frame(width: 60, height: 60)
                                  .background(Color.gold)
                                  .foregroundColor(.black)
                                  .cornerRadius(10)
                         }
                         Button(action: deleteColumn) {
                            VStack{
                                Image(systemName: "minus.rectangle.fill")
                                Text("Column")
                                   .font(.caption)
                            }
                           .frame(width: 60, height: 60)
                            .background(Color.red)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                        }
                         
                         Button(action: exportGridToPDF) {
                            VStack{
                                Image(systemName: "doc.richtext")
                                Text("Export")
                                  .font(.caption)
                            }
                            .frame(width: 60, height: 60)
                             .background(Color.gold)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                         }
                         
                        }
                     .padding()
                 }
                
                Spacer()
            
            }
             // **Cell Input**
            .overlay(alignment: .bottom){
                if isMultiSelectMode {
                     MultiCellInputView(
                        selectedCells: $selectedCells,
                        lightReference: $lightReference,
                        luxValue: $luxValue,
                        showSaveSuccess: $showSaveSuccess,
                        luxGrid: $luxGrid,
                        mapId: mapId,
                        onSave: { Task { await saveGridToFirebase() } }
                   )
                 } else if let cell = selectedCell {
                     CellInputView(
                         selectedCell: $selectedCell,
                         lightReference: $lightReference,
                         luxValue: $luxValue,
                          showSaveSuccess: $showSaveSuccess,
                        luxGrid: $luxGrid,
                        mapId: mapId,
                          onSave: { Task { await saveGridToFirebase() } }
                    )
                 }
             }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showPDFPreview) {
            if let pdfURL = pdfURL {
                PDFPreviewView(pdfURL: pdfURL)
            }
        }
        .onAppear{
            loadGrid()
        }
    }
    
    private func getCellColor(row: Int, column: Int) -> Color {
         if selectedCells.contains([row,column]) {
              return Color.blue
            
         }
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
        let newRow = Array(repeating: LuxCell(), count: luxGrid.first?.count ?? 8)
        luxGrid.append(newRow)
    }
    
     private func deleteRow() {
        guard !luxGrid.isEmpty, luxGrid.count > 1 else { return }
            luxGrid.removeLast()
    }
    
    private func addColumn() {
        guard let firstRow = luxGrid.first, firstRow.count < 50 else { return }
        for index in 0..<luxGrid.count {
            var newRow = luxGrid[index]
            newRow.append(LuxCell())
            luxGrid[index] = newRow
        }
    }
    private func deleteColumn() {
        guard let firstRow = luxGrid.first, firstRow.count > 1 else { return }
       for index in 0..<luxGrid.count {
           var newRow = luxGrid[index]
          newRow.removeLast()
          luxGrid[index] = newRow
        }
    }
    
    private func loadGrid(){
         guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
         
         let db = Firestore.firestore()
         db.collection("users").document(userId).collection("grids").document(mapId).getDocument(source: .default) { document, error in
            if let error = error {
                print("Failed to get data \(error.localizedDescription)")
                return
            }
             
            guard let document = document, document.exists else {
                 print("Could not get the document \(mapId)")
                return
            }
             let data = document.data()
            
           
             if let fetchedGridId = data?["gridId"] as? String, let fetchedGridName = data?["name"] as? String, let gridData = data?["gridData"] as? [[Int?]], let lightReferenceData = data?["lightReferenceData"] as? [[String?]] {
                  self.gridId = fetchedGridId
                   var newGrid: [[LuxCell]] = []
                 
                 for (rowIndex, row) in gridData.enumerated(){
                      var newRow: [LuxCell] = []
                     for (colIndex, lux) in row.enumerated(){
                          var newCell = LuxCell()
                         newCell.luxValue = lux
                         if let lightReference = lightReferenceData[rowIndex][colIndex] {
                             newCell.lightReference = lightReference
                         }
                          newRow.append(newCell)
                    }
                      newGrid.append(newRow)
                 }
                self.luxGrid = newGrid
             } else {
                 self.gridId = UUID().uuidString
                self.luxGrid = Array(
                     repeating: Array(repeating: LuxCell(), count: 8),
                    count: 20
                 )
           }
         }
     }
    
    private func saveGridToFirebase() async {
          guard let userId = Auth.auth().currentUser?.uid else {
              print("User not authenticated.")
              return
          }
        
         if isMultiSelectMode{
            for cellData in selectedCells{
                 let row = cellData[0]
                 let column = cellData[1]
                    let db = Firestore.firestore()
                    let cellToSave = GridCell(
                       id: UUID().uuidString,
                     row: row,
                     column: column,
                     lightReference: lightReference,
                     luxValue: Int(luxValue)
                   )
                 do{
                   let _ = try await db.collection("users").document(userId).collection("grids").document(mapId).collection("gridCells").document(cellToSave.id ?? "").setData(from: cellToSave)
                       print("✅ saveToFirebase for cell successful")
                         showSaveSuccess = true
                 } catch {
                     print("❌ saveToFirebase for cell failed \(error.localizedDescription)")
                     showSaveSuccess = false
                 }
             }
         } else if let selectedCell = selectedCell{
            // Update luxGrid with the edited values
                 if let lux = Int(luxValue){
                     luxGrid[selectedCell.row][selectedCell.column].luxValue = lux
               }
               
                luxGrid[selectedCell.row][selectedCell.column].lightReference = lightReference
               
                 let db = Firestore.firestore()
                let cellToSave = GridCell(
                     id: UUID().uuidString,
                    row: selectedCell.row,
                    column: selectedCell.column,
                    lightReference: luxGrid[selectedCell.row][selectedCell.column].lightReference,
                    luxValue: luxGrid[selectedCell.row][selectedCell.column].luxValue
                 )
               do{
                   let _ = try await db.collection("users").document(userId).collection("grids").document(mapId).collection("gridCells").document(cellToSave.id ?? "").setData(from: cellToSave)
                       print("✅ saveToFirebase for cell successful")
                       showSaveSuccess = true
                } catch {
                    print("❌ saveToFirebase for cell failed \(error.localizedDescription)")
                      showSaveSuccess = false
               }
          }
     }
    
    private func handleCellTap(row: Int, column: Int){
         if !isMultiSelectMode {
           selectedCell = (row, column)
        }
    }
   
    private func handleCellLongPress(row: Int, column: Int){
          isMultiSelectMode.toggle()
            if selectedCells.contains([row,column]) {
                selectedCells.remove([row,column])
            } else {
                 selectedCells.insert([row, column])
           }
      }
}
struct CellInputView : View{
    @Binding var selectedCell: (row: Int, column: Int)?
    @Binding var lightReference: String
    @Binding var luxValue: String
    @Binding var showSaveSuccess: Bool
    @Binding var luxGrid: [[LuxCell]]
    var mapId: String
     var onSave: () async -> Void
    
    var body : some View{
        VStack(spacing: 15) {
            if let cell = selectedCell{
                 Text("Selected Cell: [\(cell.row), \(cell.column)]")
                    .font(.headline)
                    .foregroundColor(.gold)
            
                 TextField("Enter Light Reference", text: $lightReference, prompt: Text("Optional Light Reference"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            
                TextField("Enter Lux Value", text: $luxValue)
                    .keyboardType(.numberPad)
                   .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            
                // ✅ **Save Button (Stores in Firebase)**
                Button(action: { Task { await onSave()} ; showSaveSuccess = true }) {
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
            
        }
          .padding()
           .background(Color.black.opacity(0.9))
           .cornerRadius(16)
           .shadow(radius: 5)
    }
}
struct MultiCellInputView : View{
  @Binding var selectedCells: Set<[Int]>
    @Binding var lightReference: String
    @Binding var luxValue: String
    @Binding var showSaveSuccess: Bool
    @Binding var luxGrid: [[LuxCell]]
    var mapId: String
    var onSave: () async -> Void
    
    var body : some View{
        VStack(spacing: 15) {
             Text("Multiple Cells Selected")
                .font(.headline)
                .foregroundColor(.gold)
            
              TextField("Enter Light Reference", text: $lightReference, prompt: Text("Optional Light Reference"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
         
            TextField("Enter Lux Value", text: $luxValue)
                .keyboardType(.numberPad)
               .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
         
            // ✅ **Save Button (Stores in Firebase)**
            Button(action: { Task { await onSave()} ; showSaveSuccess = true }) {
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
           .background(Color.black.opacity(0.9))
           .cornerRadius(16)
           .shadow(radius: 5)
    }
}
