import SwiftUI

struct DragLightFittingsView: View {
    @State private var lightFittings: [LightFitting] = []
    @State private var draggingLight: LightFitting?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                Color.white.edgesIgnoringSafeArea(.all)

                ForEach(lightFittings) { fitting in
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 50, height: 50)
                        .position(fitting.position)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if let index = lightFittings.firstIndex(where: { $0.id == fitting.id }) {
                                        lightFittings[index].position = value.location
                                    }
                                }
                        )
                }

                // Add light fitting button
                VStack {
                    Spacer()
                    Button("Add Light Fitting") {
                        let newFitting = LightFitting(
                            id: UUID(),
                            position: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
                            luxValue: Int.random(in: 1...100)
                        )
                        lightFittings.append(newFitting)
                    }
                    .padding()
                }
            }
        }
    }
}

struct LightFitting: Identifiable {
    let id: UUID
    var position: CGPoint
    var luxValue: Int
}

struct DragLightFittingsView_Previews: PreviewProvider {
    static var previews: some View {
        DragLightFittingsView()
    }
}
