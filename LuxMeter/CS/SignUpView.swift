import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct SignUpView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var personalEmail = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var businessLogo: UIImage?
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            if isLoading {
                ProgressView("Creating account...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .gold))
                    .scaleEffect(1.5)
            } else if let successMessage = successMessage {
                VStack {
                    Spacer()
                    VStack(spacing: 20) {
                        Text("Thank You!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.gold)

                        Text(successMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 20)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5))
                    Spacer()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer(minLength: 20)

                        VStack(spacing: 20) {
                            Text("Create an Account")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.gold)
                                .padding(.top, 20)
                                .multilineTextAlignment(.center)

                            VStack(spacing: 15) {
                                GoldInputField(title: "First Name", text: $firstName, isSecure: false)
                                GoldInputField(title: "Last Name", text: $lastName, isSecure: false)
                                GoldInputField(title: "Email", text: $personalEmail, isSecure: false)
                                GoldInputField(title: "Password", text: $password, isSecure: true)
                                GoldInputField(title: "Confirm Password", text: $confirmPassword, isSecure: true)
                            }
                            .frame(maxWidth: 420)
                            .padding(.horizontal, 20)

                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }

                            GoldButton(title: "Sign Up", action: signUp)
                                .frame(maxWidth: 420, minHeight: 50)
                                .padding(.top, 10)

                            Button("Back to Login") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .font(.subheadline)
                            .foregroundColor(.gold)
                            .padding(.top, 5)

                            // ✅ Add Clickable Terms of Service Link
                            VStack {
                                Text("By signing up, you agree to our")
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.8))

                                NavigationLink(destination: TermsOfServiceView()) {
                                    Text("Terms of Service")
                                        .font(.footnote)
                                        .foregroundColor(.gold)
                                        .underline()
                                }
                            }
                            .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .animation(.easeInOut, value: isLoading)
        .navigationBarHidden(true)
    }


    private func signUp() {
        guard !firstName.isEmpty, !lastName.isEmpty, !personalEmail.isEmpty, !password.isEmpty, password == confirmPassword else {
            errorMessage = "Please complete all required fields."
            return
        }

        isLoading = true
        Auth.auth().createUser(withEmail: personalEmail, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }

            guard let user = result?.user else {
                errorMessage = "Signup failed. Please try again."
                isLoading = false
                return
            }

            // ✅ Send verification email
            user.sendEmailVerification { error in
                if let error = error {
                    print("❌ Failed to send verification email: \(error.localizedDescription)")
                } else {
                    print("✅ Verification email sent to \(user.email ?? "unknown email")")
                }
            }

            // ✅ Save user data in Firestore
            saveUserData(user)
        }
    }

    private func saveUserData(_ user: User) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        var userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "personalEmail": personalEmail,
            "isEmailVerified": user.isEmailVerified,
            "createdAt": FieldValue.serverTimestamp(),
            "businessName": "", // Blank field
            "businessAddress": "", // Blank field
            "businessEmail": "", // Blank field
            "businessNumber": "", // Blank field
            "businessLogoUrl": "", // Blank field
            "settings": [
                "darkMode": true,
                "notificationsEnabled": true
            ]
        ]

        userRef.setData(userData, merge: true) { error in
            if let error = error {
                errorMessage = "Failed to save user data: \(error.localizedDescription)"
                isLoading = false
                return
            }

            print("✅ User data saved successfully.")

            // ✅ Create storage files immediately
            createStorageFiles(for: user.uid)

            // ✅ Create Firestore subcollections
            createCollections(for: user.uid)
        }
    }


    private func uploadBusinessLogo(user: User) {
        guard let businessLogo = businessLogo, let imageData = businessLogo.jpegData(compressionQuality: 0.8) else {
            print("⚠️ No business logo provided, skipping upload.")
            createCollections(for: user.uid)
            return
        }

        let storageRef = Storage.storage().reference().child("users/\(user.uid)/businessLogo.jpg")

        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("❌ Failed to upload business logo: \(error.localizedDescription)")
            } else {
                storageRef.downloadURL { url, error in
                    if let url = url {
                        Firestore.firestore().collection("users").document(user.uid).updateData(["businessLogoUrl": url.absoluteString])
                        print("✅ Business logo uploaded successfully.")
                    }
                }
            }
            createCollections(for: user.uid)
        }
    }

    private func createCollections(for userId: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        let gridsRef = userRef.collection("grids").document("default")
        let readingsRef = userRef.collection("readings").document("placeholder")

        let batch = db.batch()

        batch.setData(["gridName": "Default Grid", "description": "This is your first grid."], forDocument: gridsRef)
        batch.setData([
            "luxValue": 350,
            "timestamp": FieldValue.serverTimestamp(),
            "lightReference": "Room 1",
            "gridLocation": "Top Left",
            "siteLocation": "Warehouse A",
            "fixtureDetails": "LED 40W",
            "knownWattage": "40W",
            "notes": "No issues",
            "isFaulty": false,
            "imageUrl": ""
        ], forDocument: readingsRef)

        batch.commit { error in
            if let error = error {
                errorMessage = "Error creating user collections: \(error.localizedDescription)"
                isLoading = false
            } else {
                print("✅ Collections created successfully.")
                DispatchQueue.main.async {
                    successMessage = "Check your email to verify your account."
                    isLoading = false
                }
            }
        }
    }
    
    private func createStorageFiles(for userId: String) {
        let storageRef = Storage.storage().reference()

        // ✅ Create Business Logo File
        let businessLogoRef = storageRef.child("users/\(userId)/businessLogos/businessLogo.jpg")
        businessLogoRef.putData(Data(), metadata: nil) { _, error in
            if let error = error {
                print("❌ Failed to create Business Logo file: \(error.localizedDescription)")
            } else {
                print("✅ Successfully created empty Business Logo file for user: \(userId)")
            }
        }

        // ✅ Create Placeholder Reading Image
        let readingId = "placeholder" // Default placeholder image ID
        let readingRef = storageRef.child("users/\(userId)/readings/\(readingId).jpg")
        readingRef.putData(Data(), metadata: nil) { _, error in
            if let error = error {
                print("❌ Failed to create Reading Image file: \(error.localizedDescription)")
            } else {
                print("✅ Successfully created empty Reading Image file for user: \(userId)")
            }
        }

        // ✅ Create Placeholder Grid PDF
        let gridId = "placeholder" // Default grid ID
        let gridPDFRef = storageRef.child("users/\(userId)/grids/\(gridId)/PDF/placeholder.pdf")
        gridPDFRef.putData(Data(), metadata: nil) { _, error in
            if let error = error {
                print("❌ Failed to create Grid PDF file: \(error.localizedDescription)")
            } else {
                print("✅ Successfully created empty Grid PDF file for user: \(userId)")
            }
        }

        // ✅ Create Placeholder Reading PDF
        let readingPDFRef = storageRef.child("users/\(userId)/readings/\(readingId)/PDF/placeholder.pdf")
        readingPDFRef.putData(Data(), metadata: nil) { _, error in
            if let error = error {
                print("❌ Failed to create Reading PDF file: \(error.localizedDescription)")
            } else {
                print("✅ Successfully created empty Reading PDF file for user: \(userId)")
            }
        }
    }

}
