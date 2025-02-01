import Foundation

struct GridCell : Identifiable, Codable{
    var id: String?
    var row: Int
    var column: Int
    var lightReference: String?
    var luxValue: Int?
}
