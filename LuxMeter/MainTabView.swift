import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Light Meter
            LightMeterView()
                .tabItem {
                    Label("Meter", systemImage: "lightbulb")
                }

            // Readings (Placeholder)
            ReadingsView()
                .tabItem {
                    Label("Readings", systemImage: "list.bullet.rectangle")
                }

            // Settings (Placeholder)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
