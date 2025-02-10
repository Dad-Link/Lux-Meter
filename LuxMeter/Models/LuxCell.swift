import Foundation

// MARK: - LuxCell Model (for the grid)
struct LuxCell: Identifiable, Hashable {
    var id = UUID()
    var luxValue: Int?
    var lightReference: String?
}
