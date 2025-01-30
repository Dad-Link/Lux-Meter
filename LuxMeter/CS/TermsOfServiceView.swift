import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                    .padding(.bottom, 10)

                Text("Effective Date: December 28, 2024")
                    .font(.subheadline)
                    .foregroundColor(.gold.opacity(0.8))

                // Sections
                SectionView(title: "Acceptance of Terms", content: """
                By downloading or using the Lux Meter app, you agree to be bound by these Terms of Service. If you do not agree with any part of these terms, you may not use the app.
                """)

                SectionView(title: "Use of the App", content: """
                The Lux Meter app is provided to you for personal, non-commercial use. You agree not to misuse the app, including but not limited to:
                - Attempting to reverse-engineer or modify the app.
                - Using the app in a way that violates any laws or regulations.
                - Interfering with the app’s operation or accessing it in an unauthorized manner.
                """)

                SectionView(title: "Intellectual Property", content: """
                All content, features, and functionality in the Lux Meter app, including text, graphics, logos, and software, are the property of the app’s developer, Mathew, or its licensors. You may not copy, modify, or distribute any part of the app without prior written permission.
                """)

                SectionView(title: "Limitation of Liability", content: """
                To the fullest extent permitted by law, Lux Meter and its developers will not be liable for any damages or losses arising from your use of the app, including but not limited to:
                - Errors or inaccuracies in light measurement.
                - Technical issues or app unavailability.
                - Unauthorized access to or use of your device.
                """)

                SectionView(title: "User Responsibilities", content: """
                As a user, you are responsible for:
                - Ensuring the app is used according to these Terms of Service.
                - Maintaining the security of your device while using the app.
                - Granting permissions (e.g., camera access) only if you are comfortable doing so.
                """)

                SectionView(title: "Changes to Terms", content: """
                These Terms of Service may be updated periodically. Continued use of the app after updates constitutes your acceptance of the revised terms.
                """)

                SectionView(title: "Governing Law", content: """
                These Terms of Service are governed by and construed in accordance with the laws of your country or state of residence.
                """)

                SectionView(title: "Contact Us", content: """
                If you have any questions about these Terms of Service, please contact us at:

                Email: support@dadlink.com
                """)

                // Powered By Footer
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
        .background(Color.black.edgesIgnoringSafeArea(.all)) // Apply Black Background
        .navigationTitle("Terms of Service")
    }
}

// **Reusable Section View for Terms**
struct SectionView: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.gold)
            Text(content)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
        }
    }
}
