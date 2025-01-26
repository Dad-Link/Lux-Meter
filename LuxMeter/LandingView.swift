import SwiftUI

struct LandingView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.green.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 40) {
                    // App Title and Tagline
                    VStack(spacing: 10) {
                        Text("Lux Meter")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(radius: 5)

                        Text("Measure light intensity with precision and ease using our advanced Lux Meter app.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 60)

                    // Feature Highlights
                    VStack(alignment: .center, spacing: 20) {
                        FunFeatureRow(
                            imageName: "sun.max.fill",
                            title: "Precision Measurements",
                            description: "Get accurate readings for any environment, indoors or outdoors.",
                            backgroundColor: Color.yellow.opacity(0.8)
                        )

                        FunFeatureRow(
                            imageName: "rectangle.and.pencil.and.ellipsis",
                            title: "User-Friendly Interface",
                            description: "Navigate effortlessly with our intuitive and clean design.",
                            backgroundColor: Color.blue.opacity(0.8)
                        )

                        FunFeatureRow(
                            imageName: "camera.metering.spot",
                            title: "Advanced Technology",
                            description: "Harness cutting-edge sensors for reliable and fast results.",
                            backgroundColor: Color.orange.opacity(0.8)
                        )

                        FunFeatureRow(
                            imageName: "chart.bar.fill",
                            title: "Real-Time Analytics",
                            description: "Monitor light levels dynamically and save historical data.",
                            backgroundColor: Color.purple.opacity(0.8)
                        )

                        FunFeatureRow(
                            imageName: "lock.shield.fill",
                            title: "Secure and Private",
                            description: "Your data is safely stored and accessible only to you.",
                            backgroundColor: Color.green.opacity(0.8)
                        )
                    }

                    Spacer()

                    // Navigate to LoginView
                    NavigationLink(destination: LoginView()) {
                        Text("Enter App")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.pink]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)
                            .scaleEffect(1.1)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct FunFeatureRow: View {
    let imageName: String
    let title: String
    let description: String
    let backgroundColor: Color

    var body: some View {
        HStack {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding()
                .background(backgroundColor)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 5)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.leading, 10)
        }
        .padding(.horizontal, 20)
    }
}
