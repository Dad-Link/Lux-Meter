import SwiftUI
import PDFKit

struct ReadingDetailsPDFView: View {
    @State var customTitle: String // Changed from private to internal
    @State private var showPDFPreview = false
    @State private var generatedPDFURL: URL?

    let readingValue: Float
    @State var lightReference: String
    @State var gridLocation: String
    @State var siteLocation: String
    @State var fixtureDetails: String
    @State var knownWattage: String
    @State var notes: String
    @State var isFaulty: Bool
    let capturedImage: UIImage?

    // Business Details
    let businessName: String
    let businessAddress: String
    let businessEmail: String
    let businessNumber: String
    let businessLogoURL: String

    init(readingValue: Float, lightReference: String, gridLocation: String, siteLocation: String, fixtureDetails: String, knownWattage: String, notes: String, isFaulty: Bool, capturedImage: UIImage?, businessName: String, businessAddress: String, businessEmail: String, businessNumber: String, businessLogoURL: String) {
        self.readingValue = readingValue
        self._lightReference = State(initialValue: lightReference)
        self._gridLocation = State(initialValue: gridLocation)
        self._siteLocation = State(initialValue: siteLocation)
        self._fixtureDetails = State(initialValue: fixtureDetails)
        self._knownWattage = State(initialValue: knownWattage)
        self._notes = State(initialValue: notes)
        self._isFaulty = State(initialValue: isFaulty)
        self.capturedImage = capturedImage
        self.businessName = businessName
        self.businessAddress = businessAddress
        self.businessEmail = businessEmail
        self.businessNumber = businessNumber
        self.businessLogoURL = businessLogoURL
        self._customTitle = State(initialValue: lightReference) // Default title from light reference
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Customize Your PDF")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            // Custom Title Input
            TextField("Title", text: $customTitle)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                .padding(.horizontal)

            // Editable Fields
            VStack(alignment: .leading, spacing: 10) {
                TextField("Light Reference", text: $lightReference)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Grid Location", text: $gridLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Site Location", text: $siteLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Fixture Details", text: $fixtureDetails)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Known Wattage", text: $knownWattage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Notes", text: $notes)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            }

            Button(action: {
                generatePDF { url in
                    DispatchQueue.main.async {
                        generatedPDFURL = url
                        showPDFPreview = true
                    }
                }
            }) {
                Text("Generate PDF")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding(.horizontal)


            // Show Preview Button
            if let url = generatedPDFURL {
                Button(action: {
                    showPDFPreview = true
                }) {
                    Text("Preview PDF")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                .sheet(isPresented: $showPDFPreview) {
                    PDFPreviewView(pdfURL: url)
                }
            }
        }
        .padding()
    }

    func generatePDF(completion: @escaping (URL?) -> Void) {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let data = renderer.pdfData { context in
            context.beginPage()
            let pdfContent = PDFContentView(
                title: customTitle,
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
            let hostingController = UIHostingController(rootView: pdfContent)
            hostingController.view.bounds = context.pdfContextBounds
            hostingController.view.drawHierarchy(in: context.pdfContextBounds, afterScreenUpdates: true)
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ReadingDetails.pdf")
        do {
            try data.write(to: url)
            completion(url) // Return the URL via the completion handler
        } catch {
            print("Error saving PDF: \(error.localizedDescription)")
            completion(nil) // Return nil if there was an error
        }
    }

}

struct PDFContentView: View {
    let title: String
    let readingValue: Float
    let lightReference: String
    let gridLocation: String
    let siteLocation: String
    let fixtureDetails: String
    let knownWattage: String
    let notes: String
    let isFaulty: Bool
    let capturedImage: UIImage?

    let businessName: String
    let businessAddress: String
    let businessEmail: String
    let businessNumber: String
    let businessLogoURL: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Business Details
            HStack {
                if let url = URL(string: businessLogoURL) {
                    RemoteImage(url: url) // Replace with your image loading logic
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(businessName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(businessAddress)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(businessEmail)
                        .font(.footnote)
                        .foregroundColor(.blue)
                    Text(businessNumber)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }

            Divider()

            // Reading Details
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)

                Text("Lux Value: \(String(format: "%.2f", readingValue)) lx")
                    .font(.title)
                    .foregroundColor(.orange)

                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(radius: 5)
                }

                Text("Light Reference: \(lightReference)")
                Text("Grid Location: \(gridLocation)")
                Text("Site Location: \(siteLocation)")
                Text("Fixture Details: \(fixtureDetails)")
                Text("Known Wattage: \(knownWattage)")
                Text("Notes: \(notes)")
                Text("Faulty: \(isFaulty ? "Yes" : "No")")
                    .foregroundColor(isFaulty ? .red : .black)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .padding()
    }
}
