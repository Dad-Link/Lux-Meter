import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RoomGridContainerView: View {
    var gridId: String // Changed from mapId to gridId
    @State private var luxGrid: [[LuxCell]] = []
    @State private var is3DView: Bool = false
    @State private var gridName : String = ""
    
    var body: some View {
        ZStack{
            HeatmapBackgroundView()
            VStack{
                HStack{
                    Text(gridName) // This can be loaded from firestore by the gridId
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.gold)
                    Spacer()
                }
                .padding(.bottom)
                if is3DView{
                    Heatmap3DView(luxGrid: luxGrid.map { row in row.compactMap { $0.luxValue ?? 0}})
                } else{
                    RoomGridView(luxGrid: $luxGrid, is3DView: $is3DView, mapId: gridId)
                }
            }
            .onAppear{
                loadGrid()
            }
        }
        .navigationBarHidden(true)
    }
    
    func loadGrid(){
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("grids").document(gridId).getDocument(source: .default){ (document, error) in
            if let error = error {
                print("Failed to get data, \(error)")
                return
            }
            guard let document = document, document.exists else {
                print("Document does not exist")
                return
            }
            let data = document.data()
           
            
            if let fetchedGridName = data?["name"] as? String, let gridData = data?["gridData"] as? [[Int?]], let lightReferenceData = data?["lightReferenceData"] as? [[String?]] {
                self.gridName = fetchedGridName
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
                self.luxGrid = Array(
                    repeating: Array(repeating: LuxCell(), count: 8),
                   count: 20
                )
            }
        }
    }
}
