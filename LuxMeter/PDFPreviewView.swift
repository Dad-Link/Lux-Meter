import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let pdfURL: URL

    var body: some View {
        VStack {
            PDFKitRepresentedView(url: pdfURL)
                .edgesIgnoringSafeArea(.all)
            Button("Share PDF") {
                sharePDF()
            }
            .padding()
        }
    }

    private func sharePDF() {
        let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
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

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
