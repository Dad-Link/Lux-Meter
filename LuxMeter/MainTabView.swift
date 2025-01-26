import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Light Meter Tab
            LightMeterView()
                .tabItem {
                    Label("Meter", systemImage: "lightbulb")
                }

            // Readings Tab
            ReadingsView()
                .tabItem {
                    Label("Readings", systemImage: "list.bullet.rectangle")
                }

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
