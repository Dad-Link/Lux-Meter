import SwiftUI

struct GridPlanView: View {
    @State private var showCreateGrid: Bool = false
    @State private var grids: [Grid] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all) // ✅ Matte black background

                VStack {
                    // Title & Description
                    VStack(spacing: 8) {
                        Text("Grid Planner")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.gold)

                        Text("Create and manage grids to build your Lux & Heat Map.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.top, 20)

                    Spacer()

                    // Grid List or No Data Message
                    if grids.isEmpty {
                        VStack(spacing: 10) {
                            Text("No grids yet!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.gold)
                            
                            Text("Tap the '+' button below to create your first grid.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .padding(.top, 40)
                    } else {
                        ScrollView {
                            VStack(spacing: 15) {
                                ForEach(grids, id: \.id) { grid in
                                    NavigationLink(destination: RoomGridContainerView(gridId: grid.id)) {
                                        HStack {
                                            Image(systemName: "map.fill")
                                                .foregroundColor(.black)
                                            Text(grid.gridName)
                                                .font(.headline)
                                                .foregroundColor(.black)
                                            Spacer()
                                            Text(formattedDate(grid.startDate))
                                                .font(.caption)
                                                .foregroundColor(.black.opacity(0.7))
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gold)
                                        .cornerRadius(10)
                                        .shadow(radius: 5)
                                    }
                                }
                            }
                            .padding()
                        }
                    }

                    Spacer()

                    // Floating Plus Button (Centered Above Tabs)
                    Button(action: { showCreateGrid.toggle() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.gold)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.bottom, 20)
                }
                .onAppear {
                    loadGrids()
                    setupGridListener() // ✅ Live updates
                }
                .sheet(isPresented: $showCreateGrid) {
                    CreateGridView()
                }
            }
            .navigationBarHidden(true)
        }
    }

    /// **Formats Date for UI**
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// **Deletes a Grid**
    private func deleteGrid(at offsets: IndexSet) {
        grids.remove(atOffsets: offsets)
        saveGrids()
    }

    /// **Loads Grids from Local Storage**
    private func loadGrids() {
        let fileName = "grids.json"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            let data = try Data(contentsOf: filePath)
            grids = try JSONDecoder().decode([Grid].self, from: data)
            print("✅ Loaded \(grids.count) grids")
        } catch {
            print("⚠️ No saved grids found")
        }
    }

    /// **Saves Grids to Local Storage**
    private func saveGrids() {
        let fileName = "grids.json"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            let data = try JSONEncoder().encode(grids)
            try data.write(to: filePath)
            print("✅ Grids saved")
        } catch {
            print("❌ Failed to save grids: \(error.localizedDescription)")
        }
    }

    /// **Live Updates: Listen for Grid Changes**
    private func setupGridListener() {
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("grids.json")

        DispatchQueue.global(qos: .background).async {
            while true {
                if let data = try? Data(contentsOf: filePath),
                   let updatedGrids = try? JSONDecoder().decode([Grid].self, from: data) {
                    DispatchQueue.main.async {
                        self.grids = updatedGrids
                    }
                }
                sleep(5) // ✅ Refresh every 5 seconds
            }
        }
    }
}

