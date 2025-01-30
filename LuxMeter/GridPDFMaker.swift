import SwiftUI
import Firebase
import PDFKit

struct GridPDFMaker {
    static func generatePDF(from grid: [[LuxCell]], title: String) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Room Grid",
            kCGPDFContextAuthor: "LuxMeter App"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let gridCellSize: CGFloat = 30
        let padding: CGFloat = 20
        let startX = (pageWidth - (CGFloat(grid.first?.count ?? 0) * gridCellSize)) / 2
        let startY: CGFloat = 100
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let titleString = NSAttributedString(string: title, attributes: titleAttributes)
            let titleSize = titleString.size()
            let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2, y: padding, width: titleSize.width, height: titleSize.height)
            titleString.draw(in: titleRect)
            
            for (rowIndex, row) in grid.enumerated() {
                for (colIndex, cell) in row.enumerated() {
                    let cellRect = CGRect(
                        x: startX + CGFloat(colIndex) * gridCellSize,
                        y: startY + CGFloat(rowIndex) * gridCellSize,
                        width: gridCellSize,
                        height: gridCellSize
                    )
                    
                    let path = UIBezierPath(rect: cellRect)
                    UIColor.black.setStroke()
                    path.stroke()
                    
                    if let lux = cell.luxValue {
                        let luxText = "\(lux)"
                        let attributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 12),
                            .foregroundColor: UIColor.black
                        ]
                        let luxAttributedString = NSAttributedString(string: luxText, attributes: attributes)
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
