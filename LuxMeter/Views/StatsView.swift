import SwiftUI
import UIKit
import FirebaseFirestore

struct StatsView: View {
    @Binding var luxGrid: [String: LuxCell]
    @Binding var useCircleCells: Bool
    @Environment(\.dismiss) var dismiss
    
    // Input for measurement.
    @State private var cellArea: Double = 1.0      // m² per cell
    @State private var naturalLight: Double = 0.0    // Outdoor lux (for daylight factor)
    @State private var luminaireWattage: Double = 0.0  // in watts
    
    // Computed metrics.
    var totalLux: Int {
         luxGrid.values.compactMap { $0.luxValue }.reduce(0, +)
    }
    var numberOfCells: Int { luxGrid.count }
    var averageLux: Double { numberOfCells > 0 ? Double(totalLux) / Double(numberOfCells) : 0.0 }
    var totalLumens: Double { Double(totalLux) * cellArea }
    var complianceMessage: String {
         if averageLux < 300 {
            return "Below recommended levels for office work."
         } else if averageLux > 500 {
            return "Above recommended levels for office work."
         } else {
            return "Within recommended levels for office work."
         }
    }
    var daylightFactor: Double { naturalLight > 0 ? (averageLux / naturalLight) * 100 : 0.0 }
    var efficiency: Double { luminaireWattage > 0 ? totalLumens / luminaireWattage : 0.0 }
    
    // New computed properties for grid dimensions and total area.
    var gridRows: Int {
        let rows = luxGrid.keys.compactMap { Int($0.split(separator: "_")[0]) }
        return (rows.max() ?? 0) + 1
    }
    var gridColumns: Int {
        let cols = luxGrid.keys.compactMap { Int($0.split(separator: "_")[1]) }
        return (cols.max() ?? 0) + 1
    }
    var totalGridArea: Double {
        Double(gridRows * gridColumns) * cellArea
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                Form {
                    Section(header: Text("Measurements").foregroundColor(.yellow)) {
                        TextField("Cell Area (m²)", value: $cellArea, formatter: NumberFormatter())
                            .foregroundColor(.yellow)
                        Text("Grid Dimensions: \(gridRows) x \(gridColumns)")
                            .foregroundColor(.yellow)
                        Text(String(format: "Total Grid Area: %.1f m²", totalGridArea))
                            .foregroundColor(.yellow)
                        TextField("Outdoor Lux (for Daylight Factor)", value: $naturalLight, formatter: NumberFormatter())
                            .foregroundColor(.yellow)
                        TextField("Luminaire Wattage (W)", value: $luminaireWattage, formatter: NumberFormatter())
                            .foregroundColor(.yellow)
                    }
                    Section(header: Text("Light Analysis").foregroundColor(.yellow)) {
                        Text("Total Lux: \(totalLux)")
                            .foregroundColor(.yellow)
                        Text(String(format: "Average Lux: %.1f", averageLux))
                            .foregroundColor(.yellow)
                        Text(String(format: "Total Lumens: %.1f", totalLumens))
                            .foregroundColor(.yellow)
                        Text(complianceMessage)
                            .foregroundColor(.yellow)
                        if naturalLight > 0 {
                            Text(String(format: "Daylight Factor: %.1f%%", daylightFactor))
                                .foregroundColor(.yellow)
                        }
                        if luminaireWattage > 0 {
                            Text(String(format: "Efficiency: %.1f lumens/watt", efficiency))
                                .foregroundColor(.yellow)
                        }
                    }
                    // New Appearance section with toggle.
                    Section(header: Text("Appearance").foregroundColor(.yellow)) {
                        Toggle("Use Circle Cells", isOn: $useCircleCells)
                            .toggleStyle(SwitchToggleStyle(tint: .yellow))
                            .foregroundColor(.yellow)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Light Analysis")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.yellow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
