import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var metricUnitsEnabled = true

    var body: some View {
        NavigationView {
            Form {
                // General Settings Section
                Section(header: Text("General Settings")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    Toggle("Use Metric Units", isOn: $metricUnitsEnabled)
                }

                // User Details Section
                Section(header: Text("My Details")) {
                    NavigationLink("My Details") {
                        MyDetailsView()
                    }
                }

                // Privacy Section
                Section(header: Text("Privacy")) {
                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }
                    NavigationLink("Terms of Service") {
                        TermsOfServiceView()
                    }
                }

                // Support Section
                Section(header: Text("Support")) {
                    NavigationLink("Contact Support") {
                        SupportView()
                    }
                    NavigationLink("FAQs") {
                        FAQView()
                    }
                }

                // About Section
                Section(header: Text("About")) {
                    Text("Version: 1.0.0")
                    Text("Developer: Mathew")
                    NavigationLink("About Lux") {
                        AboutLuxView()
                    }
                    NavigationLink("Open Source Licenses") {
                        Text("Open source library details here.")
                            .padding()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
