import SwiftUI
import AVFoundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PDFKit

enum ReadingCardDisplayMode {
    case spinOrDelete // LightMeterView (pos 1)
    case saveOrDelete // LightMeterView (pos 2)
    case deleteOrDownload // ReadingsView (pos 1)
}

struct LightMeterView: View {
    @StateObject private var lightMeterManager = LightMeterManager()
    @State private var isMeasuring = false
    @State private var hasCameraPermission = false
    @State private var showReadingDetails = false
    @State private var currentReading: Float = 0.0
    @State private var feedbackMessage: String?
    @State private var capturedImage: UIImage?
    @State private var reading: Reading?

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

            if showReadingDetails, let reading = reading, let image = capturedImage {
                ReadingCardView(
                    reading: reading,
                    capturedImage: image,
                    actionHandler: { action in
                        switch action {
                        case .delete:
                            print("🗑️ Delete button pressed")
                            deleteLocalImage(id: reading.id)
                            showReadingDetails = false
                        case .save:
                            print("✅ Save button pressed - Calling saveToFirebase()")

                            Task {
                                await saveToFirebase(reading: reading)
                            }
                            showReadingDetails = false
                        case .download:
                            print("⬇️ Download button pressed")
                        case .close:
                            print("❌ Close button pressed")
                            showReadingDetails = false
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
            
            if let lightLevel = lightMeterManager.lightLevel, let image = lightMeterManager.captureCurrentFrame() {
                currentReading = lightLevel
                self.capturedImage = image
                let uuid = UUID().uuidString

                if let fileURL = saveImageLocally(image: image, readingId: uuid) {
                    self.reading = Reading(
                        id: uuid,
                        luxValue: currentReading,
                        timestamp: Date(),
                        lightReference: "N/A",
                        gridLocation: "N/A",
                        siteLocation: "N/A",
                        fixtureDetails: "N/A",
                        knownWattage: "Unknown",
                        notes: "No notes",
                        isFaulty: false,
                        imageUrl: fileURL // ✅ Correctly storing file path
                    )

                    print("📸 Image captured and saved locally at: \(fileURL)")
                } else {
                    print("❌ Failed to save image locally")
                }
            } else {
                self.reading = Reading(
                    id: UUID().uuidString,
                    luxValue: 0,
                    timestamp: Date(),
                    lightReference: "N/A",
                    gridLocation: "N/A",
                    siteLocation: "N/A",
                    fixtureDetails: "N/A",
                    knownWattage: "Unknown",
                    notes: "No notes",
                    isFaulty: false,
                    imageUrl: ""
                )
            }
            showReadingDetails = true
        } else {
            lightMeterManager.startMeasuring()
            capturedImage = nil
            reading = nil
        }
        isMeasuring.toggle()
    }

     
    private func saveImageLocally(image: UIImage, readingId: String) -> String? {
        let fileName = "\(readingId).jpg"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: fileURL)
                return fileURL.path
            } catch {
                print("❌ Failed to save image: \(error)")
            }
        }
        return nil
    }

    
    private func deleteLocalImage(id:String) {
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(id).jpg")
        try? FileManager.default.removeItem(at: fileURL)
        capturedImage = nil
        print("🗑️ Local image deleted from: \(fileURL.path)")
        
    }

    private func saveToFirebase(reading: Reading) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ User not authenticated.")
            feedbackMessage = "❌ User not authenticated."
            return
        }
         await saveReadingToFirestore(userId: userId, reading: reading)
    }


    private func saveReadingToFirestore(userId: String, reading: Reading) async {
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
            "imageUrl": reading.imageUrl
        ]
        print("🚀 Saving data to Firestore with image URL: \(reading.imageUrl)")
        do {
            try await db.collection("users").document(userId).collection("readings").document(reading.id)
                .setData(readingData, merge: true)
           
            print("✅ Firestore save successful with Image URL!")
        } catch {
            print("❌ Firestore save failed: \(error.localizedDescription)")
            
        }
    }


    func captureViewImage(_ view: UIView) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        return renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
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
