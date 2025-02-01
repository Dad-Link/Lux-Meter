import SwiftUI
import PDFKit
import UIKit

struct PDFPreviewView: View {
  let pdfURL: URL

    var body: some View {
     PDFKitRepresentedView(url: pdfURL)
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
  let url: URL

  func makeUIView(context: Context) -> PDFView {
     let pdfView = PDFView()
       pdfView.document = PDFDocument(url: url)
       pdfView.autoScales = true
      return pdfView
    }

  func updateUIView(_ uiView: PDFView, context: Context) {
     //nothing to update
    }
}
