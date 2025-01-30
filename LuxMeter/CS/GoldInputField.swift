import SwiftUI
import FirebaseAuth

struct GoldInputField: View {
    var title: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        ZStack(alignment: .leading) {
            // ✅ Placeholder Text
            if text.isEmpty {
                Text(title)
                    .foregroundColor(.gold.opacity(0.6)) // ✅ Faded gold for placeholder
                    .padding(.leading, 12) // ✅ Padding for proper placement
            }

            if isSecure {
                SecureField("", text: $text)
                    .padding()
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gold, lineWidth: 2))
                    .frame(maxWidth: 380)
            } else {
                TextField("", text: $text)
                    .padding()
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gold, lineWidth: 2))
                    .frame(maxWidth: 380)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Custom Gold Button
struct GoldButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gold)
                .foregroundColor(.black)
                .cornerRadius(15)
                .shadow(radius: 10)
                .padding(.horizontal, 40)
        }
    }
}

