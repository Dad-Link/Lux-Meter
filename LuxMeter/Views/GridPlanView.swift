import SwiftUI

struct GridPlanView: View {
    @StateObject private var gridManager = GridDataManager()
    
    @State private var showCreateGrid: Bool = false
    // Remove the showEditGrid flag and use selectedGrid for sheet presentation.
    @State private var selectedGrid: Grid? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var gridToDelete: Grid?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
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
                        
                        Text("Press and hold the grids to edit or delete.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // 📋 Grid List or Empty State
                    if gridManager.grids.isEmpty {
                        emptyStateView
                    } else {
                        gridListView
                    }
                    
                    Spacer()
                    
                    // ➕ Floating Button (Bottom-Centered)
                    floatingAddButton
                }
                .onAppear {
                    gridManager.loadGrids() // Load grids on view appearance.
                }
                .sheet(isPresented: $showCreateGrid) {
                    CreateGridView()
                        .onDisappear {
                            gridManager.loadGrids() // Reload grids after creating a new one.
                        }
                }
                // Item-based sheet presentation for editing.
                .sheet(item: $selectedGrid) { gridToEdit in
                    EditGridView(grid: gridToEdit) { updatedGrid in
                        if let index = gridManager.grids.firstIndex(where: { $0.gridId == updatedGrid.gridId }) {
                            gridManager.grids[index] = updatedGrid
                            gridManager.saveGrids()
                        }
                    }
                    .background(Color.black)
                    .onAppear {
                        gridManager.loadGrids()
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
    
    // MARK: - 🔹 Grid List
    private var gridListView: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(gridManager.grids, id: \.gridId) { grid in
                    NavigationLink(destination: RoomGridContainerView(gridId: grid.gridId)) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gold)
                                .shadow(radius: 5)
                            
                            VStack(alignment: .leading) {
                                Text(grid.jobName)
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Text("Start Date: \(formattedDate(grid.startDate))")
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .padding()
                        }
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .cornerRadius(10)
                    }
                    .contextMenu {
                        Button {
                            selectedGrid = grid
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

    
    // MARK: - 🔹 Empty State View
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
    
    // MARK: - ➕ Floating Add Button
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
    
    // MARK: - 🔹 Helper Functions
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func deleteGrid(_ grid: Grid) {
        gridManager.grids.removeAll { $0.gridId == grid.gridId }
        gridManager.saveGrids()
        
        let fileName = "\(grid.gridId).csv"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: filePath)
            print("✅ Deleted grid CSV: \(fileName)")
        } catch {
            print("⚠️ Failed to delete CSV for grid: \(grid.gridId), error: \(error.localizedDescription)")
        }
    }
}
