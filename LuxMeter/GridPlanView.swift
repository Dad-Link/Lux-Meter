import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct GridPlanView: View {
    @State private var showCreateGrid: Bool = false
    @State private var grids: [Grid] = []
    @State private var listener: ListenerRegistration? = nil // Added listener
    
    var body: some View {
        NavigationStack{
            ZStack{
                HeatmapBackgroundView()
                VStack {
                    HStack {
                        Text("Your Saved Grids")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.gold)
                        Spacer()
                        Button(action: { showCreateGrid.toggle() }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gold)
                        }
                    }
                    .padding()
                    if grids.isEmpty {
                        Text("No grids created, create a new grid to begin.")
                            .foregroundColor(.gray)
                            .font(.headline)
                            .padding()
                    } else {
                        List {
                            ForEach(grids, id: \.id) { grid in
                                NavigationLink(destination: RoomGridContainerView(gridId: grid.id ?? "")){ // Changed from mapId to gridId
                                    HStack{
                                        Image(systemName: "map.fill")
                                        Text(grid.name)
                                    }
                                }
                            }
                            .onDelete(perform: deleteGrid)
                        }
                    }
                    
                    Spacer()
                }
                
                // Removed .onAppear(perform: loadGrids), listener added in .onAppear
                .onAppear {
                    setupListener()
                }
                .onDisappear {
                    listener?.remove() // Remove listener when view disappears
                }
                .sheet(isPresented: $showCreateGrid){
                    CreateGridView()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    func setupListener() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
        
        let db = Firestore.firestore()
        listener = db.collection("users").document(userId).collection("grids")
            .addSnapshotListener { (querySnapshot, error) in
                if let error = error {
                    print("Failed to get data, \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else { return }
                self.grids = documents.compactMap{ document -> Grid? in
                    try? document.data(as: Grid.self)
                }
            }
    }
    
    
    private func deleteGrid(at offsets: IndexSet) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
        let db = Firestore.firestore()
        
        offsets.forEach { index in
            let gridToDelete = grids[index]
            guard let mapId = gridToDelete.id else {
                print("Grid had no id \(gridToDelete)")
                return
            }
            db.collection("users").document(userId).collection("grids").document(mapId).delete { error in
                if let error = error {
                    print("Failed to delete map with id: \(mapId), \(error.localizedDescription)")
                } else {
                    print("Successfully deleted map with id: \(mapId)")
                }
            }
        }
    }
}

struct Grid : Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
}

struct CreateGridView : View{
    @State private var mapName: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body : some View {
        ZStack {
            HeatmapBackgroundView()
            VStack {
                TextField("Enter Grid Name", text: $mapName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: createGrid){
                    Text("Create Grid")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gold)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .toolbar{
                ToolbarItem(placement: .navigationBarLeading){
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack{
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
        }
    }
    
    func createGrid() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
        let db = Firestore.firestore()
        let newGrid = Grid(name: mapName)
        do{
            let _ = try db.collection("users").document(userId).collection("grids").addDocument(from: newGrid)
            print("✅ Created a new Grid with id: \(mapName)")
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("❌ Could not Create new grid doc \(error.localizedDescription)")
        }
    }
}
