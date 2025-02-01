import UIKit
import PDFKit

class GridPDFExporter {
    static func generatePDF(from gridData: [[LuxCell]], title: String) -> Data {
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
           addContent(context: context, rect: pageRect, gridData: gridData, title: title)
        }
         return data
    }
    
   static func addContent(context: UIGraphicsPDFRendererContext, rect: CGRect, gridData: [[LuxCell]], title: String) {
         let titleFont = UIFont.boldSystemFont(ofSize: 24)
         let headingFont = UIFont.boldSystemFont(ofSize: 16)
         let textFont = UIFont.systemFont(ofSize: 14)
        
         let margin: CGFloat = 20
         let availableWidth = rect.width - 2 * margin
         var currentY = margin

        let titleAttributes = [NSAttributedString.Key.font: titleFont]
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        let titleRect = CGRect(x: margin, y: currentY, width: availableWidth, height: titleString.size().height)
          titleString.draw(in: titleRect)
        currentY += titleRect.height + 20

       
      let columnCount = gridData.first?.count ?? 0
      let rowCount = gridData.count
      let cellWidth: CGFloat = 50
      let cellHeight: CGFloat = 30
      let headerHeight: CGFloat = 20

        
       let startX = margin
        
        var currentX = startX
     
         // Draw Headers
         for col in 0..<columnCount {
            let headerRect = CGRect(x: currentX, y: currentY, width: cellWidth, height: headerHeight)
             
              let headerString = NSAttributedString(string: "Col \(col + 1)", attributes: [NSAttributedString.Key.font: textFont])
             
            headerString.draw(in: headerRect)
              currentX += cellWidth
       }
      currentY += headerHeight + 5
      currentX = startX

         // Draw Grid
      for row in 0..<rowCount {
        let rowY = currentY
       let rowLabel = NSAttributedString(string: "Row \(row+1): ", attributes: [NSAttributedString.Key.font: textFont])
        let rowLabelRect = CGRect(x: margin - 15, y: rowY, width: 70, height: cellHeight)
        rowLabel.draw(in: rowLabelRect)
            
        currentX = startX

        for col in 0..<columnCount {
             let cellRect = CGRect(x: currentX, y: rowY, width: cellWidth, height: cellHeight)
          
            UIColor.black.setStroke() // ✅ Set the stroke color for the context using UIColor
            context.stroke(cellRect)
             
           let cellText = "\(gridData[row][col].luxValue.map{ String($0)} ?? "N/A")"
            let cellAttributes = [NSAttributedString.Key.font: textFont]
             
            let cellTextString = NSAttributedString(string: cellText, attributes: cellAttributes)
             
              let textRect = CGRect(x: currentX + 5, y: rowY , width: cellWidth - 10 , height: cellHeight)
              cellTextString.draw(in: textRect)
            
            let lightReferenceText = "\(gridData[row][col].lightReference ?? "N/A")"
            let lightReferenceTextAttributes = [NSAttributedString.Key.font: textFont]
              
            let lightReferenceTextString = NSAttributedString(string: lightReferenceText, attributes: lightReferenceTextAttributes)
              
              let lightReferenceTextRect = CGRect(x: currentX , y: rowY + 15 , width: cellWidth - 10 , height: cellHeight)
             lightReferenceTextString.draw(in: lightReferenceTextRect)
            

            currentX += cellWidth
        }
          currentY += cellHeight + 2
       }
    }


   static func savePDF(_ pdfData: Data, fileName: String) -> URL? {
       let tempDir = FileManager.default.temporaryDirectory
       let tempFileURL = tempDir.appendingPathComponent("\(fileName).pdf")
       do {
           try pdfData.write(to: tempFileURL)
         return tempFileURL
       } catch {
         print("Error saving PDF: \(error)")
            return nil
       }
    }
}
