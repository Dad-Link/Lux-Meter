import SwiftUI
import SceneKit

// 🔥 3D Heatmap View with Full Rotation Support
struct Heatmap3DView: UIViewRepresentable {
    var luxGrid: [[Int]]

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = generateScene()
        sceneView.allowsCameraControl = true // ✅ Allow pinch/rotate
        sceneView.autoenablesDefaultLighting = true // ✅ Better visibility
        sceneView.backgroundColor = .black

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    private func generateScene() -> SCNScene {
        let scene = SCNScene()
        let gridWidth = luxGrid.first?.count ?? 0
        let gridHeight = luxGrid.count
        let tileSize: CGFloat = 1.0

        // ✅ Create a parent node for better positioning
        let gridNode = SCNNode()

        for row in 0..<gridHeight {
            for col in 0..<gridWidth {
                let lux = luxGrid[row][col]
                let height = CGFloat(lux) * 0.05

                let tile = SCNBox(width: tileSize, height: height, length: tileSize, chamferRadius: 0.1)
                
                // ✅ Double-Sided Rendering Fix
                tile.firstMaterial?.isDoubleSided = true
                tile.firstMaterial?.diffuse.contents = getColorForLux(lux)

                let node = SCNNode(geometry: tile)
                node.position = SCNVector3(Float(col) * 1.2, Float(height / 2), Float(row) * 1.2)
                gridNode.addChildNode(node)
            }
        }

        // ✅ Center the grid
        gridNode.position = SCNVector3(-Float(gridWidth) * 0.6, 0, -Float(gridHeight) * 0.6)
        scene.rootNode.addChildNode(gridNode)

        // ✅ Improved Camera with Full 360° View
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 8, 8) // ✅ Default top view
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 6, 0, 0) // ✅ Slight downward tilt
        scene.rootNode.addChildNode(cameraNode)

        // ✅ Main Light for Visibility
        let light = SCNLight()
        light.type = .omni
        light.intensity = 1500 // ✅ Brighter light
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0, 10, 10)
        scene.rootNode.addChildNode(lightNode)

        // ✅ Backlight for Underneath View
        let backLight = SCNLight()
        backLight.type = .omni
        backLight.intensity = 1000 // ✅ Light for viewing from below
        let backLightNode = SCNNode()
        backLightNode.light = backLight
        backLightNode.position = SCNVector3(0, -10, 10) // ✅ Positioned below the grid
        scene.rootNode.addChildNode(backLightNode)

        return scene
    }

    private func getColorForLux(_ lux: Int) -> UIColor {
        switch lux {
        case 0...100: return UIColor.blue
        case 101...300: return UIColor.green
        case 301...600: return UIColor.yellow
        case 601...1000: return UIColor.red
        default: return UIColor.white
        }
    }
}
