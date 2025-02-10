import SwiftUI


struct LightRayBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [Color.yellow.opacity(0.4), Color.orange.opacity(0.1)]),
                center: .center,
                startRadius: 50,
                endRadius: 500
            )
            .edgesIgnoringSafeArea(.all)
            .blur(radius: animate ? 20 : 40)
            .animation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animate)
        }
        .onAppear {
            animate.toggle()
        }
    }
}
