import Foundation

struct Grid: Identifiable, Codable {
    var id: String
    var gridName: String
    var address: String
    var city: String
    var postcode: String
    var startDate: Date
}
