import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var metricUnitsEnabled = true
    @State private var userId: String? = Auth.auth().currentUser?.uid

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // **User Details**
                        settingsSection(title: "MY DETAILS") {
                            NavigationLink(destination: MyDetailsView()) {
                                settingsButton(label: "My Details", icon: "person.fill")
                            }
                        }
                        
                        // **General Settings (Moved Below My Details)**
                        settingsSection(title: "GENERAL SETTINGS") {
                            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                                .foregroundColor(.gold)
                                .toggleStyle(SwitchToggleStyle(tint: .gold))
                                .onChange(of: notificationsEnabled, perform: { _ in saveSettings() })
                            
                            Toggle("Use Metric Units", isOn: $metricUnitsEnabled)
                                .foregroundColor(.gold)
                                .toggleStyle(SwitchToggleStyle(tint: .gold))
                                .onChange(of: metricUnitsEnabled, perform: { _ in saveSettings() })
                        }
                        
                        // **Privacy**
                        settingsSection(title: "PRIVACY") {
                            NavigationLink(destination: PrivacyPolicyView()) {
                                settingsButton(label: "Privacy Policy", icon: "shield.fill")
                            }
                            NavigationLink(destination: TermsOfServiceView()) {
                                settingsButton(label: "Terms of Service", icon: "doc.text.fill")
                            }
                        }

                        // **Support**
                        settingsSection(title: "SUPPORT") {
                            NavigationLink(destination: SupportView()) {
                                settingsButton(label: "Contact Support", icon: "phone.fill")
                            }
                            NavigationLink(destination: FAQView()) {
                                settingsButton(label: "FAQs", icon: "questionmark.circle.fill")
                            }
                        }

                        // **About**
                        settingsSection(title: "ABOUT") {
                            Text("Version: 1.0.0")
                                .foregroundColor(.gold)
                            Text("Developer: Mathew")
                                .foregroundColor(.gold)
                            
                            NavigationLink(destination: AboutLuxView()) {
                                settingsButton(label: "About Lux", icon: "info.circle.fill")
                            }
                        }
                        
                        // **Powered By Footer**
                        Link(destination: URL(string: "https://dadlink.co.uk")!) {
                            Text("Powered by DadLink Technologies Limited")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.7))
                                .underline()
                                .padding(.bottom, 20)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all)) // **Full Black Background**
            .onAppear(perform: loadSettings) // ✅ Load settings when view appears
            .navigationBarHidden(true) // ✅ Hide Navigation Bar
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // **Load User Settings from Firestore**
    private func loadSettings() {
        guard let userId = userId else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.notificationsEnabled = data["notificationsEnabled"] as? Bool ?? true
                self.metricUnitsEnabled = data["metricUnitsEnabled"] as? Bool ?? true
            }
        }
    }

    // **Save User Settings to Firestore**
    private func saveSettings() {
        guard let userId = userId else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).setData([
            "notificationsEnabled": notificationsEnabled,
            "metricUnitsEnabled": metricUnitsEnabled
        ], merge: true)
    }

    // **Reusable Section with Transparent Background**
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gold) // **Gold Section Titles**
                .padding(.vertical, 5)

            VStack(spacing: 10) {
                content()
            }
            .padding()
            .background(Color.black.opacity(0.8)) // **Dark Transparent Background**
            .cornerRadius(10)
        }
    }

    // **Reusable Styled Button for Settings**
    private func settingsButton(label: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black) // **Black icon**
            Text(label)
                .foregroundColor(.black) // **Black text**
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(Color.gold) // **Gold button**
        .cornerRadius(10)
    }
}
