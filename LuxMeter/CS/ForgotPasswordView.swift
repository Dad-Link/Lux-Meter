import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var confirmEmail = ""
    @State private var securityAnswer = ""
    @State private var successMessage: String?
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // ✅ Black Background
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()

                // ✅ Title
                Text("Reset Your Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)

                // ✅ Description
                Text("Enter your email and confirm it below. Answer the security question if prompted.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 20)

                // ✅ Email Input Fields
                GoldInputField(title: "Email", text: $email, isSecure: false)
                GoldInputField(title: "Confirm Email", text: $confirmEmail, isSecure: false)

                // ✅ Security Question Field (Optional)
                GoldInputField(title: "Security Answer", text: $securityAnswer, isSecure: false)

                // ✅ Error & Success Messages
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

                // ✅ Send Reset Link Button
                GoldButton(title: "Send Reset Link", action: resetPassword)

                // ✅ Back to Login Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Back to Login")
                        .font(.subheadline)
                        .foregroundColor(.gold)
                        .underline()
                        .padding(.top, 10)
                }

                Spacer()

                // ✅ Contact Us & Powered By Footer
                VStack(spacing: 10) {
                    Link(destination: URL(string: "https://dadlink.co.uk/pages/contact")!) {
                        Text("Contact Us")
                            .font(.footnote)
                            .foregroundColor(.gold)
                            .underline()
                    }

                    Link(destination: URL(string: "https://dadlink.co.uk")!) {
                        Text("Powered by DadLink Technologies Limited")
                            .font(.footnote)
                            .foregroundColor(.gold)
                            .underline()
                            .padding(.bottom, 20)
                    }
                }
            }
            .padding()
        }
        .navigationBarHidden(true) // ✅ Hide Navigation Bar
    }

    // MARK: - Reset Password Function
    private func resetPassword() {
        guard !email.isEmpty, !confirmEmail.isEmpty else {
            errorMessage = "Please enter and confirm your email."
            return
        }

        guard email == confirmEmail else {
            errorMessage = "Emails do not match."
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
