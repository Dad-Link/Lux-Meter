import SwiftUI
import AVFoundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PDFKit

enum ReadingCardDisplayMode {
    case spinOrDelete  // LightMeterView (pos 1)
    case saveOrDelete  // LightMeterView (pos 2)
    case deleteOrDownload  // ReadingsView (pos 1)
}

struct LightMeterView: View {
    @StateObject private var lightMeterManager = LightMeterManager()
    @State private var isMeasuring = false
    @State private var hasCameraPermission = false
    @State private var showReadingDetails = false
    @State private var currentReading: Float = 0.0
    @State private var location = ""
    @State private var address = ""
    @State private var reference = ""
    @State private var notes = ""
    @State private var isFaulty = false
    @State private var capturedImage: UIImage?
    @State private var imageLocalUUID: String?
    @State private var feedbackMessage: String?
    @State private var imageUrl: URL?
    @State private var gridLocation = ""
    @State private var siteLocation = ""
    @State private var fixtureDetails = ""
    @State private var knownWattage = ""
    @State private var readings: [Reading] = []
    
    @State private var timestamp = Date()
    @State private var lightReference = ""


    var dynamicBackground: some View {
        Color.black.edgesIgnoringSafeArea(.all)
    }

    var body: some View {
        ZStack {
            // Dynamic Background
            dynamicBackground.edgesIgnoringSafeArea(.all)

            VStack {
                // Header
                VStack(spacing: 5) {
                    Text("Lux Meter")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.gold)

                    Text("Measure light intensity in real time")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 30)

                Spacer()

                // Light Measurement Display
                if let lightLevel = lightMeterManager.lightLevel, isMeasuring {
                    Text("Light Intensity: \(String(format: "%.2f", lightLevel)) lx")
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                }

                // Circle Camera Feed or Placeholder
                ZStack {
                    Circle()
                        .strokeBorder(Color.gold, lineWidth: 4)
                        .frame(width: 230, height: 230)

                    if hasCameraPermission && isMeasuring {
                        CameraLightMeterView(session: lightMeterManager.captureSession)
                            .clipShape(Circle())
                            .frame(width: 220, height: 220)
                    } else {
                        Image(systemName: "camera.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gold.opacity(0.8))
                    }
                }
                .shadow(radius: 10)
                .padding(.bottom, 40)

                // Start/Stop Button
                Button(action: toggleMeasurement) {
                    HStack {
                        Image(systemName: isMeasuring ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 22))
                        Text(isMeasuring ? "Stop Measurement" : "Start Measurement")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isMeasuring ? Color.red : Color.gold)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
                .padding(.horizontal, 20)

                Spacer()

                // Feedback Message
                if let message = feedbackMessage {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.green)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.8), value: feedbackMessage)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                feedbackMessage = nil
                            }
                        }
                }
            }
            .padding()
            .onAppear(perform: requestCameraPermission)
            .onDisappear(perform: lightMeterManager.stopMeasuring)
            .navigationBarHidden(true)

            if showReadingDetails {
                ReadingCardView(
                    reading: Reading(
                        id: UUID().uuidString,
                        luxValue: currentReading,
                        timestamp: timestamp,  // ✅ Always has a timestamp
                        lightReference: lightReference.isEmpty ? "N/A" : lightReference,
                        gridLocation: gridLocation.isEmpty ? "N/A" : gridLocation,
                        siteLocation: siteLocation.isEmpty ? "N/A" : siteLocation,
                        fixtureDetails: fixtureDetails.isEmpty ? "N/A" : fixtureDetails,
                        knownWattage: knownWattage.isEmpty ? "Unknown" : knownWattage,
                        notes: notes.isEmpty ? "No notes" : notes,
                        isFaulty: isFaulty,
                        imageUrl: imageUrl?.absoluteString ?? ""  // ✅ If missing, use empty string
                    ),
                    capturedImage: capturedImage,
                    actionHandler: { action in
                        switch action {
                        case .delete:
                            deleteLocalImage()
                            showReadingDetails = false
                        case .save:
                            saveToFirebase()
                        case .download:
                            print("Download action triggered, but not applicable here.")
                        case .close:  // ✅ Add this case to make the switch exhaustive
                            showReadingDetails = false // ✅ Close the reading card
                        }
                    },

                    displayMode: .saveOrDelete
                )
                .padding()
                .background(Color.gray.opacity(0.9))
                .cornerRadius(20)
                .shadow(radius: 10)
                .transition(.move(edge: .bottom))
                .animation(.spring())
            }


        }
    }

    // MARK: - Functions

    private func requestCameraPermission() {
        lightMeterManager.requestCameraPermission { granted in
            DispatchQueue.main.async {
                hasCameraPermission = granted
                if granted {
                    lightMeterManager.configureSession()
                } else {
                    print("Camera permission denied.")
                }
            }
        }
    }
    
    private func toggleMeasurement() {
        if isMeasuring {
            lightMeterManager.stopMeasuring()
            if let lightLevel = lightMeterManager.lightLevel {
                currentReading = lightLevel
                capturedImage = lightMeterManager.captureCurrentFrame()

                if let capturedImage = capturedImage {
                    let uuid = UUID().uuidString
                    imageLocalUUID = uuid
                    saveImageLocally(image: capturedImage, uuid: uuid)
                }

                // ✅ Show reading card with the image
                withAnimation {
                    showReadingDetails = true
                }
            }
        } else {
            lightMeterManager.startMeasuring()
            showReadingDetails = false  // Hide reading card when restarting measurement
        }
        isMeasuring.toggle()
    }


    private func saveImageLocally(image: UIImage, uuid: String) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            let fileURL = getDocumentsDirectory().appendingPathComponent("\(uuid).jpg")
            try? imageData.write(to: fileURL)
        }
    }

    private func deleteLocalImage() {
        if let uuid = imageLocalUUID {
            let fileURL = getDocumentsDirectory().appendingPathComponent("\(uuid).jpg")
            try? FileManager.default.removeItem(at: fileURL)
            capturedImage = nil
            imageLocalUUID = nil
        }
    }
    
    private func saveToFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ User not authenticated.")
            return
        }

        let db = Firestore.firestore()
        let readingId = UUID().uuidString
        let storageRef = Storage.storage().reference().child("users/\(userId)/readings/\(readingId).jpg")

        if let capturedImage = capturedImage, let imageData = capturedImage.jpegData(compressionQuality: 0.8) {
            print("📸 Uploading Image to Firebase Storage...")

            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("❌ Error uploading image: \(error.localizedDescription)")
                    return
                }

                storageRef.downloadURL { url, error in
                    guard let downloadURL = url else {
                        print("❌ Failed to retrieve image URL.")
                        return
                    }

                    print("✅ Image URL: \(downloadURL.absoluteString)")

                    self.saveReadingToFirestore(
                        userId: userId,
                        readingId: readingId,
                        imageUrl: downloadURL.absoluteString // ✅ Store Image URL
                    )
                }
            }
        } else {
            print("❌ No image found, skipping image upload.")
            self.saveReadingToFirestore(userId: userId, readingId: readingId, imageUrl: nil)
        }
    }

    private func saveReadingToFirestore(userId: String, readingId: String, imageUrl: String?) {
        let db = Firestore.firestore()

        let readingData: [String: Any] = [
            "luxValue": currentReading,
            "timestamp": FieldValue.serverTimestamp(),
            "lightReference": lightReference.isEmpty ? "N/A" : lightReference,
            "gridLocation": gridLocation.isEmpty ? "N/A" : gridLocation,
            "siteLocation": siteLocation.isEmpty ? "N/A" : siteLocation,
            "fixtureDetails": fixtureDetails.isEmpty ? "N/A" : fixtureDetails,
            "knownWattage": knownWattage.isEmpty ? "Unknown" : knownWattage,
            "notes": notes.isEmpty ? "No notes" : notes,
            "isFaulty": isFaulty,
            "imageUrl": imageUrl ?? ""  // ✅ Store Image URL in Firestore
        ]

        db.collection("users").document(userId).collection("readings").document(readingId)
            .setData(readingData) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error saving reading: \(error.localizedDescription)")
                    } else {
                        print("✅ Reading Successfully Saved in Firestore!")
                        feedbackMessage = "✅ Saved Successfully!"
                        
                        withAnimation {
                            showReadingDetails = false  // ✅ Close the card after saving
                        }
                    }
                }
            }
    }


    private func convertToPDFAndSend() {
        guard let capturedImage = capturedImage else {
            feedbackMessage = "No image available to convert to PDF!"
            return
        }

        // Create a PDFDocument
        let pdfDocument = PDFDocument()

        // Add the captured image as a PDF page
        if let pdfPage = PDFPage(image: capturedImage) {
            pdfDocument.insert(pdfPage, at: 0)
        } else {
            feedbackMessage = "Failed to create PDF page from the image."
            return
        }

        // Save the PDF locally
        let fileURL = getDocumentsDirectory().appendingPathComponent("LightMeterReading.pdf")
        do {
            if pdfDocument.write(to: fileURL) {
                feedbackMessage = "PDF created and saved locally at \(fileURL.path)"
                sharePDF(fileURL)
            } else {
                feedbackMessage = "Failed to save the PDF file."
            }
        } catch {
            feedbackMessage = "Error while saving PDF: \(error.localizedDescription)"
        }
    }

    // MARK: - Share PDF
    private func sharePDF(_ fileURL: URL) {
        // Present the system share sheet to share the PDF
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityViewController, animated: true, completion: nil)
        }
    }
    private func formattedTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    // MARK: - Get Documents Directory
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

// Custom Button Style
struct ActionButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
extension Color {
    static let gold = Color(red: 255/255, green: 215/255, blue: 0/255)
}

