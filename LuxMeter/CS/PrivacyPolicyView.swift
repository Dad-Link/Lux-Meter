import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                Text("Effective Date: December 28, 2024")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("Introduction")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
Your privacy is important to us. This Privacy Policy explains how Lux Meter collects, uses, and protects your personal information when you use our app.
""")
                
                Text("What Data Do We Collect?")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
1. **Camera Data**: Lux Meter requires access to your device's camera to measure light intensity (lux). No camera data is recorded, stored, or shared.
2. **Analytics Data**: We may collect anonymized analytics data to improve the app's performance and user experience.
3. **Optional User Inputs**: If you contact support or provide feedback, we may collect your name and email address.
""")
                
                Text("How Do We Use Your Data?")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
We use the data collected to:
- Provide the primary functionality of the app (measuring light intensity).
- Improve the app through anonymized usage analytics.
- Respond to your queries or feedback.
""")
                
                Text("Data Sharing")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
We do not sell, trade, or rent your personal information to third parties. We may share anonymized data with third-party analytics services to enhance app performance.
""")
                
                Text("Your Rights")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
You have the right to:
- Deny camera access in your device settings.
- Request deletion of any personal information you provide (e.g., support emails).
- Opt out of analytics tracking, if available.
""")
                
                Text("Security")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
We take reasonable measures to protect your data. However, no method of transmission over the internet or method of electronic storage is 100% secure.
""")
                
                Text("Changes to This Policy")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
This Privacy Policy may be updated from time to time. We encourage you to review it periodically for any changes.
""")
                
                Text("Contact Us")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
If you have any questions about this Privacy Policy, you can contact us at:

Email: support@luxmeterapp.com
Address: 123 Light Avenue, Bright City, LT 45678
""")
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}
