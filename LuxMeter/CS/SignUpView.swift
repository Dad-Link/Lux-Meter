import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseAppCheck

struct SignUpView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading = false // Loading state
    @State private var isFormVisible = true
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            ).edgesIgnoringSafeArea(.all)

            if isLoading {
                ProgressView("Creating account...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .foregroundColor(.white)
            } else if let successMessage = successMessage {
                VStack {
                    Spacer()
                    VStack(spacing: 20) {
                        Text("Thank You!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

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
                                    .foregroundColor(.white)
                                    .padding(.top, 20)

                                Text("Sign up to get started with Lux Meter.\nMeasure light intensity with precision and ease!")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 20)

                                Group {
                                    TextField("First Name", text: $firstName).styledTextField()
                                    TextField("Last Name", text: $lastName).styledTextField()
                                    TextField("Email", text: $email)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .styledTextField()
                                    SecureField("Password", text: $password).styledTextField()
                                    SecureField("Confirm Password", text: $confirmPassword).styledTextField()
                                }

                                if let errorMessage = errorMessage {
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }

                                Button("Sign Up") {
                                    signUp()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.orange, Color.pink]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .shadow(radius: 10)
                                .padding(.horizontal, 40)

                                // Back to Login
                                Button("Back to Login") {
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.top, 10)
                            }

                            Spacer(minLength: 20)

                            VStack(spacing: 10) {
                                NavigationLink(destination: TermsOfServiceView()) {
                                    Text("Terms and Conditions")
                                        .font(.footnote)
                                        .foregroundColor(.white)
                                }

                                NavigationLink(destination: PrivacyPolicyView()) {
                                    Text("Privacy Policy")
                                        .font(.footnote)
                                        .foregroundColor(.white)
                                }
                            }

                            Spacer(minLength: 10)

                            Link(destination: URL(string: "https://dadlink.co.uk")!) {
                                Text("Powered by DadLink Technologies Limited")
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.bottom, 30)
                            }
                        }
                    }
                }
            }
        }
        .animation(.easeInOut, value: isFormVisible)
        .navigationBarHidden(true)
    }

    private func signUp() {
        guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty, password == confirmPassword else {
            errorMessage = "Please complete all fields correctly."
            return
        }

        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
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

            // Send verification email
            user.sendEmailVerification { error in
                if let error = error {
                    errorMessage = "Failed to send verification email: \(error.localizedDescription)"
                    isLoading = false
                    return
                }

                print("Verification email successfully sent to \(self.email).")
                saveUserData(user)
            }
        }
    }

    private func saveUserData(_ user: User) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": user.email ?? "",
            "isEmailVerified": user.isEmailVerified,
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                errorMessage = "Failed to save user data: \(error.localizedDescription)"
                isLoading = false
            } else {
                createReadingsCollection(for: user.uid)
                successMessage = "Thanks for your sign-up! Please head to your email to verify it, then log in to enjoy the app."
                isLoading = false
            }
        }
    }

    private func createReadingsCollection(for userId: String) {
        let db = Firestore.firestore()
        let placeholderReading: [String: Any] = [
            "value": 0,
            "unit": "lux",
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(userId).collection("readings").document("placeholder").setData(placeholderReading) { error in
            if let error = error {
                print("Error creating readings collection: \(error.localizedDescription)")
            } else {
                print("Readings collection initialized successfully for user \(userId).")
            }
        }
    }
}

extension View {
    func styledTextField() -> some View {
        self
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.gray.opacity(0.4), radius: 5, x: 0, y: 5)
            .padding(.horizontal, 20)
    }
}
