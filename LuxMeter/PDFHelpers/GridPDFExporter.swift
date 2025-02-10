import UIKit
import PDFKit

// MARK: - PDF Export
class GridPDFExporter {
    static func generatePDF(from grid: [[LuxCell]], title: String) -> Data {
        let pdfMetaData = [
            kCGPDFContextTitle: title,
            kCGPDFContextCreator: "Lux Mapper App"
        ]
        
        let pageWidth = 8.5 * 72.0 // 8.5 inches in points
        let pageHeight = 11 * 72.0 // 11 inches in points
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: UIGraphicsPDFRendererFormat())
        
        let pdfData = renderer.pdfData { (context) in
            context.beginPage()
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            
            let titleString = NSAttributedString(string: title, attributes: textAttributes)
            let titleSize = titleString.size()
            let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2, y: 50, width: titleSize.width, height: titleSize.height)
            titleString.draw(in: titleRect)
            
            let gridOriginX = 50.0
            let gridOriginY = titleRect.maxY + 30
            let cellSize: CGFloat = 30.0
            let cellSpacing: CGFloat = 2.0
            
            for (row, rowData) in grid.enumerated(){
                for (col, cellData) in rowData.enumerated() {
                    let x = gridOriginX + CGFloat(col) * (cellSize + cellSpacing)
                    let y = gridOriginY + CGFloat(row) * (cellSize + cellSpacing)
                    let cellRect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                    
                    let cellColor = getColorForLuxValue(cellData.luxValue)
                    cellColor.setFill()
                    context.fill(cellRect)
                    
                    // Add border around the cell for better visibility
                    UIColor.black.setStroke()
                    context.stroke(cellRect)
                    
                    let luxText = cellData.luxValue != nil ? "\(cellData.luxValue!)" : ""
                    let luxAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.black
                    ]
                    let luxString = NSAttributedString(string: luxText, attributes: luxAttributes)
                    let textSize = luxString.size()
                     //Fixed text positioning for better readability
                    let textY = y + (cellSize - textSize.height) / 2
                    
                }
            }
        }
        
        return pdfData
    }
    
    
    private static func getColorForLuxValue(_ lux: Int?) -> UIColor {
        guard let luxValue = lux else {
            return UIColor.lightGray // Default color if luxValue is nil
        }
        switch luxValue {
        case 0...100:
            return UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        case 101...300:
            return UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        case 301...600:
            return UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        case 601...1000:
            return UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        default:
            return UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        }
    }
    
    
    static func savePDF(_ pdfData: Data, fileName: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentDirectory.appendingPathComponent("\(fileName).pdf")
        
        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error writing PDF to file: \(error)")
            return nil
        }
    }
}
