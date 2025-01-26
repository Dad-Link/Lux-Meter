import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false

    init() {
        // Listen for auth changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.handleAuthChange(for: user)
            }
        }
    }

    private func handleAuthChange(for user: User?) {
        guard let user = user else {
            // User is not logged in
            self.isLoggedIn = false
            return
        }

        // Check if the user's email is verified
        if user.isEmailVerified {
            // Check if user data exists in Firestore
            checkUserInFirestore(userID: user.uid) { exists in
                self.isLoggedIn = exists
                if exists {
                    print("User is verified and data exists in Firestore.")
                } else {
                    print("User is verified but data does not exist in Firestore.")
                }
            }
        } else {
            print("User email is not verified. Prompting verification.")
            self.isLoggedIn = false
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            print("User logged out successfully.")
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
    }

    private func checkUserInFirestore(userID: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Error checking user in Firestore: \(error.localizedDescription)")
                completion(false)
            } else {
                let exists = snapshot?.exists == true
                print("Firestore check completed. Exists: \(exists)")
                completion(exists)
            }
        }
    }
}
