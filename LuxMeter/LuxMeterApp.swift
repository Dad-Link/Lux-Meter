import SwiftUI
import Firebase

@main
struct LuxMeterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isLoggedIn {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                LandingView() // Start at the introduction screen
                    .environmentObject(authViewModel)
            }
        }
    }
}
