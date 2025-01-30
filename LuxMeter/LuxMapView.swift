import SwiftUI
import MapKit

struct LuxMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var pins: [LuxPin] = []

    var body: some View {
        VStack {
            Map(coordinateRegion: $region, annotationItems: pins) { pin in
                MapPin(coordinate: pin.coordinate, tint: .orange)
            }
            .edgesIgnoringSafeArea(.all)
            .frame(height: 300)

            Button("Add Light Fitting") {
                let newPin = LuxPin(
                    id: UUID(),
                    coordinate: CLLocationCoordinate2D(
                        latitude: region.center.latitude + Double.random(in: -0.001...0.001),
                        longitude: region.center.longitude + Double.random(in: -0.001...0.001)
                    ),
                    luxValue: Int.random(in: 1...100)
                )
                pins.append(newPin)
            }
            .padding()
        }
    }
}

struct LuxPin: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let luxValue: Int
}

struct LuxMapView_Previews: PreviewProvider {
    static var previews: some View {
        LuxMapView()
    }
}
