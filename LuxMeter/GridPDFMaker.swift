import UIKit
import PDFKit

struct GridPDFMaker {
    static func generatePDF(
        from grid: [[LuxCell]],
        title: String,
        businessLogo: UIImage?,
        businessName: String?,
        firstName: String?,
        lastName: String?,
        businessAddress: String?,
        businessEmail: String?,
        businessNumber: String?,
        siteLocation: String? // ✅ This will now correctly display the Grid Name
    ) -> Data? {

        let pdfMetaData = [
            kCGPDFContextCreator: "Lux Meter App",
            kCGPDFContextTitle: title
        ]
        
        let pageWidth: CGFloat = 595.2 // A4 width (8.27 inches * 72 dpi)
        let pageHeight: CGFloat = 841.8 // A4 height (11.69 inches * 72 dpi)
        let padding: CGFloat = 20
        let headerHeight: CGFloat = 200
        let gridPadding: CGFloat = 5.0 // ✅ Better grid spacing
        let cellSize: CGFloat = min(25, (pageWidth - 80) / CGFloat(max(grid.first?.count ?? 1, 10))) // ✅ Auto-scale grid size
        
        let startX = (pageWidth - CGFloat(grid.first?.count ?? 0) * (cellSize + gridPadding)) / 2
        let startY: CGFloat = headerHeight + 40

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()

            // ✅ Centered Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let titleString = NSAttributedString(string: "Heat Map Report", attributes: titleAttributes)
            let titleSize = titleString.size()
            let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2, y: padding, width: titleSize.width, height: titleSize.height)
            titleString.draw(in: titleRect)

            // ✅ Business Logo (if available)
            if let logo = businessLogo {
                let logoRect = CGRect(x: pageWidth - 80, y: padding, width: 60, height: 60)
                logo.draw(in: logoRect)
            }

            // ✅ Business Details Section
            var currentY = titleRect.maxY + 10
            let textAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            
            func drawText(_ text: String?, yPosition: inout CGFloat) {
                guard let text = text, !text.isEmpty else { return }
                let textRect = CGRect(x: padding, y: yPosition, width: pageWidth - 2 * padding, height: 14)
                text.draw(in: textRect, withAttributes: textAttributes)
                yPosition += 18
            }
            
            drawText(businessName, yPosition: &currentY)
            drawText("\(firstName ?? "") \(lastName ?? "")", yPosition: &currentY)
            drawText(businessAddress, yPosition: &currentY)
            drawText(businessEmail, yPosition: &currentY)
            drawText(businessNumber, yPosition: &currentY)

            currentY += 10
            drawText("📍 Site Location: \(siteLocation ?? "Unknown")", yPosition: &currentY) // ✅ Now displays Grid Name, not UUID

            // ✅ Date & Time
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm dd/MM/yyyy"
            let formattedDate = dateFormatter.string(from: Date())
            drawText("🕒 Generated on: \(formattedDate)", yPosition: &currentY)

            currentY += 20

            // ✅ Heat Map Grid
            for (rowIndex, row) in grid.enumerated() {
                for (colIndex, cell) in row.enumerated() {
                    let cellRect = CGRect(
                        x: startX + CGFloat(colIndex) * (cellSize + gridPadding),
                        y: currentY + CGFloat(rowIndex) * (cellSize + gridPadding),
                        width: cellSize,
                        height: cellSize
                    )
                    
                    let path = UIBezierPath(rect: cellRect)
                    getColorForLuxValue(cell.luxValue).setFill()
                    path.fill()
                    
                    UIColor.black.setStroke()
                    path.stroke()

                    if let lux = cell.luxValue {
                        let luxText = "\(lux)"
                        let luxTextAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10)]
                        let luxAttributedString = NSAttributedString(string: luxText, attributes: luxTextAttributes)
                        let textSize = luxAttributedString.size()
                        let textRect = CGRect(
                            x: cellRect.midX - textSize.width / 2,
                            y: cellRect.midY - textSize.height / 2,
                            width: textSize.width,
                            height: textSize.height
                        )
                        luxAttributedString.draw(in: textRect)
                    }
                }
            }
        }
        
        return data
    }
    
    private static func getColorForLuxValue(_ lux: Int?) -> UIColor {
        guard let luxValue = lux else { return UIColor.lightGray } // Default gray for empty cells

        switch luxValue {
        case 0...100:
            return UIColor.blue  // Low light (blue)
        case 101...300:
            return UIColor.green  // Moderate light (green)
        case 301...600:
            return UIColor.yellow  // Bright light (yellow)
        case 601...1000:
            return UIColor.orange  // Very bright light (orange)
        default:
            return UIColor.red  // Extremely bright (red)
        }
    }

    static func savePDF(_ data: Data, fileName: String) -> URL? {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).pdf")
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }
}
