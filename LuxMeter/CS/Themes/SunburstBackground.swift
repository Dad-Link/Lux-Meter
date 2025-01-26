import SwiftUI


struct SunburstBackground: View {
    @State private var rotation = 0.0

    var body: some View {
        ZStack {
            ForEach(0..<30) { index in
                Rectangle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 2, height: 500)
                    .rotationEffect(Angle(degrees: Double(index) * 12 + rotation))
            }
            .blur(radius: 1)
            .animation(Animation.linear(duration: 10).repeatForever(autoreverses: false), value: rotation)
        }
        .onAppear {
            rotation = 360
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.blue)
    }
}
