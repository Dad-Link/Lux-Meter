import FirebaseFirestore

struct Reading: Identifiable, Codable {    var id: String
    var luxValue: Float
    var timestamp: Date
    var lightReference: String
    var lightLocation: String
    var siteLocation: String
    var fixtureDetails: String
    var knownWattage: String
    var notes: String
    var isFaulty: Bool
    var imageUrl: String? // ✅ Change this to an Optional
    var localImagePath: String? // ✅ Change this to an Optional

}


