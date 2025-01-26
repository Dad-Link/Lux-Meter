import SwiftUI
import AVFoundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PDFKit

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


    var dynamicBackground: LinearGradient {
        let intensity = Double(min(max(currentReading / 1000, 0.1), 1.0))
        return LinearGradient(
            gradient: Gradient(colors: [Color.purple.opacity(intensity), Color.blue.opacity(1 - intensity)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            // Dynamic Background
            dynamicBackground.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header
                VStack {
                    Text("Light Meter")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    Text("Measure the light intensity in lux.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 30)
                
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
                        .stroke(lineWidth: 3)
                        .foregroundColor(.blue)
                        .frame(width: 220, height: 220)
                    
                    if hasCameraPermission && isMeasuring {
                        CameraLightMeterView(session: lightMeterManager.captureSession)
                            .clipShape(Circle())
                            .frame(width: 200, height: 200)
                    } else {
                        Image(systemName: "camera.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 40)
                
                // Start/Stop Button
                Button(action: toggleMeasurement) {
                    Text(isMeasuring ? "Stop" : "Start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isMeasuring ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
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
                VStack(spacing: 16) {
                    // Dismiss Chevron
                    Image(systemName: "chevron.compact.down")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                        .onTapGesture {
                            withAnimation {
                                showReadingDetails = false
                            }
                        }
                        .padding(.top, 20)
                    
                    // Reading Details Card
                    VStack(spacing: 16) {
                        // Display Image
                        if let capturedImage = capturedImage {
                            Image(uiImage: capturedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .cornerRadius(12)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Editable Fields
                            TextField("Enter Light Reference", text: $reference)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                            
                            TextField("Enter Grid Location", text: $gridLocation)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                            
                            TextField("Enter Site Location", text: $siteLocation)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                            
                            TextField("Fixture Details", text: $fixtureDetails)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                            
                            TextField("Enter Known Wattage", text: $knownWattage)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                            
                            Toggle("Is Faulty", isOn: $isFaulty)
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                                .padding(.horizontal)
                            
                            Text("Lux Value: \(String(format: "%.2f", currentReading)) lx")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .padding(.bottom, 8)
                        
                        // Action Buttons
                        HStack(spacing: 10) {
                            Button("Save") {
                                saveToFirebase()
                                showReadingDetails = false
                            }
                            .buttonStyle(ActionButtonStyle(color: .green))
                            
                            Button("Delete") {
                                deleteLocalImage()
                                showReadingDetails = false
                            }
                            .buttonStyle(ActionButtonStyle(color: .red))
                            
                            Button("Convert to PDF") {
                                convertToPDFAndSend()
                            }
                            .buttonStyle(ActionButtonStyle(color: .blue))
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding()
                }
                .frame(maxWidth: 400)
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

                // Save captured image locally with UUID
                if let capturedImage = capturedImage {
                    let uuid = UUID().uuidString
                    imageLocalUUID = uuid
                    saveImageLocally(image: capturedImage, uuid: uuid)
                }

                // Only show the details card when a valid reading is captured
                if capturedImage != nil {
                    withAnimation {
                        showReadingDetails = true
                    }
                }
            }
        } else {
            lightMeterManager.startMeasuring()
            showReadingDetails = false // Hide card when starting measurement
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
            print("User not authenticated.")
            return
        }

        let db = Firestore.firestore()
        let readingId = UUID().uuidString // Generate a unique ID for the reading
        let storageRef = Storage.storage().reference().child("users/\(userId)/readings/\(readingId).jpg")

        if let capturedImage = capturedImage, let imageData = capturedImage.jpegData(compressionQuality: 0.8) {
            // Upload image to Firebase Storage
            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    return
                }

                storageRef.downloadURL { url, error in
                    guard let downloadURL = url else {
                        print("Failed to retrieve download URL.")
                        return
                    }

                    // Save reading data to Firestore
                    self.saveReadingToFirestore(userId: userId, readingId: readingId, imageUrl: downloadURL.absoluteString)
                }
            }
        } else {
            // Save without image
            saveReadingToFirestore(userId: userId, readingId: readingId, imageUrl: nil)
        }
    }

    private func saveReadingToFirestore(userId: String, readingId: String, imageUrl: String?) {
        let db = Firestore.firestore()
        let readingData: [String: Any] = [
            "luxValue": currentReading,
            "timestamp": FieldValue.serverTimestamp(),
            "location": gridLocation,
            "siteLocation": siteLocation,
            "address": address,
            "reference": reference,
            "fixtureDetails": fixtureDetails,
            "knownWattage": knownWattage,
            "notes": notes,
            "isFaulty": isFaulty,
            "imageUrl": imageUrl ?? ""
        ]


        db.collection("users").document(userId).collection("readings").document(readingId).setData(readingData) { error in
            if let error = error {
                print("Error saving reading to Firestore: \(error.localizedDescription)")
            } else {
                print("Reading successfully saved to Firestore!")
                feedbackMessage = "Reading saved successfully!"
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
