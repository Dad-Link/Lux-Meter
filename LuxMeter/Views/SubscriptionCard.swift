import SwiftUI
import StoreKit

struct SubscriptionCard: View {
    var subscription: SKProduct
    @Binding var currentSubscriptionPlan: String
    @Binding var isLoading: Bool
    var onPurchaseError: (String) -> Void  // Add this closure

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(subscription.localizedTitle)
                .font(.headline)
                .foregroundColor(.yellow)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subscription.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            let priceDescription = getPriceDescription(for: subscription)
            Text(priceDescription)
                .font(.title3)
                .foregroundColor(.yellow)
                .fixedSize(horizontal: false, vertical: true)

            let description = getSubscriptionDescription(for: subscription.productIdentifier)
            Text(description)
                .font(.footnote)
                .foregroundColor(.white)
                .padding(.vertical, 5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)


            Button(action: {
                isLoading = true
                SubscriptionManager.shared.buyProduct(subscription) {
                    // We now call a completion and pass the result to handler
                }
            }) {
                Text("Subscribe Now")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.black)
        .cornerRadius(10)
        .listRowInsets(EdgeInsets())
    }

    // ... getPriceDescription and getSubscriptionDescription remain unchanged ...
    private func getPriceDescription(for subscription: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = subscription.priceLocale
        let formattedPrice = formatter.string(from: subscription.price) ?? "\(subscription.price)" // Fallback

        let duration: String
        if let period = subscription.subscriptionPeriod {
            switch period.unit {
            case .day:   duration = period.numberOfUnits == 1 ? "day" : "\(period.numberOfUnits) days" //Handle Days
            case .week:  duration = period.numberOfUnits == 1 ? "week" : "\(period.numberOfUnits) weeks"
            case .month: duration = period.numberOfUnits == 1 ? "month" : "\(period.numberOfUnits) months"
            case .year:  duration = period.numberOfUnits == 1 ? "year" : "\(period.numberOfUnits) years"
            @unknown default: duration = "Unknown"
            }
        } else {
            duration = "Unknown"
        }

        return "Price: \(formattedPrice) / \(duration)"
    }

    private func getSubscriptionDescription(for productIdentifier: String) -> String {
        switch productIdentifier {
        case "connect.weekly.luxProPass":
            return "Lux Pro Weekly: Quick savings on the go. Enjoy 7 days of full access to Lux Meter, including PDF downloads and advanced analytics."
        case "connect.Monthly.luxProPass":
            return "Lux Pro Monthly: Get monthly savings with Lux Pro access. Enjoy 30 days of premium features including PDF downloads and advanced analytics."
        default:
            return "Unknown subscription plan."
        }
    }
}
