import SwiftUI
import StoreKit

@main
struct LuxMeterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isSubscribed: Bool = false // Subscription state
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    Task {
                        isSubscribed = await checkSubscriptionStatus()
                        print("🔔 Subscription Active in UI: \(isSubscribed)")
                    }
                }
        }
    }
    
    @MainActor
    private func checkSubscriptionStatus() async -> Bool {
        do {
            let productIDs: [String] = ["connect.weekly.luxProPass", "connect.Monthly.luxProPass"]

            for productID in productIDs {
                if let product = try? await Product.products(for: [productID]).first,
                   let subscriptionStatus = try await product.subscription?.status.first {
                    
                    if subscriptionStatus.state == .subscribed {
                        AppDelegate.isSubscribed = true
                        return true
                    }
                }
            }

            AppDelegate.isSubscribed = false
            return false

        } catch {
            print("❌ Failed to check subscription status: \(error.localizedDescription)")
            return false
        }
    }
}
