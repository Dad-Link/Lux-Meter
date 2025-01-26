import UIKit
import AVFoundation

class LightMeterManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var device: AVCaptureDevice?
    private let sessionQueue = DispatchQueue(label: "LightMeter.SessionQueue")
    private var videoOutput: AVCaptureVideoDataOutput?
    private var currentPixelBuffer: CVPixelBuffer?

    @Published var captureSession = AVCaptureSession()
    @Published var lightLevel: Float?
    
    private var shouldStartSession = false


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
                self.captureSession.sessionPreset = .photo

                let input = try AVCaptureDeviceInput(device: camera)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                } else {
                    print("Cannot add camera input.")
                    self.captureSession.commitConfiguration()
                    return
                }

                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoOutput.Queue"))

                if self.captureSession.canAddOutput(videoOutput) {
                    self.captureSession.addOutput(videoOutput)
                } else {
                    print("Cannot add video output.")
                    self.captureSession.commitConfiguration()
                    return
                }

                self.captureSession.commitConfiguration()
                self.isSessionConfigured = true

                // Only start the session if explicitly requested
                if self.shouldStartSession {
                    self.captureSession.startRunning()
                    print("Capture session started.")
                }
            } catch {
                print("Error configuring session: \(error.localizedDescription)")
            }
        }
    }


    func startMeasuring() {
        sessionQueue.async {
            self.shouldStartSession = true
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                print("Measurement started.")
            }
        }
    }

    func stopMeasuring() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                print("Measurement stopped.")
            }
            self.shouldStartSession = false
        }
        DispatchQueue.main.async {
            self.lightLevel = nil
        }
    }


    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProcessedTime > 0.1 else { return } // Process at ~10 FPS
        lastProcessedTime = currentTime

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        self.currentPixelBuffer = pixelBuffer

        let brightness = computeBrightness(from: pixelBuffer)
        DispatchQueue.main.async {
            self.lightLevel = brightness
            print("Current brightness: \(brightness) lx")
        }
    }

    func captureCurrentFrame() -> UIImage? {
        guard let pixelBuffer = currentPixelBuffer else {
            print("No pixel buffer available for capture.")
            return nil
        }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage from CIImage.")
            return nil
        }
        print("Image successfully captured.")
        return UIImage(cgImage: cgImage)
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
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let bufferPointer = baseAddress.assumingMemoryBound(to: UInt8.self)

        var totalBrightness: Int = 0
        var pixelCount: Int = 0

        let step = 5 // Sampling every 5 pixels for performance
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let pixelOffset = y * bytesPerRow + x * 4
                let blue = bufferPointer[pixelOffset]
                let green = bufferPointer[pixelOffset + 1]
                let red = bufferPointer[pixelOffset + 2]

                // Simple average to determine brightness
                let brightness = (Int(red) + Int(green) + Int(blue)) / 3
                totalBrightness += brightness
                pixelCount += 1
            }
        }

        let averageBrightness = pixelCount > 0 ? Float(totalBrightness) / Float(pixelCount) : 0
        return averageBrightness
    }
}
