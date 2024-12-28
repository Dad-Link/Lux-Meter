import SwiftUI

struct ReadingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Readings History")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                List {
                    ForEach(1..<11, id: \.self) { index in
                        Text("Reading \(index): \(Double(index * 100)) lx")
                    }
                }
            }
            .navigationTitle("Readings")
        }
    }
}
