// LuxCell.swift (Or at the top of a shared file)
import Foundation

struct LuxCell: Codable {
    var lightReference: String?
    var luxValue: Int?
    
    init(lightReference: String? = nil, luxValue: Int? = nil) {
        self.lightReference = lightReference
        self.luxValue = luxValue
    }
}
