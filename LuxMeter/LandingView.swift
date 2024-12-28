import SwiftUI

struct LandingView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // App Title and Description
                    VStack(alignment: .center, spacing: 10) {
                        Text("Lux Meter")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Measure light intensity with precision and ease using our advanced Lux Meter app.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 40)

                    // Section 1
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .foregroundColor(.yellow)
                            .padding(.leading, 20)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Precision Measurements")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("Get accurate readings of light intensity for your environment, whether indoors or outdoors.")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }

                    // Section 2
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("User-Friendly Interface")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("Easily navigate through our app with a clean and intuitive design tailored for everyone.")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)

                        Image(systemName: "rectangle.and.pencil.and.ellipsis")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .foregroundColor(.blue)
                            .padding(.trailing, 20)
                    }

                    // Section 3
                    HStack {
                        Image(systemName: "camera.metering.spot")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .foregroundColor(.green)
                            .padding(.leading, 20)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Advanced Features")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("Leverage cutting-edge technology to enhance your lighting analysis experience.")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }

                    // Button to Enter the App
                    NavigationLink(destination: LightMeterView()) {
                        Text("Enter App")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)

                    // Footer Description
                    Text("Designed with love to bring light measurement to your fingertips. Enhance your experience with the Lux Meter app.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}
