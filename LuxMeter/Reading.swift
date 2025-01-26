import FirebaseFirestore

struct Reading: Identifiable {
    let id: String
    let luxValue: Float
    let timestamp: Date
    let lightReference: String // Reference for the light assessment
    let gridLocation: String // Grid location within the site
    let siteLocation: String // Site location or room name
    let fixtureDetails: String // Details about the fixture
    let knownWattage: String // Known wattage of the fixture
    let notes: String // Additional notes
    let isFaulty: Bool // Faulty status
    let imageUrl: String? // URL to the image in Firebase Storage
}
