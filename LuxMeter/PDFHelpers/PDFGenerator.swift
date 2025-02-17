import PDFKit
import UIKit
import FirebaseStorage

class PDFGenerator {

    // Helper function to draw a string with specified attributes and return the drawn height
    static func drawString(_ string: String, in rect: CGRect, with attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let attributedString = NSAttributedString(string: string, attributes: attributes)
        attributedString.draw(in: rect)
        return attributedString.size().height
    }
    
    static func generatePDF(reading: Reading,
                            businessLogo: UIImage? = nil,
                            businessName: String? = nil,
                            firstName: String? = nil,
                            lastName: String? = nil,
                            businessAddress: String? = nil,
                            businessEmail: String? = nil,
                            businessNumber: String? = nil,
                            completion: @escaping (URL?) -> Void) {
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Light Meter App",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "Light Meter Reading"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // A3 size in points (mm to points)
        let pageWidth = 297 * 72 / 25.4
        let pageHeight = 420 * 72 / 25.4
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            addContent(context: context,
                       rect: pageRect,
                       reading: reading,
                       businessLogo: businessLogo,
                       businessName: businessName,
                       firstName: firstName,
                       lastName: lastName,
                       businessAddress: businessAddress,
                       businessEmail: businessEmail,
                       businessNumber: businessNumber)
        }
        
        let fileName = "LightMeterReading.pdf"
        let tempDir = FileManager.default.temporaryDirectory
        let tempFileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempFileURL)
            completion(tempFileURL)
        } catch {
            print("Error writing PDF to temporary directory: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    static func addContent(context: UIGraphicsPDFRendererContext,
                           rect: CGRect,
                           reading: Reading,
                           businessLogo: UIImage?,
                           businessName: String?,
                           firstName: String?,
                           lastName: String?,
                           businessAddress: String?,
                           businessEmail: String?,
                           businessNumber: String?) {
        let margin: CGFloat = 20
        let availableWidth = rect.width - 2 * margin
        let topSectionHeight: CGFloat = 180  // Adjust as needed
        let bottomSectionHeight: CGFloat = 180 // Adjust as needed
        let imageAreaHeight: CGFloat = rect.height - topSectionHeight - bottomSectionHeight - (2 * margin)
        var currentY = margin
        
        //----- Top Section -----
        let topSectionRect = CGRect(x: margin, y: currentY, width: availableWidth, height: topSectionHeight)
        
        // Top Left - Business Information
        let topLeftWidth = availableWidth * 0.5 // 50% of the width
        let topLeftRect = CGRect(x: topSectionRect.minX, y: topSectionRect.minY, width: topLeftWidth, height: topSectionRect.height)
        var topLeftCurrentY = topLeftRect.minY
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm dd/MM/yy"
        let timestampString = dateFormatter.string(from: reading.timestamp)
        
        // Business Logo (optional)
        if let logo = businessLogo {
            let logoHeight: CGFloat = 40 // Adjust as needed
            let logoAspectRatio = logo.size.width / logo.size.height
            let logoWidth = logoHeight * logoAspectRatio
            let logoRect = CGRect(x: topLeftRect.minX, y: topLeftCurrentY, width: logoWidth, height: logoHeight)
            logo.draw(in: logoRect)
            topLeftCurrentY += logoHeight + 5
        }
        
        // Business Name (optional)
        if let name = businessName {
            let businessNameFont = UIFont.boldSystemFont(ofSize: 16)
            let attrs: [NSAttributedString.Key: Any] = [.font: businessNameFont]
            let height = drawString(name, in: CGRect(x: topLeftRect.minX, y: topLeftCurrentY, width: topLeftRect.width, height: 30), with: attrs)
            topLeftCurrentY += height + 5
        }
        
        // User Name (optional)
        if let fName = firstName, let lName = lastName {
            let nameString = "\(fName) \(lName)"
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
            let height = drawString(nameString, in: CGRect(x: topLeftRect.minX, y: topLeftCurrentY, width: topLeftRect.width, height: 20), with: attrs)
            topLeftCurrentY += height + 5
        }
        
        // Business Address (optional)
        if let bAddress = businessAddress {
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
            let height = drawString(bAddress, in: CGRect(x: topLeftRect.minX, y: topLeftCurrentY, width: topLeftRect.width, height: 40), with: attrs)
            topLeftCurrentY += height + 5
        }
       
        // Business Email (optional)
        if let email = businessEmail {
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
            let height = drawString(email, in: CGRect(x: topLeftRect.minX, y: topLeftCurrentY, width: topLeftRect.width, height: 40), with: attrs)
            topLeftCurrentY += height + 5
        }
        
        // Business Number (optional)
        if let number = businessNumber {
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
            let height = drawString(number, in: CGRect(x: topLeftRect.minX, y: topLeftCurrentY, width: topLeftRect.width, height: 40), with: attrs)
            topLeftCurrentY += height + 5
        }
        
        // Top Right
        let topRightWidth = availableWidth * 0.5
        let topRightRect = CGRect(x: topSectionRect.maxX - topRightWidth, y: topSectionRect.minY, width: topRightWidth, height: topSectionRect.height)
        
        // Time
        let timeAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
        _ = drawString(timestampString, in: CGRect(x: topRightRect.minX, y: topRightRect.minY, width: topRightRect.width, height: 20), with: timeAttrs)
        
        // Site Location (using the reading's data)
        let siteLocationAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16)]
        _ = drawString("Site Location: \(reading.siteLocation)", in: CGRect(x: topRightRect.minX, y: topRightRect.minY + 20, width: topRightRect.width, height: 30), with: siteLocationAttrs)
        
        //----- Image Section -----
        currentY += topSectionHeight
        
        // Load and draw the captured image (if available)
        if let imageUrlString = reading.imageUrl,
           let image = loadImageFromPath(path: imageUrlString) {
            
            let imageX = margin
            let imageY = currentY
            let imageWidth = availableWidth
            let imageHeight = imageAreaHeight
            let imageRect = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
            
            image.draw(in: imageRect)
            currentY += imageRect.height
        } else {
            // Handle case where there's no image
            let noImageText = "No Image Available"
            let noImageAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ]
            let noImageSize = (noImageText as NSString).size(withAttributes: noImageAttrs)
            let noImageRect = CGRect(
                x: rect.midX - noImageSize.width / 2,
                y: currentY + imageAreaHeight / 2 - noImageSize.height / 2,
                width: noImageSize.width,
                height: noImageSize.height
            )
            drawString(noImageText, in: noImageRect, with: noImageAttrs)
            currentY += imageAreaHeight
        }
        
        //----- Bottom Section -----
        let bottomSectionRect = CGRect(x: margin, y: currentY, width: availableWidth, height: bottomSectionHeight)
        let bottomTextAreaWidth = availableWidth
        let bottomTextAreaRect = CGRect(x: bottomSectionRect.minX, y: bottomSectionRect.minY, width: bottomTextAreaWidth, height: bottomSectionRect.height)
        
        let textY = bottomTextAreaRect.minY + 10 // Start a little below the top
        var currentTextY = textY
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        
        currentTextY += drawString("🔹 Reference: \(reading.lightReference)", in: CGRect(x: bottomTextAreaRect.minX, y: currentTextY, width: bottomTextAreaWidth, height: 20), with: textAttributes) + 5
        
        currentTextY += drawString("📍 Light Location: \(reading.lightLocation)", in: CGRect(x: bottomTextAreaRect.minX, y: currentTextY, width: bottomTextAreaWidth, height: 20), with: textAttributes) + 5
        
        currentTextY += drawString("📍 Site Location: \(reading.siteLocation)", in: CGRect(x: bottomTextAreaRect.minX, y: currentTextY, width: bottomTextAreaWidth, height: 20), with: textAttributes) + 5
        
        currentTextY += drawString("💡 Fixture Details: \(reading.fixtureDetails)", in: CGRect(x: bottomTextAreaRect.minX, y: currentTextY, width: bottomTextAreaWidth, height: 20), with: textAttributes) + 5
        
        currentTextY += drawString("⚡ Known Wattage: \(reading.knownWattage)", in: CGRect(x: bottomTextAreaRect.minX, y: currentTextY, width: bottomTextAreaWidth, height: 20), with: textAttributes) + 5
        
        currentTextY += drawString("📝 Notes: \(reading.notes)", in: CGRect(x: bottomTextAreaRect.minX, y: currentTextY, width: bottomTextAreaWidth, height: 20), with: textAttributes) + 5
        
        //----- Footer -----
        let footerText = "LuxMeter powered by DADLINK TECHNOLOGIES LIMITED"
        let footerFont = UIFont.systemFont(ofSize: 10)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        let footerString = NSAttributedString(string: footerText, attributes: footerAttributes)
        let footerSize = footerString.size()
        let footerX = (rect.width - footerSize.width) / 2
        let footerY = rect.height - margin - footerSize.height
        footerString.draw(at: CGPoint(x: footerX, y: footerY))
    }
    
    static func loadImageFromPath(path: String) -> UIImage? {
        let url = URL(fileURLWithPath: path)
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }
}
