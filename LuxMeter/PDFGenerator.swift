import PDFKit
import UIKit
import FirebaseStorage

class PDFGenerator {

  static func generatePDF(reading: Reading, completion: @escaping (URL?) -> Void) {
        let pdfMetaData = [
            kCGPDFContextCreator: "Light Meter App",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "Light Meter Reading"
        ]
    
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

       let data = renderer.pdfData { (context) in
           context.beginPage()
           addContent(context: context, rect: pageRect, reading: reading)
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


  static func addContent(context: UIGraphicsPDFRendererContext, rect: CGRect, reading: Reading) {

          let titleFont = UIFont.boldSystemFont(ofSize: 24)
          let headingFont = UIFont.boldSystemFont(ofSize: 16)
          let textFont = UIFont.systemFont(ofSize: 14)
        
          let margin: CGFloat = 20
          let availableWidth = rect.width - 2 * margin
          var currentY = margin
        
        let titleAttributes = [NSAttributedString.Key.font: titleFont]
            let titleText = "Light Meter Reading"
          let titleString = NSAttributedString(string: titleText, attributes: titleAttributes)
         let titleRect = CGRect(x: margin, y: currentY, width: availableWidth, height: titleString.size().height)
            titleString.draw(in: titleRect)
         currentY += titleRect.height + 10

       
        let dateFormatter = DateFormatter()
         dateFormatter.dateStyle = .medium
         dateFormatter.timeStyle = .short
        let formattedDate = dateFormatter.string(from: reading.timestamp)
        
        let dateAttributes = [NSAttributedString.Key.font: textFont]
            let dateString = NSAttributedString(string: "Date & Time: \(formattedDate)", attributes: dateAttributes)
        let dateRect = CGRect(x: margin, y: currentY, width: availableWidth, height: dateString.size().height)
        dateString.draw(in: dateRect)
        currentY += dateRect.height + 10
       
        
         let headingAttributes = [NSAttributedString.Key.font: headingFont]
        let textAttributes = [NSAttributedString.Key.font: textFont]
       
        func addText(heading: String, text: String) {
          let headingString = NSAttributedString(string: heading, attributes: headingAttributes)
              let headingRect = CGRect(x: margin, y: currentY, width: availableWidth, height: headingString.size().height)
            headingString.draw(in: headingRect)
            currentY += headingRect.height
            
                
            let textString = NSAttributedString(string: text, attributes: textAttributes)
             let textRect = CGRect(x: margin, y: currentY, width: availableWidth, height: textString.size().height)
                textString.draw(in: textRect)
                currentY += textRect.height + 10
         }

        addText(heading: "Lux Value:", text: "\(String(format: "%.2f", reading.luxValue)) lx")
        addText(heading: "Reference:", text: reading.lightReference)
        addText(heading: "Grid Location:", text: reading.gridLocation)
        addText(heading: "Site Location:", text: reading.siteLocation)
        addText(heading: "Fixture Details:", text: reading.fixtureDetails)
         addText(heading: "Known Wattage:", text: reading.knownWattage)
         addText(heading: "Notes:", text: reading.notes)
         addText(heading: "Faulty:", text: reading.isFaulty ? "Yes" : "No")

        
           if let imageUrlString = reading.imageUrl, let image = loadImageFromPath(path: imageUrlString) {
             let imageAspectRatio = image.size.height / image.size.width
                let maxImageWidth = availableWidth
                let maxImageHeight =  maxImageWidth * imageAspectRatio
                
                let imageRect = CGRect(x: margin, y: currentY, width: maxImageWidth, height: maxImageHeight)
                 image.draw(in: imageRect)
       
          
            } else {
        print("No image URL provided")
         }
    }
  static func loadImageFromPath(path: String) -> UIImage? {
    let url = URL(fileURLWithPath: path)
      if let data = try? Data(contentsOf: url) {
       return UIImage(data: data)
      } else {
         return nil
       }
    }
}
