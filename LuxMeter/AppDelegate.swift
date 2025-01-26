import Firebase
import FirebaseAppCheck
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()

        // Configure App Check with DeviceCheck for security
        AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())

        // Set Firebase Messaging delegate
        Messaging.messaging().delegate = self

        // Request notification permissions
        requestNotificationPermissions()

        return true
    }

    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Failed to request notifications authorization: \(error.localizedDescription)")
            }

            if granted {
                print("Notification permissions granted.")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permissions denied.")
            }
        }
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Forward the device token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        print("Device token registered: \(deviceToken)")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("Failed to retrieve FCM token.")
            return
        }

        // Save FCM token locally for later use
        UserDefaults.standard.setValue(fcmToken, forKey: "fcmToken")
        print("FCM Token: \(fcmToken)")

        // Optional: Send token to your backend if needed
        sendFCMTokenToServer(fcmToken)
    }

    private func sendFCMTokenToServer(_ token: String) {
        // Placeholder for sending the FCM token to your backend server
        print("Sending FCM token to server: \(token)")
        // Add your backend API call here
    }

    // Handle notifications while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("Notification received in foreground: \(notification.request.content.userInfo)")
        completionHandler([.alert, .sound, .badge])
    }

    // Handle notifications when the app is tapped or in the background
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("User interacted with notification: \(response.notification.request.content.userInfo)")
        completionHandler()
    }
}
