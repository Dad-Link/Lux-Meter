import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 30) {
                    // Title and Description
                    Text("Welcome Back!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Log in to your account to continue using Lux Meter. Secure, fast, and reliable!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 20)

                    // Email and Password Fields
                    Group {
                        TextField("Email", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .styledTextField()

                        SecureField("Password", text: $password)
                            .styledTextField()
                    }

                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Login Button
                    Button(action: login) {
                        Text("Log In")
                            .font(.headline)
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
                    }

                    // Forgot Password and Sign-Up Links
                    VStack(spacing: 5) {
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundColor(.white)
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
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.top, 40)
            }

            VStack {
                Spacer()

                // Powered By Footer
                Link(destination: URL(string: "https://dadlink.co.uk")!) {
                    Text("Powered by DadLink Technologies Limited")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .underline()
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: autoLogin)
    }

    private func autoLogin() {
        if let user = Auth.auth().currentUser, user.isEmailVerified {
            // Check if the user exists in Firestore
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).getDocument { snapshot, error in
                if let error = error {
                    print("Error checking user in Firestore: \(error.localizedDescription)")
                    authViewModel.isLoggedIn = false
                } else if snapshot?.exists == true {
                    authViewModel.isLoggedIn = true
                } else {
                    authViewModel.isLoggedIn = false
                }
            }
        } else {
            authViewModel.isLoggedIn = false
        }
    }

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

            // Check if user exists in Firestore
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

