import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PDFKit
import UIKit

struct ReadingCardView: View {
    let actionHandler: (ReadingCardAction) -> Void
    let displayMode: ReadingCardDisplayMode

    @State private var isFlipped = false
    @State private var disableTap = false
    @State private var showPDFPreview = false
    @State private var pdfURL: URL?
    @State private var isGeneratingPDF = false
    @State private var pdfGenerationAttempted = false

    // Editable Fields (Updated on Save)
    @State private var lightReference: String
    @State private var lightLocation: String = ""
    @State private var siteLocation: String
    @State private var fixtureDetails: String
    @State private var knownWattage: String
    @State private var notes: String
    @State private var isFaulty: Bool
    @State private var imageUrl: String?

    let reading: Reading
    let capturedImage: UIImage?

    init(
        reading: Reading,
        capturedImage: UIImage?,
        actionHandler: @escaping (ReadingCardAction) -> Void,
        displayMode: ReadingCardDisplayMode
    ) {
        self.reading = reading
        self.capturedImage = capturedImage
        self.actionHandler = actionHandler
        self.displayMode = displayMode

        _lightReference = State(initialValue: reading.lightReference)
        _lightLocation = State(initialValue: reading.lightLocation)
        _siteLocation = State(initialValue: reading.siteLocation)
        _fixtureDetails = State(initialValue: reading.fixtureDetails)
        _knownWattage = State(initialValue: reading.knownWattage)
        _notes = State(initialValue: reading.notes)
        _isFaulty = State(initialValue: reading.isFaulty)
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
            .frame(maxWidth: 360, maxHeight: 530)
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
            .onAppear {
                // Pre-generate the PDF (if not already attempted)
                // NOTE: We removed auto-show of the PDF preview here.
                if !pdfGenerationAttempted {
                    pdfGenerationAttempted = true
                    generatePDF()
                }
            }

            Spacer()
        }
        // PDFPreviewView is only shown when the user taps Download.
        .sheet(isPresented: $showPDFPreview) {
            if let pdfURL = pdfURL {
                PDFPreviewView(pdfURL: pdfURL)
            }
        }
    }

    // MARK: - Display Card

    private var displayCard: some View {
        VStack(spacing: 12) {
            // Edit Button
            HStack {
                Spacer()
                Button(action: { withAnimation { isFlipped.toggle() } }) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                        .padding(10)
                }
            }
            .padding(.trailing, 10)

            // Display Image
            if let image = getImageForReading() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
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

            // Reading Information
            Text("Lux Value: \(String(format: "%.2f", reading.luxValue)) lx")
                .font(.title2)
                .foregroundColor(.yellow)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 5) {
                Text("🔹 Reference: \(lightReference)").foregroundColor(.yellow).bold()
                Text("📍 Light Location: \(reading.lightLocation)").foregroundColor(.white.opacity(0.8))
                Text("📍 Site Location: \(siteLocation)").foregroundColor(.white.opacity(0.8))
                Text("💡 Fixture: \(fixtureDetails)").foregroundColor(.white.opacity(0.8))
                Text("⚡ Wattage: \(knownWattage)").foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)

            // Action Buttons: Save, Delete, Download
            HStack(spacing: 20) {
                Button(action: { saveReading() }) {
                    Image(systemName: "checkmark.circle.fill")
                        .buttonStyle(.green)
                }
                Button(action: { actionHandler(.delete) }) {
                    Image(systemName: "trash.fill")
                        .buttonStyle(.red)
                }
                Button(action: { openPDFPreview() }) {
                    Image(systemName: "arrow.down.circle.fill")
                        .buttonStyle(.blue)
                }
            }
            .padding(.vertical, 12)

            if isGeneratingPDF {
                ProgressView("Generating PDF...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                    .foregroundColor(.yellow)
                    .padding()
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
        .shadow(radius: 5)
    }

    // MARK: - Edit Card

    private var editCard: some View {
        VStack(spacing: 12) {
            Text("Edit Reading")
                .font(.headline)
                .foregroundColor(.yellow)

            TextField("Reference", text: $lightReference)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Light Location", text: $lightLocation)
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
                Button(action: { saveReading() }) {
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

    // MARK: - Image Helpers

    private func getImageForReading() -> UIImage? {
        if let capturedImage = capturedImage {
            return capturedImage
        }
        if let localImagePath = getLocalImagePath(for: reading.id),
           let localImage = loadImageFromPath(path: localImagePath) {
            return localImage
        }
        return nil
    }

    private func loadImageFromPath(path: String) -> UIImage? {
        let url = URL(fileURLWithPath: path)
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }

    private func getLocalImagePath(for readingId: String) -> String? {
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(readingId).jpg")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL.path
        }
        return nil
    }

    // MARK: - Save Reading

    private func saveReading() {
        var savedReadings = loadReadingsLocally()

        if let index = savedReadings.firstIndex(where: { $0.id == reading.id }) {
            savedReadings[index] = Reading(
                id: reading.id,
                luxValue: reading.luxValue,
                timestamp: Date(),
                lightReference: lightReference,
                lightLocation: lightLocation,
                siteLocation: siteLocation,
                fixtureDetails: fixtureDetails,
                knownWattage: knownWattage,
                notes: notes,
                isFaulty: isFaulty,
                imageUrl: reading.imageUrl,
                localImagePath: reading.localImagePath
            )
        } else {
            savedReadings.append(reading)
        }

        do {
            let data = try JSONEncoder().encode(savedReadings)
            let fileURL = getDocumentsDirectory().appendingPathComponent("readings.json")
            try data.write(to: fileURL, options: [.atomic])

            withAnimation {
                isFlipped = false
                actionHandler(.close)
            }
            print("✅ Reading saved locally!")
        } catch {
            print("❌ Error saving reading: \(error)")
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

    // MARK: - PDF Generation & Preview

    private func generatePDF() {
        isGeneratingPDF = true
        // Use the completion-based PDF generation.
        PDFGenerator.generatePDF(reading: reading) { url in
            DispatchQueue.main.async {
                self.isGeneratingPDF = false
                if let url = url {
                    self.pdfURL = url
                    // NOTE: We no longer auto-show the PDF preview here.
                } else {
                    print("❌ Failed to generate PDF")
                }
            }
        }
    }

    /// Called by the Download button.
    private func openPDFPreview() {
        if pdfURL != nil {
            showPDFPreview = true
        } else {
            // If PDF isn’t ready yet, generate it first and then show the preview.
            generatePDF()
            // Optionally, you can add a delay or a progress indicator here.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.pdfURL != nil {
                    self.showPDFPreview = true
                }
            }
        }
    }
}

// MARK: - Custom Button Styling

extension Image {
    func buttonStyle(_ color: Color) -> some View {
        self.resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .foregroundColor(color)
    }
}
