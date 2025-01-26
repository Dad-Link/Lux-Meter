import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MessageUI

struct ReadingDetailsView: View {
    let readingId: String
    let readingValue: Float
    let customTitle: String // Use as a plain string
    @Binding var lightReference: String
    @Binding var gridLocation: String
    @Binding var siteLocation: String
    @Binding var fixtureDetails: String
    @Binding var knownWattage: String
    @Binding var notes: String
    @Binding var isFaulty: Bool
    let capturedImage: UIImage?
    let imageUrl: String?

    @Environment(\.presentationMode) var presentationMode
    @State private var showPDFPreview = false
    @State private var generatedPDFURL: URL?
    @State private var isCompilingPDF = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 12) {
                // Header
                header

                // Reading Metadata
                metadataFields

                // Captured Image Section
                imageSection

                // Input Fields
                inputFields

                // Action Buttons
                actionButtons
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(15)
            .shadow(radius: 10)
            .frame(width: 350, height: 600)

            if isCompilingPDF {
                ProgressView("Compiling PDF...")
            }
        }
        .sheet(isPresented: $showPDFPreview) {
            if let pdfURL = generatedPDFURL {
                PDFPreviewView(pdfURL: pdfURL)
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Spacer()
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
        }
        .padding(.trailing, 8)
    }

    private var metadataFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lux Value: \(String(format: "%.2f", readingValue)) lx")
                .font(.headline)
                .foregroundColor(.black)

            Text("Light Reference: \(lightReference.isEmpty ? "N/A" : lightReference)")
                .font(.subheadline)

            Text("Grid Location: \(gridLocation.isEmpty ? "N/A" : gridLocation)")
                .font(.subheadline)

            Text("Site Location: \(siteLocation.isEmpty ? "N/A" : siteLocation)")
                .font(.subheadline)

            Text("Fixture Details: \(fixtureDetails.isEmpty ? "N/A" : fixtureDetails)")
                .font(.subheadline)

            Text("Known Wattage: \(knownWattage.isEmpty ? "N/A" : knownWattage)")
                .font(.subheadline)

            Text("Notes: \(notes.isEmpty ? "N/A" : notes)")
                .font(.subheadline)

            Text("Faulty: \(isFaulty ? "Yes" : "No")")
                .font(.subheadline)
                .foregroundColor(isFaulty ? .red : .black)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private var imageSection: some View {
        Group {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            } else if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                AsyncImageView(url: url)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                placeholderImage
            }
        }
        .padding(.bottom, 8)
    }


    private var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .foregroundColor(.gray)
    }

    private var inputFields: some View {
        VStack(spacing: 8) {
            TextField("Light Reference", text: $lightReference)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Grid Location", text: $gridLocation)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Site Location", text: $siteLocation)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Fixture Details", text: $fixtureDetails)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Known Wattage", text: $knownWattage)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Toggle("Mark as Faulty", isOn: $isFaulty)
                .toggleStyle(SwitchToggleStyle(tint: .red))

            TextEditor(text: $notes)
                .frame(height: 60)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 0.5)
                )
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button(action: deleteReading) {
                    Text("Delete")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: saveReading) {
                    Text("Save")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            Button(action: generatePDFPreview) {
                Text("Preview & Send PDF")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Functions

    private func deleteReading() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("readings").document(readingId).delete { error in
            if let error = error {
                print("Failed to delete reading: \(error.localizedDescription)")
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    private func saveReading() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("readings").document(readingId).setData([
            "lightReference": lightReference,
            "gridLocation": gridLocation,
            "siteLocation": siteLocation,
            "fixtureDetails": fixtureDetails,
            "knownWattage": knownWattage,
            "notes": notes,
            "isFaulty": isFaulty,
            "timestamp": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                print("Error updating reading: \(error.localizedDescription)")
            } else {
                print("Reading updated successfully.")
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    private func generatePDFPreview() {
        isCompilingPDF = true // Show progress indicator

        // Mock or replace these with actual data from Firebase
        let businessName = "Business Name"
        let businessAddress = "123 Business Street, City, Country"
        let businessEmail = "contact@business.com"
        let businessNumber = "+123 456 7890"
        let businessLogoURL = "https://example.com/logo.png"

        let renderer = ReadingDetailsPDFView(
            readingValue: readingValue,
            lightReference: lightReference,
            gridLocation: gridLocation,
            siteLocation: siteLocation,
            fixtureDetails: fixtureDetails,
            knownWattage: knownWattage,
            notes: notes,
            isFaulty: isFaulty,
            capturedImage: capturedImage,
            businessName: businessName,
            businessAddress: businessAddress,
            businessEmail: businessEmail,
            businessNumber: businessNumber,
            businessLogoURL: businessLogoURL
        )

        renderer.generatePDF { url in
            DispatchQueue.main.async {
                isCompilingPDF = false // Hide progress indicator
                generatedPDFURL = url
                showPDFPreview = true
            }
        }

    }
}
