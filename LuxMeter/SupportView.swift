import SwiftUI

struct SupportView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Support")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                // Contact Support Section
                Text("Contact Support")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
If you need assistance, feel free to contact our support team. We are here to help you with any issues or questions regarding the Lux Meter app.
""")
                Button(action: {
                    // Replace with your support email address
                    sendEmail(to: "support@luxmeterapp.com", subject: "Support Request", body: "Please describe your issue here.")
                }) {
                    Text("Email Support")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                // FAQ Section
                Text("Frequently Asked Questions")
                    .font(.headline)
                    .fontWeight(.semibold)
                NavigationLink("View FAQs") {
                    FAQView()
                }
                .padding(.vertical, 5)

                // Feedback Section
                Text("Submit Feedback")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("""
We value your feedback! Let us know what you think about Lux Meter and how we can improve your experience.
""")
                Button(action: {
                    // Replace with your feedback email address
                    sendEmail(to: "feedback@luxmeterapp.com", subject: "Feedback for Lux Meter", body: "Share your feedback here.")
                }) {
                    Text("Submit Feedback")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Support")
    }

    // Email Sending Function
    private func sendEmail(to email: String, subject: String, body: String) {
        if let emailURL = URL(string: "mailto:\(email)?subject=\(subject)&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(emailURL)
        }
    }
}
