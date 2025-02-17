import SwiftUI
import StoreKit

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("metricUnitsEnabled") private var metricUnitsEnabled = true
    @AppStorage("currentSubscriptionPlan") private var currentSubscriptionPlan = "None" // Use "None" or another identifier
    @State private var showingSubscriptionOptions = false
    @State private var subscriptions: [SKProduct] = []
    @State private var isLoading = false
    @State private var purchaseError: String?  // To display purchase errors


    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack {
                    Text("SETTINGS")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow) // Use .yellow directly
                        .padding(.top, 20)

                    settingsSection(title: "GENERAL SETTINGS") {
                        Toggle("Enable Notifications", isOn: $notificationsEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .yellow))
                            .foregroundStyle(.white) // Use .foregroundStyle for text color

                        Toggle("Use Metric Units", isOn: $metricUnitsEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .yellow))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: 400)
                    .padding(.vertical, 20)

                    subscriptionSection()

                    ScrollView {
                        VStack(spacing: 20) {
                            privacySection()
                            supportSection()
                            aboutSection()
                            footerLink()
                        }
                        .padding(.horizontal)
                    }
                }
                if isLoading {
                    Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                        .foregroundColor(.white)
                }
                // Display error alert if purchaseError is set
                if let error = purchaseError {
                    Color.black.opacity(0.8).edgesIgnoringSafeArea(.all) // Dim background
                    VStack {
                        Text("Purchase Error")
                            .font(.title2)
                            .foregroundColor(.red)

                        Text(error)
                            .foregroundColor(.white)
                            .padding()
                        Button("OK") {
                            purchaseError = nil // Dismiss the alert
                            isLoading = false   // Ensure loading indicator is off
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .transition(.scale) // Add a nice appearance transition
                }

            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            fetchSubscriptions()
            SubscriptionManager.shared.startObserving()

            // Listen for subscription purchase notifications
            NotificationCenter.default.addObserver(forName: .subscriptionPurchased, object: nil, queue: .main) { _ in
                // Determine purchased plan based on product ID
                if let product = SubscriptionManager.shared.recentlyPurchasedProduct {
                    self.currentSubscriptionPlan =  product.productIdentifier // Store the identifier OR
                    // More user friendly option below, but requires updates to SubscriptionCard
                    // self.currentSubscriptionPlan = product.localizedTitle

                    self.showingSubscriptionOptions = false  //Dismiss Options
                    self.isLoading = false //dismiss loading on successful completion.
                }
            }

           NotificationCenter.default.addObserver(
               forName: .subscriptionFailed,
               object: nil,
               queue: .main
           ) { notification in
               if let error = notification.object as? String {
                   self.purchaseError = error
               }
           }
        }
        .onDisappear {
            SubscriptionManager.shared.stopObserving()
            // GOOD practice to remove observers:
            NotificationCenter.default.removeObserver(self, name: .subscriptionPurchased, object: nil)
            NotificationCenter.default.removeObserver(self, name: .subscriptionFailed, object: nil)
        }
        .sheet(isPresented: $showingSubscriptionOptions) {
            SubscriptionOptionsView(subscriptions: subscriptions, currentSubscriptionPlan: $currentSubscriptionPlan, isLoading: $isLoading)
                .background(Color.black)
        }
    }

    private func subscriptionSection() -> some View {
        settingsSection(title: "SUBSCRIPTIONS") {
            Button(action: {
                isLoading = true
                // No artificial delay needed; fetchSubscriptions() already covers loading
                showingSubscriptionOptions = true
                isLoading = false  //The Sheet will handle its own loading state.
            }) {
                settingsButton(label: "Manage Subscriptions", icon: "arrow.up.arrow.down")
            }
        }
    }

    private func fetchSubscriptions() {
        isLoading = true
        let productIdentifiers: Set<String> = ["connect.weekly.luxProPass", "connect.Monthly.luxProPass"]
        SubscriptionManager.shared.requestProducts(productIdentifiers: productIdentifiers) { success, products in
            DispatchQueue.main.async {
                self.isLoading = false  // No ? needed
                if success, let products = products {
                    self.subscriptions = products // No ? needed
                } else {
                    self.purchaseError = "Failed to fetch subscription options.  Please check your internet connection and try again."  // No ? needed
                }
            }
        }
    }


    // Placeholder views : MUST BE PROVIDED before submissions
    private func privacySection() -> some View {
        settingsSection(title: "PRIVACY") {
            NavigationLink(destination: Text("Privacy Policy Content")) {  // Replace Text with PrivacyPolicyView
                settingsButton(label: "Privacy Policy", icon: "shield.fill")
            }
            NavigationLink(destination: Text("Terms of Service Content")) {  // Replace Text with TermsOfServiceView
                settingsButton(label: "Terms of Service", icon: "doc.text.fill")
            }
        }
    }

    private func supportSection() -> some View {
        settingsSection(title: "SUPPORT") {
            NavigationLink(destination: Text("Contact Support")) { // Replace with your SupportView()
                settingsButton(label: "Contact Support", icon: "phone.fill")
            }
            NavigationLink(destination: Text("FAQ Content")) {       // Replace with your FAQView()
                settingsButton(label: "FAQs", icon: "questionmark.circle.fill")
            }
        }
    }

    private func aboutSection() -> some View {
        settingsSection(title: "ABOUT") {
            Text("Version: 1.0.0")
                .foregroundColor(.yellow)
            Text("Developer: Mathew")
                .foregroundColor(.yellow)
            NavigationLink(destination: Text("About Lux Content")) { // Replace Text with AboutLuxView
                settingsButton(label: "About Lux", icon: "info.circle.fill")
            }
        }
    }


    private func footerLink() -> some View {
        Link(destination: URL(string: "https://dadlink.co.uk")!) {
            Text("Powered by DadLink Technologies Limited")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
                .underline()
                .padding(.bottom, 20)
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.yellow)
                .padding(.vertical, 5)
            VStack(spacing: 10) {
                content()
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
        }
        .frame(maxWidth: 400)
    }

    private func settingsButton(label: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black)
            Text(label)
                .foregroundColor(.black)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(Color.yellow)
        .cornerRadius(10)
    }
}
