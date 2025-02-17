import SwiftUI

struct LandingView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.gold.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 35) {
                    VStack(spacing: 8) {
                        Text("Lux Meter")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.gold)
                            .shadow(color: .gold.opacity(0.8), radius: 10, x: 0, y: 5)

                        Text("Measure light intensity with precision and ease using our advanced Lux Meter app.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 40)

                    VStack(alignment: .center, spacing: 18) {
                        FunFeatureRow(imageName: "sun.max.fill", title: "Precision Measurements", description: "Get accurate readings for any environment, indoors or outdoors.")
                        FunFeatureRow(imageName: "rectangle.and.pencil.and.ellipsis", title: "User-Friendly Interface", description: "Navigate effortlessly with our intuitive and clean design.")
                        FunFeatureRow(imageName: "camera.metering.spot", title: "Advanced Technology", description: "Harness cutting-edge sensors for reliable and fast results.")
                        FunFeatureRow(imageName: "chart.bar.fill", title: "Real-Time Analytics", description: "Monitor light levels dynamically and save historical data.")
                        FunFeatureRow(imageName: "lock.shield.fill", title: "Secure and Private", description: "Your data is safely stored and accessible only to you.")
                    }

                    Spacer()

                    // Directly navigate to the app
                    NavigationLink(destination: MainTabView()) {
                        Text("Enter App")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gold, Color.orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.black)
                            .cornerRadius(15)
                            .shadow(color: Color.gold.opacity(0.5), radius: 10, x: 0, y: 10)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 30)
                    }
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct FunFeatureRow: View {
    let imageName: String
    let title: String
    let description: String

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.6)) // Darker background for better contrast
                    .frame(width: 75, height: 75)

                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.yellow) // Changed to yellow for high contrast
            }
            .overlay(
                Circle().stroke(Color.gold, lineWidth: 3) // Gold border
            )
            .shadow(color: .gold.opacity(0.5), radius: 5)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gold)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.leading, 10)
        }
        .padding(.horizontal, 20)
    }
}
