import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ReadingsView: View {
    @State private var readings: [Reading] = []
    @State private var selectedReading: Reading?
    @State private var showDetails = false
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    // Title and Description
                    VStack(spacing: 10) {
                        Text("Your Lux Readings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Explore your recorded light measurements. Tap any reading to view its details.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Readings List or Error State
                    if isLoading {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if let errorMessage = errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    } else if readings.isEmpty {
                        VStack {
                            Image(systemName: "lightbulb")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.white.opacity(0.8))
                            Text("No readings available.")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 10)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(readings) { reading in
                                    Button(action: {
                                        withAnimation {
                                            selectedReading = reading
                                            showDetails = true
                                        }
                                    }) {
                                        HStack(alignment: .top, spacing: 20) {
                                            // Display the image using RemoteImage
                                            if let imageUrl = reading.imageUrl, let url = URL(string: imageUrl) {
                                                RemoteImage(url: url)
                                                    .clipShape(Circle())
                                                    .frame(width: 50, height: 50)
                                            } else {
                                                Image(systemName: "photo")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 50, height: 50)
                                                    .foregroundColor(.gray)
                                            }

                                            // Reading details
                                            VStack(alignment: .leading, spacing: 5) {
                                                Text("Lux Value: \(reading.luxValue, specifier: "%.2f") lx")
                                                    .font(.headline)
                                                    .foregroundColor(.blue)

                                                Text("Light Reference: \(reading.lightReference)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.white.opacity(0.8))

                                                Text("Grid Location: \(reading.gridLocation)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.white.opacity(0.8))

                                                Text(reading.timestamp, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.8))
                                            }

                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.black.opacity(0.4)) // Transparent background
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white.opacity(0.5), lineWidth: 1) // Outline
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding()
                // Details View
                .sheet(isPresented: $showDetails) {
                    if let reading = selectedReading {
                        ReadingDetailsView(
                            readingId: reading.id,
                            readingValue: reading.luxValue,
                            customTitle: reading.lightReference, // Pass as a plain string
                            lightReference: .constant(reading.lightReference),
                            gridLocation: .constant(reading.gridLocation),
                            siteLocation: .constant(reading.siteLocation),
                            fixtureDetails: .constant(reading.fixtureDetails),
                            knownWattage: .constant(reading.knownWattage),
                            notes: .constant(reading.notes),
                            isFaulty: .constant(reading.isFaulty),
                            capturedImage: nil, // Use nil or an appropriate UIImage
                            imageUrl: reading.imageUrl
                        )
                    }
                }


            }
            .onAppear {
                fetchReadings()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Readings")
        }
    }

    private func fetchReadings() {
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        db.collection("users").document(userId).collection("readings")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    errorMessage = "Error loading readings: \(error.localizedDescription)"
                    return
                }

                self.readings = snapshot?.documents.compactMap { doc -> Reading? in
                    let data = doc.data()
                    return Reading(
                        id: doc.documentID,
                        luxValue: data["luxValue"] as? Float ?? 0.0,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        lightReference: data["lightReference"] as? String ?? "",
                        gridLocation: data["gridLocation"] as? String ?? "",
                        siteLocation: data["siteLocation"] as? String ?? "",
                        fixtureDetails: data["fixtureDetails"] as? String ?? "",
                        knownWattage: data["knownWattage"] as? String ?? "",
                        notes: data["notes"] as? String ?? "",
                        isFaulty: data["isFaulty"] as? Bool ?? false,
                        imageUrl: data["imageUrl"] as? String
                    )
                } ?? []
            }
    }
}
