import AVFoundation
import Combine

class LightMeterManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var device: AVCaptureDevice?
    private let sessionQueue = DispatchQueue(label: "LightMeter.SessionQueue")
    private var videoOutput: AVCaptureVideoDataOutput?

    @Published var captureSession = AVCaptureSession()
    @Published var lightLevel: Float?

    private var lastProcessedTime: CFTimeInterval = CACurrentMediaTime()

    
    private var isSessionConfigured = false

    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        default:
            completion(false)
        }
    }

    func configureSession() {
        sessionQueue.async {
            guard let camera = self.defaultCamera(), !self.isSessionConfigured else { return }
            self.device = camera

            do {
                self.captureSession.beginConfiguration()
                self.captureSession.sessionPreset = .medium // Adjust preset for smoother performance

                let input = try AVCaptureDeviceInput(device: camera)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }

                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ] // Ensure BGRA format for compatibility
                videoOutput.alwaysDiscardsLateVideoFrames = true // Discard late frames for smoother performance
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoOutput.Queue"))

                if self.captureSession.canAddOutput(videoOutput) {
                    self.captureSession.addOutput(videoOutput)
                }

                self.captureSession.commitConfiguration()
                self.isSessionConfigured = true
            } catch {
                print("Error configuring session: \(error.localizedDescription)")
            }
        }
    }


    func startMeasuring() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func stopMeasuring() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
        lightLevel = nil
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProcessedTime > 0.1 else { return } // Process every 100ms
        lastProcessedTime = currentTime

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let brightness = computeBrightness(from: pixelBuffer)
        DispatchQueue.main.async {
            self.lightLevel = brightness
        }
    }

    private func defaultCamera() -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    private func computeBrightness(from pixelBuffer: CVPixelBuffer) -> Float {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
              CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA else {
            return 0
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        // Safely process a smaller sample of pixels
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let bufferPointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        var totalBrightness: Int = 0
        var pixelCount = 0

        // Iterate through a grid of pixels (e.g., every 5th pixel)
        let step = 5
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let pixelOffset = y * bytesPerRow + x * 4
                let blue = bufferPointer[pixelOffset]
                let green = bufferPointer[pixelOffset + 1]
                let red = bufferPointer[pixelOffset + 2]

                // Calculate luminance (simple average of R, G, B)
                let brightness = (Int(red) + Int(green) + Int(blue)) / 3
                totalBrightness += brightness
                pixelCount += 1
            }
        }

        // Compute average brightness
        return pixelCount > 0 ? Float(totalBrightness) / Float(pixelCount) : 0
    }
}
