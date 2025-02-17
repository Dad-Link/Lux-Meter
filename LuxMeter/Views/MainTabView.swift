import SwiftUI

struct MainTabView: View {
    init() {
        UITabBar.appearance().barTintColor = UIColor.black
        UITabBar.appearance().backgroundColor = UIColor.black
        UITabBar.appearance().unselectedItemTintColor = UIColor.darkGray
    }

    var body: some View {
        TabView {
            // Light Meter Tab
            LightMeterView()
                .tabItem {
                    Label("Meter", systemImage: "lightbulb")
                        .foregroundColor(.gold)
                }

            // Readings Tab
            ReadingsView()
                .tabItem {
                    Label("Readings", systemImage: "list.bullet.rectangle")
                        .foregroundColor(.gold)
                }

            // Map/Grid Tab
            GridPlanView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                        .foregroundColor(.gold)
                }

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                        .foregroundColor(.gold)
                }
        }
        .accentColor(.gold) // Ensures the selected tab is gold
    }
}

extension Color {
    static let gold = Color.yellow
}
