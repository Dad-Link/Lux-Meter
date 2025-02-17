import UIKit
import PDFKit

struct GridPDFMaker {
    static func generatePDF(
        jobName: String,
        userGridId: String,
        businessName: String,
        address: String,
        town: String,
        city: String,
        county: String,
        postcode: String,
        startDate: Date,
        from grid: [[LuxCell]],
        title: String,
        businessLogo: UIImage?,
        firstName: String?,
        lastName: String?,
        businessAddress: String?,
        businessEmail: String?,
        businessNumber: String?,
        siteLocation: String?
    ) -> Data? {

        let pdfMetaData = [
            kCGPDFContextCreator: "Lux Meter App",
            kCGPDFContextTitle: title
        ]

        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let padding: CGFloat = 20
        let headerHeight: CGFloat = 200
        let gridPadding: CGFloat = 5.0
        let cellSize: CGFloat = min(25, (pageWidth - 80) / CGFloat(max(grid.first?.count ?? 1, 10)))

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let titleString = NSAttributedString(string: "Heat Map Report", attributes: titleAttributes)
            let titleSize = titleString.size()
            let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2, y: padding, width: titleSize.width, height: titleSize.height)
            titleString.draw(in: titleRect)

            // Logo
            if let logo = businessLogo {
                let logoRect = CGRect(x: (pageWidth - 60) / 2, y: titleRect.maxY + 10, width: 60, height: 60)
                logo.draw(in: logoRect)
            }

            // Business Details
            var currentY = titleRect.maxY + 80
            let textAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]

            let details = [
                "Grid ID: \(userGridId)",
                "Job Reference: \(jobName)",
                "Business/Resident Name: \(businessName)",
                "Street Address: \(address)",
                "Town: \(town)",
                "City: \(city)",
                "County: \(county)",
                "Postcode: \(postcode)",
                "Start Date: \(DateFormatter.localizedString(from: startDate, dateStyle: .medium, timeStyle: .short))"
            ]

            for detail in details.filter({ !$0.isEmpty }) {
                let detailString = NSAttributedString(string: detail, attributes: textAttributes)
                let detailSize = detailString.size()
                let detailRect = CGRect(x: padding, y: currentY, width: detailSize.width, height: detailSize.height)
                detailString.draw(in: detailRect)
                currentY += detailSize.height + 5
            }

            currentY += 20

            // Display grid entries
            let gridEntries = grid.flatMap { $0 }.compactMap { cell -> String? in
                guard let luxValue = cell.luxValue, let lightRef = cell.lightReference else { return nil }
                return "Lux: \(luxValue), Reference: \(lightRef)"
            }.joined(separator: "\n")

            let entriesText = NSAttributedString(string: "Grid Entries (for selected grid):\n\(gridEntries)", attributes: textAttributes)
            let entriesSize = entriesText.size()
            let entriesRect = CGRect(x: padding, y: currentY, width: entriesSize.width, height: entriesSize.height)
            entriesText.draw(in: entriesRect)

            currentY += entriesSize.height + 20

            // Centered Heat Map Grid
            let totalGridWidth = CGFloat(grid.first?.count ?? 0) * (cellSize + gridPadding)
            let startX = (pageWidth - totalGridWidth) / 2

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
        guard let luxValue = lux else { return UIColor.lightGray }

        switch luxValue {
        case 0...100: return UIColor.blue
        case 101...300: return UIColor.green
        case 301...600: return UIColor.yellow
        case 601...1000: return UIColor.orange
        default: return UIColor.red
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
