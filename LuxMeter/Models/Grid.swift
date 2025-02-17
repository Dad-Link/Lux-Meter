import Foundation

// MARK: - 🔹 Grid Model
struct Grid: Codable {
    var jobName: String = ""
    var gridId: String = ""
    var businessName: String = ""
    var address: String = ""
    var town: String = ""
    var city: String = ""
    var postcode: String = ""
    var startDate: Date = Date()
}
extension Grid: Identifiable {
    var id: String { gridId }
}
