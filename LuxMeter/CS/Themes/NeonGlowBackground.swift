import SwiftUI


struct NeonGlowBackground: View {
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.green.opacity(0.3), Color.clear]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 50)
                .offset(x: -100, y: -200)

            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.clear]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 50)
                .offset(x: 150, y: 200)
        }
    }
}
