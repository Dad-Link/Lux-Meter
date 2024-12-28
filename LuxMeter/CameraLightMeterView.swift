import SwiftUI
import UIKit
import AVFoundation

struct CameraLightMeterView: UIViewRepresentable {
    class LightMeterPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                fatalError("Expected AVCaptureVideoPreviewLayer")
            }
            return layer
        }

        func configurePreviewLayer(with session: AVCaptureSession) {
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
        }
    }

    let session: AVCaptureSession

    func makeUIView(context: Context) -> LightMeterPreviewView {
        let view = LightMeterPreviewView()
        DispatchQueue.main.async {
            view.configurePreviewLayer(with: session)
        }
        return view
    }

    func updateUIView(_ uiView: LightMeterPreviewView, context: Context) {
        DispatchQueue.main.async {
            uiView.configurePreviewLayer(with: session)
        }
    }
}
