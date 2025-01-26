import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var successMessage: String?
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()

                // Title
                Text("Reset Your Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Description
                Text("Enter your email address below, and we'll send you a link to reset your password. Make sure to check your inbox, including the spam folder.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 20)

                // Email Input
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .styledTextField()

                // Error and Success Messages
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                if let successMessage = successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Reset Button
                Button(action: resetPassword) {
                    Text("Send Reset Link")
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

                // Back to Login Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Back to Login")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .underline()
                        .padding(.top, 10)
                }

                Spacer()

                // Contact Us Link
                Link(destination: URL(string: "https://dadlink.co.uk/pages/contact")!) {
                    Text("Contact Us")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .underline()
                }

                // Powered By Footer
                Link(destination: URL(string: "https://dadlink.co.uk")!) {
                    Text("Powered by DadLink Technologies Limited")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .underline()
                        .padding(.bottom, 20)
                }
            }
            .padding()
        }
        .navigationBarHidden(true) // Hide the top back navigation
    }

    private func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                successMessage = nil
            } else {
                successMessage = "A password reset link has been sent to your email."
                errorMessage = nil
            }
        }
    }
}
