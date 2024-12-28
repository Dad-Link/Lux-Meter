import SwiftUI

struct FAQView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Frequently Asked Questions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                FAQItem(question: "What is Lux Meter?", answer: "Lux Meter is an app that measures the intensity of light (in lux) using your device's camera.")
                FAQItem(question: "How do I use Lux Meter?", answer: "Open the app, allow camera access, and start measuring light intensity.")
                FAQItem(question: "Does Lux Meter store any data?", answer: "No, Lux Meter does not store any user data or measurements.")
                FAQItem(question: "Can I use Lux Meter offline?", answer: "Yes, Lux Meter works offline since it only uses your device's camera to measure light.")
            }
            .padding()
        }
        .navigationTitle("FAQs")
    }
}

struct FAQItem: View {
    let question: String
    let answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(question)
                .font(.headline)
                .fontWeight(.semibold)
            Text(answer)
                .font(.body)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 10)
    }
}
