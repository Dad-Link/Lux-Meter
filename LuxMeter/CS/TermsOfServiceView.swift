import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                Text("Effective Date: December 28, 2024")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("Acceptance of Terms")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
By downloading or using the Lux Meter app, you agree to be bound by these Terms of Service. If you do not agree with any part of these terms, you may not use the app.
""")
                
                Text("Use of the App")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
The Lux Meter app is provided to you for personal, non-commercial use. You agree not to misuse the app, including but not limited to:
- Attempting to reverse-engineer or modify the app.
- Using the app in a way that violates any laws or regulations.
- Interfering with the app’s operation or accessing it in an unauthorized manner.
""")
                
                Text("Intellectual Property")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
All content, features, and functionality in the Lux Meter app, including text, graphics, logos, and software, are the property of the app’s developer, Mathew, or its licensors. You may not copy, modify, or distribute any part of the app without prior written permission.
""")
                
                Text("Limitation of Liability")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
To the fullest extent permitted by law, Lux Meter and its developers will not be liable for any damages or losses arising from your use of the app, including but not limited to:
- Errors or inaccuracies in light measurement.
- Technical issues or app unavailability.
- Unauthorized access to or use of your device.
""")
                
                Text("User Responsibilities")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
As a user, you are responsible for:
- Ensuring the app is used according to these Terms of Service.
- Maintaining the security of your device while using the app.
- Granting permissions (e.g., camera access) only if you are comfortable doing so.
""")
                
                Text("Changes to Terms")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
These Terms of Service may be updated periodically. Continued use of the app after updates constitutes your acceptance of the revised terms.
""")
                
                Text("Governing Law")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
These Terms of Service are governed by and construed in accordance with the laws of your country or state of residence.
""")
                
                Text("Contact Us")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
If you have any questions about these Terms of Service, please contact us at:

Email: support@luxmeterapp.com
Address: 123 Light Avenue, Bright City, LT 45678
""")
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
    }
}
