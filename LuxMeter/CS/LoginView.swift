import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isKeyboardVisible = false  // ✅ Detect keyboard visibility

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // ✅ Black Theme
            
            VStack {
                Spacer().frame(height: 20) // ✅ Top Padding
                
                ScrollView {
                    VStack(spacing: 30) {
                        // ✅ Title
                        Text("Welcome Back!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.gold)

                        Text("Log in to your account to continue using Lux Meter.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 20)

                        // ✅ Email & Password Fields
                        Group {
                            GoldTextField(title: "Email", text: $email, isSecure: false)
                            GoldTextField(title: "Password", text: $password, isSecure: true)
                        }

                        // ✅ Error Message (if any)
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        // ✅ Login Button
                        Button(action: login) {
                            Text("Log In")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gold)
                                .foregroundColor(.black)
                                .cornerRadius(15)
                                .shadow(radius: 10)
                                .padding(.horizontal, 40)
                        }

                        // ✅ Forgot Password & Sign-Up Links
                        VStack(spacing: 5) {
                            NavigationLink(destination: ForgotPasswordView()) {
                                Text("Forgot Password?")
                                    .font(.subheadline)
                                    .foregroundColor(.gold)
                                    .underline()
                            }

                            NavigationLink(destination: SignUpView()) {
                                VStack {
                                    Text("Don't have an account?")
                                        .font(.subheadline)
                                        .foregroundColor(.white)

                                    Text("Sign Up")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gold)
                                }
                            }
                        }
                    }
                    .padding(.top, 40)
                }

                // ✅ Fixed Footer (Hidden When Keyboard is Up)
                if !isKeyboardVisible {
                    VStack {
                        Spacer()
                        Link(destination: URL(string: "https://dadlink.co.uk")!) {
                            Text("Powered by DadLink Technologies Limited")
                                .font(.footnote)
                                .foregroundColor(.gold)
                                .underline()
                                .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
        .onAppear(perform: autoLogin)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation {
                isKeyboardVisible = false
            }
        }
        .navigationBarHidden(true)
    }

    private func autoLogin() {
        guard authViewModel.autoLoginEnabled else {
            print("⚠️ Auto-login is disabled. Staying on LoginView.")
            authViewModel.isLoggedIn = false
            return
        }

        if let user = Auth.auth().currentUser, user.isEmailVerified {
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).getDocument { snapshot, error in
                if let error = error {
                    print("❌ Error checking user: \(error.localizedDescription)")
                    authViewModel.isLoggedIn = false
                } else if snapshot?.exists == true {
                    authViewModel.isLoggedIn = true
                    print("✅ Auto-login successful")
                } else {
                    authViewModel.isLoggedIn = false
                }
            }
        } else {
            authViewModel.isLoggedIn = false
        }
    }

    // MARK: - Login Function
    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        print("Attempting to log in...")
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Error logging in: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                return
            }

            guard let user = result?.user else {
                print("No user object returned from Firebase.")
                errorMessage = "Login failed. Please try again."
                return
            }

            if !user.isEmailVerified {
                print("User email not verified.")
                errorMessage = "Please verify your email before logging in."
                return
            }

            let db = Firestore.firestore()
            db.collection("users").document(user.uid).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching user data: \(error.localizedDescription)")
                    errorMessage = "Failed to fetch user data. Please try again."
                    return
                }

                if snapshot?.exists == true {
                    print("User data found. Logging in.")
                    authViewModel.isLoggedIn = true
                } else {
                    print("User data not found in Firestore.")
                    errorMessage = "No account found. Please sign up."
                }
            }
        }
    }
}

struct GoldTextField: View {
    let title: String
    @Binding var text: String
    let isSecure: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            // ✅ Placeholder Text
            if text.isEmpty {
                Text(title)
                    .foregroundColor(.gold.opacity(0.6)) // ✅ Faded gold for placeholder
                    .padding(.leading, 12) // ✅ Ensures correct positioning
            }

            if isSecure {
                SecureField("", text: $text)
                    .padding()
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gold, lineWidth: 2))
                    .frame(maxWidth: 380)
            } else {
                TextField("", text: $text)
                    .autocapitalization(.none)
                    .padding()
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gold, lineWidth: 2))
                    .frame(maxWidth: 380)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
        