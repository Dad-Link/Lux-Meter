import SwiftUI

struct FAQView: View {
    @State private var expandedQuestion: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("Frequently Asked Questions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // FAQ Items
                FAQItem(question: "What is Lux?",
                        answer: "Lux is a unit of measurement for light intensity. It represents how much light is falling on a surface. For example, a candle produces about 10 lux, while bright daylight can reach over 100,000 lux!",
                        expandedQuestion: $expandedQuestion)

                FAQItem(question: "How does Lux Meter work?",
                        answer: "Lux Meter uses your device’s camera to detect light intensity and converts it into measurable lux values.",
                        expandedQuestion: $expandedQuestion)

                FAQItem(question: "How do I use Lux Meter?",
                        answer: "Simply open the app, allow camera access, and start measuring the brightness of your environment.",
                        expandedQuestion: $expandedQuestion)

                FAQItem(question: "Can Lux Meter measure LED brightness?",
                        answer: "Yes! Lux Meter can measure any light source, including LED bulbs, screens, and natural light.",
                        expandedQuestion: $expandedQuestion)

                FAQItem(question: "Does Lux Meter store my data?",
                        answer: "No, Lux Meter does not collect or store any user data.",
                        expandedQuestion: $expandedQuestion)

                FAQItem(question: "Can I use Lux Meter offline?",
                        answer: "Absolutely! Lux Meter works entirely offline, using only your device’s camera to measure light intensity.",
                        expandedQuestion: $expandedQuestion)
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationTitle("FAQs")
    }
}

// MARK: - Animated FAQItem
struct FAQItem: View {
    let question: String
    let answer: String
    @Binding var expandedQuestion: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Question Row (Clickable)
            HStack {
                Text(question)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                Spacer()
                Image(systemName: expandedQuestion == question ? "chevron.up" : "chevron.down")
                    .foregroundColor(.gold)
                    .font(.system(size: 14, weight: .bold))
            }
            .padding()
            .background(Color.black.opacity(0.9))
            .cornerRadius(10)
            .onTapGesture {
                withAnimation {
                    expandedQuestion = (expandedQuestion == question) ? nil : question
                }
            }

            // Animated Answer Section
            if expandedQuestion == question {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 5)
    }
}
