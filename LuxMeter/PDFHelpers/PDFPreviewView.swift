import SwiftUI
import PDFKit
import UIKit

struct PDFPreviewView: View {
    let pdfURL: URL

    var body: some View {
        VStack {
            if FileManager.default.fileExists(atPath: pdfURL.path) {
                PDFKitRepresentedView(url: pdfURL)
            } else {
                VStack {
                    Text("PDF file is missing.")
                        .foregroundColor(.red)
                        .font(.headline)
                    Text("Please try exporting again.")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            print("📂 Opening PDF Preview: \(pdfURL.path)")
        }
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true

        if FileManager.default.fileExists(atPath: url.path) {
            if let document = PDFDocument(url: url) {
                pdfView.document = document
                print("✅ PDF successfully loaded: \(url.path)")
            } else {
                print("❌ Failed to load PDF document")
            }
        } else {
            print("❌ PDF file does not exist at \(url.path)")
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            uiView.document = document
        }
    }
}
