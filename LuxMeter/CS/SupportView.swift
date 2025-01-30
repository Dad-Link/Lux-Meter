import SwiftUI

struct SupportView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("Support")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                    .padding(.bottom, 10)

                // Contact Support Section
                SectionView(title: "Contact Support", content: """
                If you need assistance, feel free to contact our support team. We are here to help you with any issues or questions regarding the Lux Meter app.
                """)

                Button(action: {
                    sendEmail(to: "support@dadlink.com", subject: "Support Request", body: "Please describe your issue here.")
                }) {
                    Text("Email Support")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gold)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }

                // FAQ Section
                SectionView(title: "Frequently Asked Questions", content: """
                Find answers to common questions and troubleshooting steps for the Lux Meter app.
                """)

                NavigationLink(destination: FAQView()) {
                    Text("View FAQs")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gold)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                .padding(.vertical, 5)

                // Feedback Section
                SectionView(title: "Submit Feedback", content: """
                We value your feedback! Let us know what you think about Lux Meter and how we can improve your experience.
                """)

                Button(action: {
                    sendEmail(to: "support@dadlink.com", subject: "Feedback for Lux Meter", body: "Share your feedback here.")
                }) {
                    Text("Submit Feedback")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gold)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }

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
        .navigationTitle("Support")
    }

    // **Email Sending Function**
    private func sendEmail(to email: String, subject: String, body: String) {
        if let emailURL = URL(string: "mailto:\(email)?subject=\(subject)&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(emailURL)
        }
    }
}
