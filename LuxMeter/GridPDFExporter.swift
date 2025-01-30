import PDFKit
import SwiftUI

struct GridPDFExporter {
    static func generatePDF(from grid: [[LuxCell]], title: String) -> Data {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            let pageBounds = context.pdfContextBounds

            let headerFont = UIFont.boldSystemFont(ofSize: 16)
            let textFont = UIFont.systemFont(ofSize: 12)

            let titleString = NSAttributedString(string: title, attributes: [.font: headerFont])
            titleString.draw(at: CGPoint(x: 20, y: 20))

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm dd/MM/yy"
            let timestampString = NSAttributedString(string: dateFormatter.string(from: Date()), attributes: [.font: textFont])
            timestampString.draw(at: CGPoint(x: 20, y: 40))

            var yPosition: CGFloat = 80

            for row in grid {
                var rowString = ""
                for cell in row {
                    rowString += cell.luxValue != nil ? " * " : "   "
                }
                let rowText = NSAttributedString(string: rowString, attributes: [.font: textFont])
                rowText.draw(at: CGPoint(x: 40, y: yPosition))
                yPosition += 20
                if yPosition > pageBounds.height - 40 { context.beginPage(); yPosition = 40 }
            }
        }
        return pdfData
    }

    static func savePDF(_ data: Data, fileName: String) -> URL? {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).pdf")
        try? data.write(to: fileURL)
        return fileURL
    }
}
