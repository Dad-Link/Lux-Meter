import SwiftUI
import PDFKit

struct BusinessDetails: View {
    @State private var businessName = ""
    @State private var businessAddress = ""
    @State private var businessEmail = ""
    @State private var businessNumber = ""
    @State private var businessLogo: UIImage?
    @State private var isLoading = false
    @State private var feedbackMessage: FeedbackMessage?
    @State private var showImagePicker = false
    private let logoFilename = "businessLogo.jpg"

    // UserDefaults Keys
    private let businessNameKey = "businessNameKey"
    private let businessAddressKey = "businessAddressKey"
    private let businessEmailKey = "businessEmailKey"
    private let businessNumberKey = "businessNumberKey"

    // State for User Defaults storage
    @AppStorage("storedBusinessName") private var storedBusinessName: String = ""
    @AppStorage("storedBusinessAddress") private var storedBusinessAddress: String = ""
    @AppStorage("storedBusinessEmail") private var storedBusinessEmail: String = ""
    @AppStorage("storedBusinessNumber") private var storedBusinessNumber: String = ""

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    VStack {
                        if let logo = businessLogo {
                            Image(uiImage: logo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                                .onTapGesture {
                                    showImagePicker = true
                                }
                        } else {
                            Circle()
                                .strokeBorder(Color.gold, lineWidth: 2)
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Text("Tap to Add Logo")
                                        .font(.footnote)
                                        .foregroundColor(.gold)
                                )
                                .onTapGesture {
                                    showImagePicker = true
                                }
                        }
                    }
                    .padding(.top)

                    VStack(spacing: 5) {
                        Text("Business Details")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.gold)
                        Text("Add your business details to customize your reports.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Divider().background(Color.gold.opacity(0.5))

                    VStack(spacing: 15) {
                        CustomTextField(title: "Business Name", text: $businessName)
                        CustomTextField(title: "Business Address", text: $businessAddress)
                        CustomTextField(title: "Business Email", text: $businessEmail, keyboardType: .emailAddress)
                        CustomTextField(title: "Business Number", text: $businessNumber, keyboardType: .phonePad)
                    }
                    .padding(.horizontal)

                    Button(action: {
                        saveDetailsLocally()
                        generateAndSaveBusinessDetailsDocument()
                    }) {
                        Text("Save Changes and Generate Document")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gold)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                    }

                    Button(action: clearAllDetails) {
                        Text("Clear All Business Details")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }

                    Link(destination: URL(string: "https://dadlink.co.uk")!) {
                        Text("Powered by DadLink Technologies Limited")
                            .font(.footnote)
                            .foregroundColor(.gold.opacity(0.8))
                            .underline()
                            .padding(.top, 20)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
            }

            if isLoading {
                ProgressView("Saving...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .navigationTitle("Business Details")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $businessLogo, onImagePicked: saveBusinessLogoLocally)
        }
        .onAppear(perform: loadDetailsLocally)
        .onChange(of: businessName) { newValue in storedBusinessName = newValue }
        .onChange(of: businessAddress) { newValue in storedBusinessAddress = newValue }
        .onChange(of: businessEmail) { newValue in storedBusinessEmail = newValue }
        .onChange(of: businessNumber) { newValue in storedBusinessNumber = newValue }
        .alert(item: $feedbackMessage) { message in
            Alert(title: Text("Info"), message: Text(message.text), dismissButton: .default(Text("OK")))
        }
    }

    private func loadDetailsLocally() {
        businessName = storedBusinessName
        businessAddress = storedBusinessAddress
        businessEmail = storedBusinessEmail
        businessNumber = storedBusinessNumber
        loadBusinessLogoLocally()
    }

    private func saveDetailsLocally() {
      
    }
    

    private func generateAndSaveBusinessDetailsDocument() {
        // 1. Create PDF metadata
        let pdfMetaData = [
            kCGPDFContextCreator: "Lux Meter App",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "Business Details"
        ] as [CFString: Any]

        // 2. Define page format
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0 // Standard letter size
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        // 3. Create PDF renderer
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        // 4. Render PDF data
        let data = renderer.pdfData { (context) in
            context.beginPage()
            addBusinessDetailsContent(context: context, rect: pageRect)
        }

        // 5. Get document directory URL
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        // 6. Create file URL
        let fileURL = documentDirectory.appendingPathComponent("BusinessDetails.pdf")

        // 7. Write PDF data to file
        do {
            try data.write(to: fileURL)
            feedbackMessage = FeedbackMessage(text: "Business details document created and saved.")
        } catch {
            feedbackMessage = FeedbackMessage(text: "Error writing PDF to file: \(error.localizedDescription)")
            print("Error writing PDF to file: \(error)")
        }
    }

    private func addBusinessDetailsContent(context: UIGraphicsPDFRendererContext, rect: CGRect) {
        let margin: CGFloat = 20
        let availableWidth = rect.width - 2 * margin
        var currentY = margin

        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let textFont = UIFont.systemFont(ofSize: 14)

        func addText(text: String, font: UIFont, maxWidth: CGFloat) {
            let attributes = [NSAttributedString.Key.font: font]
            let attributedString = NSAttributedString(string: text, attributes: attributes)

            let textRect = CGRect(x: margin, y: currentY, width: maxWidth, height: attributedString.size().height)
            attributedString.draw(in: textRect)
            currentY += attributedString.size().height + 5
        }

        addText(text: "Business Details", font: titleFont, maxWidth: availableWidth)

        if let logo = businessLogo {
            let logoWidth: CGFloat = 100
            let logoHeight: CGFloat = 100
            let logoX = margin
            let logoY = currentY
            let logoRect = CGRect(x: logoX, y: logoY, width: logoWidth, height: logoHeight)

            logo.draw(in: logoRect)
            currentY += logoHeight + 10
        }

        addText(text: "Name: \(businessName)", font: textFont, maxWidth: availableWidth)
        addText(text: "Address: \(businessAddress)", font: textFont, maxWidth: availableWidth)
        addText(text: "Email: \(businessEmail)", font: textFont, maxWidth: availableWidth)
        addText(text: "Number: \(businessNumber)", font: textFont, maxWidth: availableWidth)
    }


    private func clearAllDetails() {

        businessName = ""
        businessAddress = ""
        businessEmail = ""
        businessNumber = ""

        storedBusinessName = ""
        storedBusinessAddress = ""
        storedBusinessEmail = ""
        storedBusinessNumber = ""

        businessLogo = nil

        if let url = getLocalLogoURL() {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("Error deleting logo file: \(error)")
            }
        }
    }

    private func saveBusinessLogoLocally(image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8), let url = getLocalLogoURL() {
            try? data.write(to: url, options: .atomic)
            businessLogo = image
        }
    }

    private func loadBusinessLogoLocally() {
        if let url = getLocalLogoURL(), let data = try? Data(contentsOf: url) {
            businessLogo = UIImage(data: data)
        }
    }

    private func getLocalLogoURL() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(logoFilename)
    }

}

// MARK: - Reusable Custom TextField
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboardType)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            .background(Color.white) // ✅ White Background
            .cornerRadius(10)
            .foregroundColor(.black) // ✅ Black Text
    }
}

// MARK: - FeedbackMessage Struct
struct FeedbackMessage: Identifiable {
    let id = UUID()
    let text: String
}
