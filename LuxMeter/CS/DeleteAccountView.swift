import SwiftUI
import FirebaseAuth

struct DeleteAccountView: View {
    var dismiss: () -> Void
    var deleteAccount: (String) -> Void  // ✅ Accept delete function with password

    @State private var password: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // ✅ Black Background

            VStack(spacing: 20) {
                Text("Delete Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .padding(.top, 20)

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                } else {
                    VStack(spacing: 15) {
                        SecureField("Enter Password", text: $password)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)

                        if showError {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.horizontal, 10)
                        }

                        Button(action: {
                            isLoading = true
                            deleteAccount(password)  // ✅ Call delete function with entered password
                        }) {
                            Text("Delete Permanently")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)

                        Button(action: dismiss) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
