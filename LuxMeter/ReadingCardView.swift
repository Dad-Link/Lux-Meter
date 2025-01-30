import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PDFKit

struct ReadingCardView: View {
    let actionHandler: (ReadingCardAction) -> Void
    let displayMode: ReadingCardDisplayMode

    @State private var isFlipped = false
    @State private var disableTap = false
    @State private var showPDFPreview = false
    @State private var pdfURL: URL?

    // Editable Fields (Updated on Save)
    @State private var lightReference: String
    @State private var gridLocation: String
    @State private var siteLocation: String
    @State private var fixtureDetails: String
    @State private var knownWattage: String
    @State private var notes: String
    @State private var isFaulty: Bool
    @State private var timestamp: Date
    @State private var imageUrl: String?

    @State private var reading: Reading
    let capturedImage: UIImage?

    init(
        reading: Reading,
        capturedImage: UIImage?,
        actionHandler: @escaping (ReadingCardAction) -> Void,
        displayMode: ReadingCardDisplayMode
    ) {
        self._reading = State(initialValue: reading)
        self.capturedImage = capturedImage
        self.actionHandler = actionHandler
        self.displayMode = displayMode

        _lightReference = State(initialValue: reading.lightReference)
        _gridLocation = State(initialValue: reading.gridLocation)
        _siteLocation = State(initialValue: reading.siteLocation)
        _fixtureDetails = State(initialValue: reading.fixtureDetails)
        _knownWattage = State(initialValue: reading.knownWattage)
        _notes = State(initialValue: reading.notes)
        _isFaulty = State(initialValue: reading.isFaulty)
        _timestamp = State(initialValue: reading.timestamp)
        _imageUrl = State(initialValue: reading.imageUrl)
    }

    var body: some View {
        VStack {
            Spacer()

            ZStack {
                displayCard
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

                editCard
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }
            .frame(maxWidth: 360, maxHeight: 420)
            .background(Color.black.opacity(0.9))
            .cornerRadius(16)
            .shadow(color: Color.yellow.opacity(0.6), radius: 8)
            .padding(.bottom, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.yellow, lineWidth: 2)
            )
            .onTapGesture {
                if !disableTap {
                    withAnimation {
                        isFlipped.toggle()
                        disableTap = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        disableTap = false
                    }
                }
            }

            Spacer()
        }
        .sheet(isPresented: $showPDFPreview) {
            if let pdfURL = pdfURL {
                PDFPreviewView(pdfURL: pdfURL) // ✅ Show Preview before sharing
            }
        }
    }
    
    // MARK: - Display Card
    private var displayCard: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { withAnimation { isFlipped.toggle() } }) {
                    Image(systemName: "highlighter")
                        .foregroundColor(.yellow)
                        .font(.title3)
                        .padding(10)
                }
            }
            .padding(.top, 6)
            .padding(.trailing, 10)

            // ✅ Display Image (either captured or from Firestore)
            if let capturedImage = capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 5)
            } else if let imageUrl = reading.imageUrl, !imageUrl.isEmpty {
                RemoteImage(urlString: imageUrl) // ✅ Ensure this component is working
                    .scaledToFit()
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 5)
            } else {
                Image(systemName: "photo.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
                    .foregroundColor(.gray)
                    .padding()
            }

            Text("Lux Value: \(String(format: "%.2f", reading.luxValue)) lx")
                .font(.headline)
                .foregroundColor(.yellow)
                .padding(.top, 4)

            VStack(alignment: .leading) {
                Text("Reference: \(lightReference.isEmpty ? "N/A" : lightReference)").foregroundColor(.yellow).bold()
                Text("Grid: \(gridLocation.isEmpty ? "N/A" : gridLocation)").foregroundColor(.white.opacity(0.8))
                Text("Site: \(siteLocation.isEmpty ? "N/A" : siteLocation)").foregroundColor(.white.opacity(0.8))
                Text("Fixture: \(fixtureDetails.isEmpty ? "N/A" : fixtureDetails)").foregroundColor(.white.opacity(0.8))
                Text("Wattage: \(knownWattage.isEmpty ? "N/A" : knownWattage)").foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)

            // ✅ Buttons should always appear at the bottom
            HStack(spacing: 20) {
                Button(action: { saveReading() }) {
                    Image(systemName: "checkmark.circle.fill").buttonStyle(.green)
                }
                Button(action: { actionHandler(.delete) }) {
                    Image(systemName: "trash.fill").buttonStyle(.red)
                }
                Button(action: { generateAndSharePDF() }) {
                    Image(systemName: "arrow.down.circle.fill").buttonStyle(.blue)
                }
            }
            .padding(.vertical, 12)
        }
    }


    // MARK: - Edit Card
    private var editCard: some View {
        VStack(spacing: 12) {
            Text("Edit Reading")
                .font(.headline)
                .foregroundColor(.yellow)

            TextField("Reference", text: $lightReference)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Grid Location", text: $gridLocation)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Site Location", text: $siteLocation)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Fixture Details", text: $fixtureDetails)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Known Wattage", text: $knownWattage)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Notes", text: $notes)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Text("Faulty?")
                    .foregroundColor(.yellow)
                Toggle("", isOn: $isFaulty)
            }
            .padding(.top, 8)

            HStack(spacing: 16) {
                Button(action: { actionHandler(.delete) }) {
                    Image(systemName: "trash.fill").buttonStyle(.red)
                }
                Button(action: {
                    saveReading() // ✅ Save and close card
                }) {
                    Image(systemName: "checkmark.circle.fill").buttonStyle(.green)
                }
            }
            .padding(.top, 12)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: .white.opacity(0.3), radius: 8)
    }

    private func saveReading() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        let updatedData: [String: Any] = [
            "luxValue": reading.luxValue,
            "lightReference": lightReference,
            "gridLocation": gridLocation,
            "siteLocation": siteLocation,
            "fixtureDetails": fixtureDetails,
            "knownWattage": knownWattage,
            "notes": notes,
            "isFaulty": isFaulty,
            "timestamp": FieldValue.serverTimestamp(),
            "imageUrl": imageUrl ?? ""
        ]

        db.collection("users").document(userId).collection("readings").document(reading.id).setData(updatedData, merge: true) { error in
            if error == nil {
                withAnimation {
                    isFlipped = false
                    actionHandler(.close) // ✅ Close after saving
                }
            }
        }
    }


    // MARK: - Generate & Preview PDF
    private func generateAndSharePDF() {
        PDFGenerator.generatePDF(reading: reading) { url in
            DispatchQueue.main.async {
                if let pdfURL = url {
                    self.pdfURL = pdfURL
                    self.showPDFPreview = true // ✅ Shows preview before sharing
                } else {
                    print("❌ Failed to generate PDF")
                }
            }
        }
    }
}

// MARK: - Custom Button Styling
extension Image {
    func buttonStyle(_ color: Color) -> some View {
        self.resizable().scaledToFit().frame(width: 30, height: 30).foregroundColor(color)
    }
}
