import SwiftUI
import PDFKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct PDFGenerator {
    struct PDFContentView: View {
        let businessName: String
        let businessAddress: String
        let businessEmail: String
        let businessNumber: String
        let logoURL: URL?
        let reading: Reading
        let capturedImage: UIImage?

        var body: some View {
            VStack(spacing: 20) {
                // Business Header Section
                HStack(alignment: .top) {
                    Spacer() // Align logo to top-right
                    if let logoURL = logoURL {
                        RemoteImage(url: logoURL)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(businessName)
                        .font(.title2)
                        .bold()
                    Text(businessAddress)
                        .font(.body)
                        .foregroundColor(.gray)
                    Text(businessEmail)
                        .font(.footnote)
                        .foregroundColor(.blue)
                    Text(businessNumber)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                Divider()

                // Reading Details Section
                VStack(alignment: .leading, spacing: 10) {
                    VStack {
                        Text("Lux Value")
                            .font(.headline)
                            .bold()
                        Text("\(String(format: "%.2f", reading.luxValue)) lx")
                            .font(.title)
                            .foregroundColor(.orange)
                    }

                    Text("Light Reference: \(reading.lightReference)")
                    Text("Grid Location: \(reading.gridLocation)")
                    Text("Site Location: \(reading.siteLocation)")
                    Text("Fixture Details: \(reading.fixtureDetails)")
                    Text("Known Wattage: \(reading.knownWattage)")
                    Text("Notes: \(reading.notes)")
                    Text("Faulty: \(reading.isFaulty ? "Yes" : "No")")
                        .foregroundColor(reading.isFaulty ? .red : .black)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 5)

                // Reading Image Section
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 5)
                }
            }
            .padding()
        }
    }


    static func generatePDF(
        readingId: String,
        completion: @escaping (URL?) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User ID not available")
            completion(nil)
            return
        }

        let db = Firestore.firestore()
        let storage = Storage.storage().reference()

        // Fetch user business details
        db.collection("users").document(userId).getDocument { userDocument, error in
            guard let userData = userDocument?.data(), error == nil else {
                print("Failed to fetch user details: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            let businessName = userData["businessName"] as? String ?? "N/A"
            let businessAddress = userData["businessAddress"] as? String ?? "N/A"
            let businessEmail = userData["businessEmail"] as? String ?? "N/A"
            let businessNumber = userData["businessNumber"] as? String ?? "N/A"
            let businessLogoURLString = userData["businessLogo"] as? String
            let businessLogoURL = businessLogoURLString != nil ? URL(string: businessLogoURLString!) : nil

            // Fetch reading details
            db.collection("users").document(userId).collection("readings").document(readingId).getDocument { (readingDocument, error) in
                guard let readingData = readingDocument?.data(), error == nil else {
                    print("Failed to fetch reading details: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                    return
                }

                let reading = Reading(
                    id: readingId,
                    luxValue: readingData["luxValue"] as? Float ?? 0.0,
                    timestamp: (readingData["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                    lightReference: readingData["lightReference"] as? String ?? "N/A",
                    gridLocation: readingData["gridLocation"] as? String ?? "N/A",
                    siteLocation: readingData["siteLocation"] as? String ?? "N/A",
                    fixtureDetails: readingData["fixtureDetails"] as? String ?? "N/A",
                    knownWattage: readingData["knownWattage"] as? String ?? "N/A",
                    notes: readingData["notes"] as? String ?? "N/A",
                    isFaulty: readingData["isFaulty"] as? Bool ?? false,
                    imageUrl: readingData["imageUrl"] as? String
                )

                // Handle reading image
                if let imageUrl = reading.imageUrl {
                    storage.child(imageUrl).downloadURL { (url, error) in
                        if let imageUrl = url {
                            URLSession.shared.dataTask(with: imageUrl) { (data, _, _) in
                                var capturedImage: UIImage? = nil
                                if let data = data {
                                    capturedImage = UIImage(data: data)
                                }
                                DispatchQueue.main.async {
                                    renderPDF(
                                        businessName: businessName,
                                        businessAddress: businessAddress,
                                        businessEmail: businessEmail,
                                        businessNumber: businessNumber,
                                        businessLogoURL: businessLogoURL,
                                        reading: reading,
                                        capturedImage: capturedImage,
                                        completion: completion
                                    )
                                }
                            }.resume()
                        } else {
                            renderPDF(
                                businessName: businessName,
                                businessAddress: businessAddress,
                                businessEmail: businessEmail,
                                businessNumber: businessNumber,
                                businessLogoURL: businessLogoURL,
                                reading: reading,
                                capturedImage: nil,
                                completion: completion
                            )
                        }
                    }
                } else {
                    renderPDF(
                        businessName: businessName,
                        businessAddress: businessAddress,
                        businessEmail: businessEmail,
                        businessNumber: businessNumber,
                        businessLogoURL: businessLogoURL,
                        reading: reading,
                        capturedImage: nil,
                        completion: completion
                    )
                }
            }

        }
    }

    private static func renderPDF(
        businessName: String,
        businessAddress: String,
        businessEmail: String,
        businessNumber: String,
        businessLogoURL: URL?,
        reading: Reading,
        capturedImage: UIImage?,
        completion: @escaping (URL?) -> Void
    ) {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595.2, height: 841.8))
        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()

            let hostingController = UIHostingController(
                rootView: PDFContentView(
                    businessName: businessName,
                    businessAddress: businessAddress,
                    businessEmail: businessEmail,
                    businessNumber: businessNumber,
                    logoURL: businessLogoURL,
                    reading: reading,
                    capturedImage: capturedImage
                )
            )

            hostingController.view.bounds = context.pdfContextBounds
            hostingController.view.drawHierarchy(in: context.pdfContextBounds, afterScreenUpdates: true)
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ReadingDetails.pdf")
        do {
            try pdfData.write(to: tempURL)
            completion(tempURL)
        } catch {
            print("Failed to generate PDF: \(error)")
            completion(nil)
        }
    }
}
