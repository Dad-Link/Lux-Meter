import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PDFKit

struct ReadingsView: View {
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var listener: ListenerRegistration?
    @StateObject private var dataManager = ReadingDataManager()

    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var selectedReading: Reading?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    titleSection

                    if isLoading {
                        loadingState
                    } else if let errorMessage = errorMessage {
                        errorState(errorMessage)
                    } else if dataManager.readings.isEmpty {
                        emptyState
                    } else {
                        readingsList
                    }
                }
                .padding()
            }
            .onAppear(perform: setupListener)
            .onDisappear(perform: removeListener)
            .navigationBarTitle("Readings", displayMode: .inline)
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    // MARK: - UI Components

    private var titleSection: some View {
        VStack(spacing: 10) {
            Text("Your Lux Readings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.gold)

            Text("View, edit, or download your saved readings.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var loadingState: some View {
        ProgressView("Loading...")
            .progressViewStyle(CircularProgressViewStyle(tint: .gold))
    }

    private func errorState(_ message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)

            Text(message)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var emptyState: some View {
        VStack {
            Image(systemName: "lightbulb.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white.opacity(0.8))

            Text("No readings available.")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 10)
        }
    }

    private var readingsList: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(dataManager.readings) { reading in
                    ReadingCardView(
                        reading: reading,
                        capturedImage: loadImageForReading(reading: reading),
                        actionHandler: { action in
                            handleAction(action, for: reading)
                        },
                        displayMode: .deleteOrDownload
                    )
                    .frame(maxWidth: 360)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .cornerRadius(16)
                    .shadow(radius: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Helper Functions

    private func loadImageForReading(reading: Reading) -> UIImage? {
        if let localImagePath = getLocalImagePath(for: reading.id) {
            return loadImageFromPath(path: localImagePath)
        }
        return nil
    }

    private func setupListener() {
        isLoading = true

        DispatchQueue.global(qos: .background).async {
            let savedReadings = loadReadingsLocally()

            DispatchQueue.main.async {
                self.dataManager.readings = savedReadings
                self.isLoading = false
                print("📄 Loaded \(savedReadings.count) readings from local storage.")
            }
        }
    }

    private func loadReadingsLocally() -> [Reading] {
        let fileURL = getDocumentsDirectory().appendingPathComponent("readings.json")
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Reading].self, from: data)) ?? []
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    func loadImageFromPath(path: String) -> UIImage? {
        let url = URL(fileURLWithPath: path)
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }

    private func getLocalImagePath(for readingId: String) -> String? {
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(readingId).jpg")
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL.path : nil
    }

    private func removeListener(){
        listener?.remove()
    }

    private func handleAction(_ action: ReadingCardAction, for reading: Reading) {
        switch action {
        case .delete:
            deleteReading(reading)
        case .save:
            saveReading(reading)
        case .download:
            selectedReading = reading
            generatePDF(for: reading)
        case .close:
            print("✅ Close action triggered inside ReadingCardView.")
        }
    }

    private func saveReading(_ reading: Reading) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ Error: No authenticated user found.")
            return
        }

        let db = Firestore.firestore()
        let readingData: [String: Any] = [
            "id": reading.id,
            "luxValue": reading.luxValue,
            "timestamp": FieldValue.serverTimestamp(),
            "lightReference": reading.lightReference,
            "lightLocation": reading.lightLocation,
            "siteLocation": reading.siteLocation,
            "fixtureDetails": reading.fixtureDetails,
            "knownWattage": reading.knownWattage,
            "notes": reading.notes,
            "isFaulty": reading.isFaulty,
            "imageUrl": reading.imageUrl ?? "",
            "localImagePath": reading.localImagePath ?? ""
        ]

        db.collection("users").document(userId)
            .collection("readings").document(reading.id)
            .setData(readingData, merge: true) { error in
                if let error = error {
                    print("❌ Error saving reading: \(error.localizedDescription)")
                } else {
                    print("✅ Reading saved successfully!")
                }
            }
    }

    private func deleteReading(_ reading: Reading) {
        var savedReadings = loadReadingsLocally()
        savedReadings.removeAll { $0.id == reading.id }

        do {
            let data = try JSONEncoder().encode(savedReadings)
            let fileURL = getDocumentsDirectory().appendingPathComponent("readings.json")
            try data.write(to: fileURL, options: .atomic)

            DispatchQueue.main.async {
                withAnimation {
                    self.dataManager.readings = savedReadings
                }
            }
            print("✅ Reading deleted successfully.")
        } catch {
            print("❌ Error deleting reading: \(error.localizedDescription)")
        }
    }

    private func generatePDF(for reading: Reading) {
        // Use the completion handler version of PDFGenerator.generatePDF.
        PDFGenerator.generatePDF(reading: reading) { url in
            DispatchQueue.main.async {
                if let url = url {
                    self.pdfURL = url
                    self.showShareSheet = true
                } else {
                    print("❌ Failed to generate PDF.")
                    self.errorMessage = "Failed to generate PDF. Please try again."
                }
            }
        }
    }
}

// MARK: - Enum for Button Actions

enum ReadingCardAction {
    case delete
    case save
    case download
    case close
}

// MARK: - ShareSheet View (for presenting UIActivityViewController)

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                                 applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
