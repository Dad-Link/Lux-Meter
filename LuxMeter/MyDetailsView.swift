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

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo at the top
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
                                .strokeBorder(Color.gray, lineWidth: 2)
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Text("Tap to Add Logo")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                )
                                .onTapGesture {
                                    showImagePicker = true
                                }
                        }
                    }
                    .padding(.top)

                    // Title and Description
                    VStack(spacing: 5) {
                        Text("My Details")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Manage your personal and business details. Keep everything up-to-date!")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Form for details
                    VStack(spacing: 15) {
                        Group {
                            TextField("First Name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Last Name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Personal Email", text: $personalEmail)
                                .keyboardType(.emailAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        Divider()

                        Group {
                            TextField("Business Name", text: $businessName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Business Address", text: $businessAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Business Email", text: $businessEmail)
                                .keyboardType(.emailAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Business Number", text: $businessNumber)
                                .keyboardType(.phonePad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal)

                    // Save Button
                    Button(action: saveDetailsToFirebase) {
                        Text("Save Changes")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.horizontal)
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
            ImagePicker(image: $businessLogo)
        }
        .onAppear(perform: fetchDetailsFromFirebase)
        .alert(item: $feedbackMessage) { message in
            Alert(title: Text("Info"), message: Text(message.text), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Fetch User Details

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
                downloadedPDFs = document.data()?["downloadedPDFs"] as? [String] ?? []

                if let logoUrl = document.data()?["businessLogo"] as? String {
                    fetchBusinessLogo(from: logoUrl)
                }
            } else {
                feedbackMessage = FeedbackMessage(text: "Failed to load details.")
            }
        }
    }

    private func fetchBusinessLogo(from url: String) {
        guard let logoUrl = URL(string: url) else { return }
        URLSession.shared.dataTask(with: logoUrl) { data, _, _ in
            if let data = data {
                DispatchQueue.main.async {
                    businessLogo = UIImage(data: data)
                }
            }
        }.resume()
    }

    // MARK: - Save User Details

    private func saveDetailsToFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let storage = Storage.storage().reference()

        var data: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "businessName": businessName,
            "businessAddress": businessAddress,
            "businessEmail": businessEmail,
            "businessNumber": businessNumber,
            "personalEmail": personalEmail,
            "createdAt": FieldValue.serverTimestamp(),
            "downloadedPDFs": downloadedPDFs
        ]

        isLoading = true

        if let logo = businessLogo, let imageData = logo.jpegData(compressionQuality: 0.8) {
            let logoRef = storage.child("users/\(userId)/businessLogo.jpg")
            logoRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    feedbackMessage = FeedbackMessage(text: "Failed to upload logo: \(error.localizedDescription)")
                    isLoading = false
                    return
                }

                logoRef.downloadURL { url, error in
                    if let error = error {
                        feedbackMessage = FeedbackMessage(text: "Failed to fetch logo URL: \(error.localizedDescription)")
                        isLoading = false
                        return
                    }

                    if let url = url {
                        data["businessLogo"] = url.absoluteString
                        saveDataToFirestore(data: data)
                    }
                }
            }
        } else {
            saveDataToFirestore(data: data)
        }
    }

    private func saveDataToFirestore(data: [String: Any]) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userId).setData(data, merge: true) { error in
            isLoading = false
            if let error = error {
                feedbackMessage = FeedbackMessage(text: "Failed to save details: \(error.localizedDescription)")
            } else {
                feedbackMessage = FeedbackMessage(text: "Details saved successfully!")
            }
        }
    }
}

// MARK: - FeedbackMessage Struct

struct FeedbackMessage: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - ImagePicker for Logo

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
