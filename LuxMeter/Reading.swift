import FirebaseFirestore

struct Reading: Identifiable {
    let id: String
    let luxValue: Float
    let timestamp: Date
    let lightReference: String
    let gridLocation: String
    let siteLocation: String
    let fixtureDetails: String
    let knownWattage: String
    let notes: String
    let isFaulty: Bool
    let imageUrl: String? // ✅ Stores the direct link from Firebase Storage
}

