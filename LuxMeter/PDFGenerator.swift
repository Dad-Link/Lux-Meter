import PDFKit
import SwiftUI

class PDFGenerator {
    static func generatePDF(reading: Reading, completion: @escaping (URL?) -> Void) {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()

            let hostingController = UIHostingController(
                rootView: PDFContentView(
                    title: reading.lightReference,
                    reading: reading,
                    businessName: "Your Business Name",
                    businessAddress: "Your Address",
                    businessEmail: "email@example.com",
                    businessNumber: "+1234567890",
                    businessLogoURL: nil,
                    capturedImage: nil
                )
            )

            hostingController.view.bounds = context.pdfContextBounds
            hostingController.view.drawHierarchy(in: context.pdfContextBounds, afterScreenUpdates: true)
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ReadingDetails.pdf")
        do {
            try pdfData.write(to: tempURL)
            completion(tempURL)
        } catch {
            print("❌ Error saving PDF: \(error.localizedDescription)")
            completion(nil)
        }
    }
}
