import SwiftUI

struct GridPlanView: View {
    @State private var showCreateGrid: Bool = false
    @State private var showEditGrid: Bool = false
    @State private var selectedGrid: Grid? = nil
    @State private var grids: [Grid] = []
    @State private var showDeleteConfirmation: Bool = false
    @State private var gridToDelete: Grid?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack {
                    // 📌 Header
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

                    // 📋 Grid List or Empty State
                    if grids.isEmpty {
                        emptyStateView
                    } else {
                        gridListView
                    }

                    Spacer()

                    // ➕ Floating Button (Bottom-Centered)
                    floatingAddButton
                }
                .onAppear {
                    loadGrids()
                }
                .sheet(isPresented: $showCreateGrid) {
                    CreateGridView()
                }
                .sheet(isPresented: $showEditGrid) {
                    if let gridToEdit = selectedGrid {
                        EditGridView(grid: gridToEdit) { updatedGrid in
                            if let index = grids.firstIndex(where: { $0.id == updatedGrid.id }) {
                                grids[index] = updatedGrid
                                saveGrids()
                            }
                        }
                    }
                }
                .alert("Delete Grid?", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        if let grid = gridToDelete {
                            deleteGrid(grid)
                        }
                    }
                } message: {
                    Text("This will permanently remove the grid and its data.")
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - 🔹 Grid List
extension GridPlanView {
    private var gridListView: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(grids, id: \.id) { grid in
                    ZStack {
                        // 👇 Background Button (For Swipe Actions)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gold)
                            .shadow(radius: 5)

                        HStack {
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
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .cornerRadius(10)
                    .contextMenu {
                        Button {
                            selectedGrid = grid
                            showEditGrid.toggle()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            gridToDelete = grid
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            selectedGrid = grid
                            showEditGrid.toggle()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading) {
                        Button(role: .destructive) {
                            gridToDelete = grid
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 🔹 Empty State View
extension GridPlanView {
    private var emptyStateView: some View {
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
    }
}

// MARK: - ➕ Floating Add Button
extension GridPlanView {
    private var floatingAddButton: some View {
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
}

// MARK: - 🔹 Helper Functions
extension GridPlanView {
    /// **Formats Date for UI**
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// **Deletes a Grid (With CSV Cleanup)**
    private func deleteGrid(_ grid: Grid) {
        grids.removeAll { $0.id == grid.id }
        saveGrids()

        // 🗑 Delete associated CSV file
        let fileName = "\(grid.id).csv"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try FileManager.default.removeItem(at: filePath)
            print("✅ Deleted grid CSV: \(fileName)")
        } catch {
            print("⚠️ Failed to delete CSV for grid: \(grid.id), error: \(error.localizedDescription)")
        }
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

