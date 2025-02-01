import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PDFKit

struct ReadingsView: View {
    @State private var readings: [Reading] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var listener: ListenerRegistration? // Added listener

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    titleSection

                    if isLoading {
                        loadingState
                    } else if let errorMessage = errorMessage {
                        errorState(errorMessage)
                    } else if readings.isEmpty {
                        emptyState
                    } else {
                        readingsList
                    }
                }
                .padding()
            }
            .onAppear(perform: setupListener) // Updated .onAppear to call the listener
            .onDisappear(perform: removeListener) // Removes Listener when the view disappears
            .navigationBarTitle("Readings", displayMode: .inline)
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
            VStack(spacing: 15) {
                ForEach(readings) { reading in
                    ReadingCardView(
                        reading: reading,
                        capturedImage: nil,
                        actionHandler: { action in
                            handleAction(action, for: reading)
                        },
                        displayMode: .deleteOrDownload
                    )
                    .padding()
                    .background(Color.black.opacity(0.9))
                    .cornerRadius(16)
                    .shadow(radius: 5)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func setupListener() {
       guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        isLoading = true // Set loading to true while we fetch data
         listener = db.collection("users").document(userId).collection("readings")
             .order(by: "timestamp", descending: true)
              .addSnapshotListener { snapshot, error in
             isLoading = false // Set loading to false once the data is loaded.
                 if let error = error {
                     errorMessage = "Error loading readings: \(error.localizedDescription)"
                      return
                 }
                 
                 guard let documents = snapshot?.documents else { return }
                 self.readings = documents.compactMap { doc -> Reading? in
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
                 }
             }
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
            "gridLocation": reading.gridLocation,
            "siteLocation": reading.siteLocation,
            "fixtureDetails": reading.fixtureDetails,
            "knownWattage": reading.knownWattage,
            "notes": reading.notes,
            "isFaulty": reading.isFaulty,
            "imageUrl": reading.imageUrl ?? ""
        ]
        
        db.collection("users").document(userId).collection("readings").document(reading.id)
            .setData(readingData, merge: true) { error in
                if let error = error {
                    print("❌ Error saving reading: \(error.localizedDescription)")
                } else {
                    print("✅ Reading saved successfully!")
                }
            }
    }
    
    private func deleteReading(_ reading: Reading) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userId).collection("readings").document(reading.id).delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Error deleting reading: \(error.localizedDescription)"
                } else {
                    withAnimation {
                        readings.removeAll { $0.id == reading.id }
                    }
                    print("✅ Reading deleted successfully.")
                }
            }
        }
    }
       
   private func generatePDF(for reading: Reading) {
          guard let userId = Auth.auth().currentUser?.uid else { return }
      
          PDFGenerator.generatePDF(reading: reading) { url in
              DispatchQueue.main.async {
                  if let url = url {
                      print("✅ PDF generated: \(url)")
                     sharePDF(url)
                  } else {
                      print("❌ Failed to generate PDF")
                  }
              }
          }
      }

    private func sharePDF(_ url: URL) {
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityController, animated: true, completion: nil)
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
