import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let pdfURL: URL
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            PDFKitRepresentedView(url: pdfURL)
                .navigationBarTitle("PDF Preview", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                        }
                    }
                }
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(activityItems: [pdfURL])
                }
        }
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            uiView.document = document
        }
    }
}
