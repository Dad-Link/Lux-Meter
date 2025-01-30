import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct SignUpView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var personalEmail = ""
    @State private var businessEmail = ""
    @State private var personalPhoneNumber = ""
    @State private var businessPhoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var businessLogo: UIImage? // ✅ Business Logo Upload
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading = false
    @State private var isFormVisible = true
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

                        if isFormVisible {
                            VStack(spacing: 20) {
                                Text("Create an Account")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gold)
                                    .padding(.top, 20)
                                    .multilineTextAlignment(.center)

                                Text("Sign up to get started with Lux Meter. Measure light intensity with precision and ease!")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 40)
                                    .frame(maxWidth: 600)

                                VStack(spacing: 15) {
                                    GoldInputField(title: "First Name", text: $firstName, isSecure: false)
                                    GoldInputField(title: "Last Name", text: $lastName, isSecure: false)
                                    GoldInputField(title: "Personal Email", text: $personalEmail, isSecure: false)
                                    GoldInputField(title: "Business Email (Optional)", text: $businessEmail, isSecure: false)
                                    GoldInputField(title: "Personal Phone Number", text: $personalPhoneNumber, isSecure: false)
                                    GoldInputField(title: "Work Phone Number (Optional)", text: $businessPhoneNumber, isSecure: false)
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
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
        }
        .animation(.easeInOut, value: isFormVisible)
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

            saveUserData(user)

            user.sendEmailVerification { error in
                if let error = error {
                    print("❌ Failed to send verification email: \(error.localizedDescription)")
                }
            }
        }
    }

    private func saveUserData(_ user: User) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        let userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "personalEmail": personalEmail,
            "businessEmail": businessEmail,
            "personalPhoneNumber": personalPhoneNumber,
            "businessPhoneNumber": businessPhoneNumber,
            "isEmailVerified": user.isEmailVerified,
            "createdAt": FieldValue.serverTimestamp()
        ]

        userRef.setData(userData) { error in
            if let error = error {
                errorMessage = "Failed to save user data: \(error.localizedDescription)"
                isLoading = false
            } else {
                successMessage = "Check your email to verify your account."
                isLoading = false

                createCollections(for: user.uid)
            }
        }
    }

    private func createCollections(for userId: String) {
        let db = Firestore.firestore()
        
        // ✅ Create "grids" collection with default grid
        let gridsRef = db.collection("users").document(userId).collection("grids")
        let defaultGrid = [
            "gridName": "Default Grid",
            "description": "This is your first grid."
        ]
        gridsRef.addDocument(data: defaultGrid) { error in
            if let error = error {
                print("❌ Error creating grids collection: \(error.localizedDescription)")
            } else {
                print("✅ Grids collection created successfully.")
            }
        }

        // ✅ Create "readings" collection with placeholder document
        let readingsRef = db.collection("users").document(userId).collection("readings")
        readingsRef.document("placeholder").setData(["initialized": true]) { error in
            if let error = error {
                print("❌ Error initializing readings collection: \(error.localizedDescription)")
            } else {
                print("✅ Readings collection initialized successfully.")
            }
        }
    }
}
