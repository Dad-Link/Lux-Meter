import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SceneKit

struct RoomGridContainerView: View {
    @State private var is3DView = false // 🔥 Toggle between 2D & 3D view
    @State private var luxGrid: [[LuxCell]] = Array(
        repeating: Array(repeating: LuxCell(), count: 8),
        count: 20
    )

    var body: some View {
        VStack {
            // 🔥 Header (Hide Toggle in Room View)
            HStack {
                Text(is3DView ? "Heatmap 3D View" : "Room Map")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)

                Spacer()

                // ✅ Show Toggle **ONLY** when in 3D View
                if is3DView {
                    Toggle("Back to Room", isOn: $is3DView)
                        .toggleStyle(SwitchToggleStyle(tint: .gold))
                        .labelsHidden()
                        .padding()
                        .transition(.opacity) // Smooth transition
                        .animation(.easeInOut)
                }
            }
            .padding(.horizontal)

            // 🔄 Conditional View: 2D Grid OR 3D Heatmap
            if is3DView {
                // ✅ Show 3D View with toggle visible
                Heatmap3DView(luxGrid: luxGrid.map { $0.map { $0.luxValue ?? 0 } }) // Convert LuxCell to Int
                    .transition(.opacity)
                    .animation(.easeInOut)
            } else {
                // ✅ Show 2D Grid, hiding the toggle
                RoomGridView(luxGrid: $luxGrid, is3DView: $is3DView)
                    .transition(.opacity)
                    .animation(.easeInOut)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// 🔥 LuxCell Model
struct LuxCell {
    var luxValue: Int? = nil
    var lightReference: String? = nil
}
