import SwiftUI
import PDFKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct PDFGeneratorView: View {
    @State private var customTitle: String
    @State private var lightReference: String
    @State private var gridLocation: String
    @State private var siteLocation: String
    @State private var fixtureDetails: String
    @State private var knownWattage: String
    @State private var notes: String
    @State private var isFaulty: Bool
    @State private var showPDFPreview = false
    @State private var generatedPDFURL: URL?
    
    let reading: Reading
    let businessName: String
    let businessAddress: String
    let businessEmail: String
    let businessNumber: String
    let businessLogoURL: String?
    let capturedImage: UIImage?
    
    init(reading: Reading, businessName: String, businessAddress: String, businessEmail: String, businessNumber: String, businessLogoURL: String?, capturedImage: UIImage?) {
        self.reading = reading
        self._customTitle = State(initialValue: reading.lightReference)
        self._lightReference = State(initialValue: reading.lightReference)
        self._gridLocation = State(initialValue: reading.gridLocation)
        self._siteLocation = State(initialValue: reading.siteLocation)
        self._fixtureDetails = State(initialValue: reading.fixtureDetails)
        self._knownWattage = State(initialValue: reading.knownWattage)
        self._notes = State(initialValue: reading.notes)
        self._isFaulty = State(initialValue: reading.isFaulty)
        self.businessName = businessName
        self.businessAddress = businessAddress
        self.businessEmail = businessEmail
        self.businessNumber = businessNumber
        self.businessLogoURL = businessLogoURL
        self.capturedImage = capturedImage
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Customize Your PDF")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            // Custom Title Input
            TextField("Title", text: $customTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // Editable Fields
            VStack(alignment: .leading, spacing: 10) {
                TextField("Light Reference", text: $lightReference)
                TextField("Grid Location", text: $gridLocation)
                TextField("Site Location", text: $siteLocation)
                TextField("Fixture Details", text: $fixtureDetails)
                TextField("Known Wattage", text: $knownWattage)
                TextField("Notes", text: $notes)
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            
            Button(action: generatePDF) {
                Text("Generate PDF")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Show Preview Button
            if let url = generatedPDFURL {
                Button(action: { showPDFPreview = true }) {
                    Text("Preview PDF")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .sheet(isPresented: $showPDFPreview) {
                    PDFPreviewView(pdfURL: url)
                }
            }
        }
        .padding()
    }
    
    func generatePDF() {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            
            let hostingController = UIHostingController(
                rootView: PDFContentView(
                    title: customTitle,
                    reading: reading,
                    businessName: businessName,
                    businessAddress: businessAddress,
                    businessEmail: businessEmail,
                    businessNumber: businessNumber,
                    businessLogoURL: businessLogoURL,
                    capturedImage: capturedImage
                )
            )
            
            hostingController.view.bounds = context.pdfContextBounds
            hostingController.view.drawHierarchy(in: context.pdfContextBounds, afterScreenUpdates: true)
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ReadingDetails.pdf")
        do {
            try pdfData.write(to: tempURL)
            generatedPDFURL = tempURL
            showPDFPreview = true  // ✅ Automatically show preview after generating PDF
        } catch {
            print("❌ Error saving PDF: \(error.localizedDescription)")
        }
    }
    
}



struct PDFContentView: View {
    let title: String
    let reading: Reading
    let businessName: String
    let businessAddress: String
    let businessEmail: String
    let businessNumber: String
    let businessLogoURL: String?
    let capturedImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Business Details
            HStack {
                if let urlString = businessLogoURL, let url = URL(string: urlString) {
                    RemoteImage(urlString: url.absoluteString)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(businessName).font(.title2).bold()
                    Text(businessAddress).font(.subheadline).foregroundColor(.gray)
                    Text(businessEmail).font(.footnote).foregroundColor(.blue)
                    Text(businessNumber).font(.footnote).foregroundColor(.gray)
                }
            }

            Divider()

            // Reading Details
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.title).bold()
                Text("Lux Value: \(String(format: "%.2f", reading.luxValue)) lx").font(.title).foregroundColor(.orange)
                
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(radius: 5)
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
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .padding()
    }
}



struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
