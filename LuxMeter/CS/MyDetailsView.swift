import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseFunctions

struct MyDetailsView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var businessName = ""
    @State private var businessAddress = ""
    @State private var businessEmail = ""
    @State private var businessNumber = ""
    @State private var personalEmail = ""
    @State private var downloadedPDFs: [String] = []
    @State private var businessLogo: UIImage?
    @State private var isLoading = false
    @State private var feedbackMessage: FeedbackMessage?
    @State private var showImagePicker = false
    @State private var showDeleteConfirmation = false
    @State private var showFinalDeleteConfirmation = false
    private let logoFilename = "businessLogo.jpg" // ✅ File name for local storage
    @Environment(\.presentationMode) var presentationMode // ✅ Controls navigation
    @EnvironmentObject var authViewModel: AuthViewModel // 🔥 Inject ViewModel
    @State private var showDeleteAccountView = false  // 🔹 Show password prompt for deletion
    @State private var password: String = ""  // 🔥 Add this to store user input


    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // Background
            ScrollView {
                VStack(spacing: 20) {
                    // ✅ Logo at the top
                    VStack {
                        if let logo = businessLogo {
                            Image(uiImage: logo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                                .onTapGesture {
                                    showImagePicker = true
                                }
                        } else {
                            Circle()
                                .strokeBorder(Color.gold, lineWidth: 2)
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Text("Tap to Add Logo")
                                        .font(.footnote)
                                        .foregroundColor(.gold)
                                )
                                .onTapGesture {
                                    showImagePicker = true
                                }
                        }
                    }
                    .padding(.top)
                    
                    // ✅ Title and Description
                    VStack(spacing: 5) {
                        Text("My Details")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.gold)
                            .toolbarBackground(Color.black, for: .navigationBar) 
                            .toolbarColorScheme(.dark, for: .navigationBar)
                        Text("Manage your personal and business details. Keep everything up-to-date!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Toggle("Enable Auto-Login", isOn: $authViewModel.autoLoginEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .gold))
                        .padding(.horizontal, 20)
                        .foregroundColor(.white)
                    
                    Divider().background(Color.gold.opacity(0.5))
                    
                    // ✅ Form for user details
                    VStack(spacing: 15) {
                        Group {
                            CustomTextField(title: "First Name", text: $firstName)
                            CustomTextField(title: "Last Name", text: $lastName)
                            CustomTextField(title: "Personal Email", text: $personalEmail, keyboardType: .emailAddress)
                        }
                        Divider().background(Color.gold)
                        Group {
                            CustomTextField(title: "Business Name", text: $businessName)
                            CustomTextField(title: "Business Address", text: $businessAddress)
                            CustomTextField(title: "Business Email", text: $businessEmail, keyboardType: .emailAddress)
                            CustomTextField(title: "Business Number", text: $businessNumber, keyboardType: .phonePad)
                        }
                    }
                    .padding(.horizontal)
                    
                    // ✅ Save Button
                    Button(action: saveDetailsToFirebase) {
                        Text("Save Changes")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gold)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                    }
                    Button(action: logout) {
                        Text("Logout")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    Button(action: { showDeleteAccountView = true }) {
                        Text("Delete Account")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .sheet(isPresented: $showDeleteAccountView) {
                        DeleteAccountView(
                            dismiss: {
                                showDeleteAccountView = false
                                authViewModel.isLoggedIn = false  // Ensure logout
                            },
                            deleteAccount: { password in  // ✅ Pass delete function properly
                                deleteAccount(password: password)
                            }
                        )
                        .environmentObject(authViewModel)
                    }


                    
                    // ✅ Powered By Footer
                    Link(destination: URL(string: "https://dadlink.co.uk")!) {
                        Text("Powered by DadLink Technologies Limited")
                            .font(.footnote)
                            .foregroundColor(.gold.opacity(0.8))
                            .underline()
                            .padding(.top, 20)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
            }
            if isLoading {
                ProgressView("Saving...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .navigationTitle("My Details")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $businessLogo, onImagePicked: saveBusinessLogoLocally) // ✅ Save locally
        }
        .onAppear(perform: fetchDetailsFromFirebase)
        .alert(item: $feedbackMessage) { message in
            Alert(title: Text("Info"), message: Text(message.text), dismissButton: .default(Text("OK")))
        }
        .alert("Enter your password to delete your account", isPresented: $showDeleteConfirmation, actions: {
            SecureField("Password", text: $password)  // 🔥 Capture password
            Button("Delete", role: .destructive) {
                deleteAccount(password: password)  // ✅ Pass password properly
            }
            Button("Cancel", role: .cancel) {}
        })
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            print("✅ User signed out successfully.") // ✅ Log success
            presentationMode.wrappedValue.dismiss() // ✅ Navigate back to LoginView
        } catch let signOutError as NSError {
            print("❌ Error signing out: \(signOutError.localizedDescription)")
            feedbackMessage = FeedbackMessage(text: "Failed to log out. Please try again.")
        }
    }
    
    // ✅ Fetch User Details (From Firebase or Local)
    private func fetchDetailsFromFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        isLoading = true
        db.collection("users").document(userId).getDocument { document, error in
            isLoading = false
            if let document = document, document.exists {
                firstName = document.data()?["firstName"] as? String ?? ""
                lastName = document.data()?["lastName"] as? String ?? ""
                businessName = document.data()?["businessName"] as? String ?? ""
                businessAddress = document.data()?["businessAddress"] as? String ?? ""
                businessEmail = document.data()?["businessEmail"] as? String ?? ""
                businessNumber = document.data()?["businessNumber"] as? String ?? ""
                personalEmail = document.data()?["personalEmail"] as? String ?? ""
                if let logoUrl = document.data()?["businessLogo"] as? String {
                    fetchBusinessLogo(from: logoUrl)
                } else {
                    loadBusinessLogoLocally() // ✅ Load from device
                }
            } else {
                feedbackMessage = FeedbackMessage(text: "Failed to load details.")
            }
        }
    }
    
    // ✅ Fetch Business Logo from Firebase (If Needed)
    private func fetchBusinessLogo(from url: String) {
        guard let logoUrl = URL(string: url) else { return }
        URLSession.shared.dataTask(with: logoUrl) { data, _, _ in
            if let data = data {
                DispatchQueue.main.async {
                    businessLogo = UIImage(data: data)
                    saveBusinessLogoLocally(image: businessLogo!) // ✅ Save locally
                }
            }
        }.resume()
    }
    
    // ✅ Save Business Logo Locally
    private func saveBusinessLogoLocally(image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8), let url = getLocalLogoURL() {
            try? data.write(to: url, options: .atomic)
            businessLogo = image
        }
    }
    
    // ✅ Load Business Logo from Device
    private func loadBusinessLogoLocally() {
        if let url = getLocalLogoURL(), let data = try? Data(contentsOf: url) {
            businessLogo = UIImage(data: data)
        }
    }
    
    // ✅ Get File URL for Local Logo Storage
    private func getLocalLogoURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(logoFilename)
    }
    
    private func deleteAccount(password: String) {
        guard let user = Auth.auth().currentUser, let email = user.email, !isLoading else { return }

        isLoading = true
        feedbackMessage = FeedbackMessage(text: "Deleting account... Please wait.")

        let db = Firestore.firestore()
        let userId = user.uid
        let group = DispatchGroup()

        // 🔥 Step 1: Re-authenticate User with Provided Password
        group.enter()
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)  // 🔑 Use entered password
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                print("❌ Re-authentication failed: \(error.localizedDescription)")
                feedbackMessage = FeedbackMessage(text: "Incorrect password. Please try again.")
                isLoading = false
                group.leave()
                return
            }
            print("✅ User re-authenticated.")
            group.leave()
        }

        // 🔥 Step 2: Delete Firestore Subcollections
        group.enter()
        deleteSubcollections(userId: userId) { error in
            if let error = error {
                print("❌ Error deleting subcollections: \(error.localizedDescription)")
            } else {
                print("✅ Subcollections deleted.")
            }
            group.leave()
        }

        // 🔥 Step 3: Delete Firebase Storage Files
        group.enter()
        deleteUserStorageFiles(userId: userId) { storageError in
            if let storageError = storageError {
                print("❌ Error deleting storage files: \(storageError.localizedDescription)")
            } else {
                print("✅ User storage files deleted.")
            }
            group.leave()
        }

        // 🔥 Step 4: Delete Firestore User Document
        group.enter()
        db.collection("users").document(userId).delete { error in
            if let error = error {
                print("❌ Failed to delete user document: \(error.localizedDescription)")
            } else {
                print("✅ User document deleted.")
            }
            group.leave()
        }

        // 🔥 Step 5: Delete Firebase Authentication Account After All Data is Deleted
        group.notify(queue: .main) {
            print("✅ All user data deleted. Now deleting Firebase Authentication...")

            user.delete { authError in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let authError = authError {
                        print("❌ Failed to delete user from Firebase Auth: \(authError.localizedDescription)")
                        self.feedbackMessage = FeedbackMessage(text: "Failed to delete user. Try again later.")
                        return
                    }

                    print("✅ User account deleted successfully.")

                    // 🔥 Navigate back to login screen after deletion
                    authViewModel.isLoggedIn = false  // ✅ Reset authentication state
                }
            }
        }
    }



    private func deleteSubcollections(userId: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        let subcollections = ["readings", "grids"]
        let group = DispatchGroup()

        for sub in subcollections {
            let collectionRef = db.collection("users").document(userId).collection(sub)
            group.enter()

            collectionRef.getDocuments { (snapshot, error) in
                if let error = error {
                    print("❌ Error fetching subcollection \(sub): \(error.localizedDescription)")
                    group.leave()
                    return
                }

                guard let snapshot = snapshot, !snapshot.isEmpty else {
                    print("⚠️ No documents found in \(sub), skipping...")
                    group.leave()
                    return
                }

                let batch = db.batch()
                for document in snapshot.documents {
                    batch.deleteDocument(document.reference)
                }

                batch.commit { err in
                    if let err = err {
                        print("❌ Error deleting subcollection \(sub): \(err.localizedDescription)")
                    } else {
                        print("✅ Successfully deleted subcollection \(sub)")
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            print("✅ All subcollections deleted.")
            completion(nil)
        }
    }

    private func deleteUserStorageFiles(userId: String, completion: @escaping (Error?) -> Void) {
        let storageRef = Storage.storage().reference().child("users/\(userId)/")

        storageRef.listAll { (result, error) in
            if let error = error {
                completion(error)
                return
            }

            // ✅ Unwrap `result` safely
            guard let result = result else {
                print("❌ Error: Failed to list storage files.")
                completion(NSError(domain: "StorageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to list storage files"]))
                return
            }

            let group = DispatchGroup()

            for file in result.items {
                group.enter()
                file.delete { error in
                    if let error = error {
                        print("❌ Failed to delete file: \(file.name), Error: \(error.localizedDescription)")
                    } else {
                        print("✅ Successfully deleted file: \(file.name)")
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                print("✅ All user storage files deleted.")
                completion(nil)
            }
        }
    }


    // ✅ Save Details to Firebase
    private func saveDetailsToFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        var data: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "businessName": businessName,
            "businessAddress": businessAddress,
            "businessEmail": businessEmail,
            "businessNumber": businessNumber,
            "personalEmail": personalEmail,
            "createdAt": FieldValue.serverTimestamp()
        ]
        isLoading = true
        db.collection("users").document(userId).setData(data, merge: true) { error in
            isLoading = false
            feedbackMessage = error == nil ? FeedbackMessage(text: "Details saved!") : FeedbackMessage(text: "Failed to save.")
        }
    }
}

// MARK: - Reusable Custom TextField
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboardType)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            .background(Color.white) // ✅ White Background
            .cornerRadius(10)
            .foregroundColor(.black) // ✅ Black Text
    }
}

// MARK: - FeedbackMessage Struct
struct FeedbackMessage: Identifiable {
    let id = UUID()
    let text: String
}
