import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var autoLoginEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoLoginEnabled, forKey: "autoLoginEnabled")

            // 🔥 Ensure user is logged out if Auto-Login is turned OFF
            if !autoLoginEnabled {
                logout()
            }
        }
    }

    init() {
        self.autoLoginEnabled = UserDefaults.standard.bool(forKey: "autoLoginEnabled")
        
        // Listen for auth changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.handleAuthChange(for: user)
            }
        }
    }
    
    

    private func handleAuthChange(for user: User?) {
        guard let user = user else {
            self.isLoggedIn = false
            return
        }

        if user.isEmailVerified {
            checkUserInFirestore(userID: user.uid) { exists in
                self.isLoggedIn = exists && self.autoLoginEnabled  // 🔥 Only login if auto-login is enabled
                if exists {
                    print("✅ User is verified and data exists in Firestore.")
                } else {
                    print("⚠️ User is verified but data does not exist in Firestore.")
                }
            }
        } else {
            print("⚠️ User email is not verified. Prompting verification.")
            self.isLoggedIn = false
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            print("✅ User logged out successfully.")
        } catch {
            print("❌ Error logging out: \(error.localizedDescription)")
        }
    }

    private func checkUserInFirestore(userID: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error checking user in Firestore: \(error.localizedDescription)")
                completion(false)
            } else {
                let exists = snapshot?.exists == true
                print("✅ Firestore check completed. Exists: \(exists)")
                completion(exists)
            }
        }
    }
}
