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
    @State private var imageUrl: String?


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
                                // await saveToFirebase(reading: reading) // Removed - we only save locally now
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
                .background(Color.clear) // ✅ Makes the card blend with the black background
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

                saveImageLocally(image: image, readingId: uuid) { result in
                    switch result {
                    case .success(let fileURLString):
                        let newReading = Reading(
                            id: uuid,
                            luxValue: currentReading,
                            timestamp: Date(),
                            lightReference: "",
                            lightLocation: "",
                            siteLocation: "",
                            fixtureDetails: "",
                            knownWattage: "",
                            notes: "",
                            isFaulty: false,
                            imageUrl: fileURLString,
                            localImagePath: fileURLString
                        )

                        // ✅ Save the reading locally instead of Firebase
                        saveReadingLocally(newReading)

                        reading = newReading // ✅ Update reading instance
                        showReadingDetails = true // ✅ Show reading card after stopping

                    case .failure(let error):
                        print("❌ Image saving failed: \(error.localizedDescription)")
                        feedbackMessage = "❌ Failed to save image. Please try again."
                    }
                }
            }
        } else {
            lightMeterManager.startMeasuring()
            capturedImage = nil
            reading = nil
            showReadingDetails = false
        }
        isMeasuring.toggle()
    }



    private func saveReadingLocally(_ reading: Reading) {
        let fileURL = getDocumentsDirectory().appendingPathComponent("readings.json")

        var readings: [Reading] = loadReadingsLocally()

        if !readings.contains(where: { $0.id == reading.id }) {
            readings.append(reading)
        } else {
            if let index = readings.firstIndex(where: { $0.id == reading.id }) {
                readings[index] = reading
            }
        }

        do {
            let data = try JSONEncoder().encode(readings)
            try data.write(to: fileURL, options: .atomic)
            print("✅ Reading saved locally: \(reading.id)")
        } catch {
            print("❌ Failed to save reading locally: \(error)")
        }
    }



    
    private func loadReadingsLocally() -> [Reading] {
        let fileURL = getDocumentsDirectory().appendingPathComponent("readings.json")

        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }

        return (try? JSONDecoder().decode([Reading].self, from: data)) ?? []
    }

     
    private func saveImageLocally(image: UIImage, readingId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let fileName = "\(readingId).jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            let error = NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data."])
            completion(.failure(error))
            return
        }

        do {
            try data.write(to: fileURL)
            DispatchQueue.main.async { // Maintain async to prevent blocking the UI.
                self.imageUrl = fileURL.path // ✅ Now imageUrl is a valid property
            }
            completion(.success(fileURL.path))
        } catch {
            print("❌ Failed to save image: \(error)")
            completion(.failure(error))
        }
    }

    
    private func deleteLocalImage(id:String) {
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(id).jpg")
        try? FileManager.default.removeItem(at: fileURL)
        capturedImage = nil
        print("🗑️ Local image deleted from: \(fileURL.path)")
        
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
            .frame(maxWidth: 360, maxHeight: 530) // ⬆️ Increased height for better spacing
            .padding()
            .background(color.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
