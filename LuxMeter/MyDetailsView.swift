import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

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

    private let logoFilename = "businessLogo.jpg" // ✅ File name for local storage
    @Environment(\.presentationMode) var presentationMode // ✅ Controls navigation


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

                        Text("Manage your personal and business details. Keep everything up-to-date!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

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
    }
    
    // ✅ Logout Function
    private func logout() {
        do {
            try Auth.auth().signOut()
            presentationMode.wrappedValue.dismiss() // ✅ Navigate back to LoginView
        } catch {
            feedbackMessage = FeedbackMessage(text: "Failed to log out.")
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
        if let data = image.jpegData(compressionQuality: 0.8),
           let url = getLocalLogoURL() {
            try? data.write(to: url, options: .atomic)
            businessLogo = image
        }
    }

    // ✅ Load Business Logo from Device
    private func loadBusinessLogoLocally() {
        if let url = getLocalLogoURL(),
           let data = try? Data(contentsOf: url) {
            businessLogo = UIImage(data: data)
        }
    }

    // ✅ Get File URL for Local Logo Storage
    private func getLocalLogoURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(logoFilename)
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
