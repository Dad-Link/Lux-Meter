import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import StoreKit

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    static var isSubscribed: Bool = false // Global subscription state

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // ✅ Configure Firebase (Keep if using Firestore for data storage)
        FirebaseApp.configure()

        // ✅ Set Firebase Messaging delegate
        Messaging.messaging().delegate = self

        // ✅ Request notification permissions
        requestNotificationPermissions()

        // ✅ Check subscription status at launch
        Task {
            await checkSubscriptionStatus()
        }

        return true
    }

    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("❌ Failed to request notifications authorization: \(error.localizedDescription)")
            }

            if granted {
                print("✅ Notification permissions granted.")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ Notification permissions denied.")
            }
        }
    }

    // ✅ StoreKit 2: Check Subscription Status (No Login Required)
    @MainActor
    private func checkSubscriptionStatus() async {
        do {
            let productIDs: [String] = ["connect.weekly.luxProPass", "connect.Monthly.luxProPass"]

            for productID in productIDs {
                if let product = try? await Product.products(for: [productID]).first,
                   let subscriptionStatus = try await product.subscription?.status.first {
                    
                    if subscriptionStatus.state == .subscribed {
                        AppDelegate.isSubscribed = true
                        print("🔔 Subscription Active!")
                        return
                    }
                }
            }

            AppDelegate.isSubscribed = false
            print("❌ No active subscription.")

        } catch {
            print("❌ Failed to check subscription status: \(error.localizedDescription)")
        }
    }
}
