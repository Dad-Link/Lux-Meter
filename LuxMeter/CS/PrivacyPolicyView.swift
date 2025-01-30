import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // **Title**
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                    .padding(.bottom, 10)

                Text("Effective Date: December 28, 2024")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                PrivacySection(title: "Introduction", content: """
Your privacy is important to us. This Privacy Policy explains how Lux Meter collects, uses, and protects your personal information when you use our app.
""")

                PrivacySection(title: "What Data Do We Collect?", content: """
1. **Camera Data**: Lux Meter requires access to your device's camera to measure light intensity (lux). No camera data is recorded, stored, or shared.
2. **Analytics Data**: We may collect anonymized analytics data to improve the app's performance and user experience.
3. **Optional User Inputs**: If you contact support or provide feedback, we may collect your name and email address.
""")

                PrivacySection(title: "How Do We Use Your Data?", content: """
We use the data collected to:
- Provide the primary functionality of the app (measuring light intensity).
- Improve the app through anonymized usage analytics.
- Respond to your queries or feedback.
""")

                PrivacySection(title: "Data Sharing", content: """
We do not sell, trade, or rent your personal information to third parties. We may share anonymized data with third-party analytics services to enhance app performance.
""")

                PrivacySection(title: "Your Rights", content: """
You have the right to:
- Deny camera access in your device settings.
- Request deletion of any personal information you provide (e.g., support emails).
- Opt out of analytics tracking, if available.
""")

                PrivacySection(title: "Security", content: """
We take reasonable measures to protect your data. However, no method of transmission over the internet or method of electronic storage is 100% secure.
""")

                PrivacySection(title: "Changes to This Policy", content: """
This Privacy Policy may be updated from time to time. We encourage you to review it periodically for any changes.
""")

                // **Contact Us Section**
                PrivacySection(title: "Contact Us", content: """
If you have any questions about this Privacy Policy, you can contact us at:

📧 Email: support@dadlink.co.uk
""")

                // **Full Privacy Policy Section**
                VStack(alignment: .leading, spacing: 5) {
                    Text("Full Privacy Policy")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.gold)
                        .padding(.top, 5)

                    Text("To read the full privacy policy, please visit our website using the link below:")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))

                    Link("Read Full Privacy Policy", destination: URL(string: "https://dadlink.co.uk/policies/privacy-policy")!)
                        .font(.headline)
                        .foregroundColor(.gold)
                        .underline()
                        .padding(.top, 5)
                }
                .padding(.vertical, 10)
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationTitle("Privacy Policy")

        // **Powered By Footer**
        .safeAreaInset(edge: .bottom) {
            Link(destination: URL(string: "https://dadlink.co.uk")!) {
                Text("Powered by DadLink Technologies Limited")
                    .font(.footnote)
                    .foregroundColor(.gold)
                    .underline()
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
            }
        }
    }
}

// MARK: - **Reusable Section Component**
struct PrivacySection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.gold)
                .padding(.top, 5)
            Text(content)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 5)
    }
}

