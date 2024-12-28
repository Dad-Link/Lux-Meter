import SwiftUI
import AVFoundation

struct LightMeterView: View {
    @StateObject private var lightMeterManager = LightMeterManager()
    @State private var isMeasuring = false
    @State private var hasCameraPermission = false

    var body: some View {
        VStack {
            // Header
            VStack {
                Text("Light Meter")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("Measure the light intensity in lux.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 30)

            Spacer()

            // Light Measurement Display
            if let lightLevel = lightMeterManager.lightLevel, isMeasuring {
                Text("Light Intensity: \(String(format: "%.2f", lightLevel)) lx")
                    .font(.headline)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
            }

            // Circle Camera Feed
            ZStack {
                Circle()
                    .stroke(lineWidth: 3)
                    .foregroundColor(.blue)
                    .frame(width: 200, height: 200)

                if hasCameraPermission && isMeasuring {
                    CameraLightMeterView(session: lightMeterManager.captureSession)
                        .clipShape(Circle())
                        .frame(width: 200, height: 200)
                } else {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 40)

            Spacer()

            // Control Buttons
            VStack(spacing: 15) {
                Button(action: {
                    if isMeasuring {
                        lightMeterManager.stopMeasuring()
                    } else {
                        lightMeterManager.startMeasuring()
                    }
                    isMeasuring.toggle()
                }) {
                    Text(isMeasuring ? "Stop Measurement" : "Start Measurement")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isMeasuring ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    // Perform back action or navigation
                }) {
                    Text("Back")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .padding()
        .onAppear {
            lightMeterManager.requestCameraPermission { granted in
                DispatchQueue.main.async {
                    hasCameraPermission = granted
                    if granted {
                        lightMeterManager.configureSession()
                    }
                }
            }
        }
        .onDisappear {
            lightMeterManager.stopMeasuring()
        }
        .navigationBarHidden(true) // Hide the navigation bar back button
        .background(Color(.systemGroupedBackground)) // Use UIColor bridge
    }
}
