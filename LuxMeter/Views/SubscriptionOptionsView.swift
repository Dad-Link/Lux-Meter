import SwiftUI
import StoreKit

struct SubscriptionOptionsView: View {
    var subscriptions: [SKProduct]
    @Binding var currentSubscriptionPlan: String
    @Binding var isLoading: Bool
    @Environment(\.dismiss) var dismiss
    @State private var purchaseError: String? // Add this


    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose Your Plan")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .padding(.top)

                Text("Unlock premium features...")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                Text("Current Plan: \(currentSubscriptionPlan)")
                    .font(.headline)
                    .foregroundColor(.yellow)
                    .padding(.bottom, 10)

                if subscriptions.isEmpty && !isLoading {
                    Text("No subscription plans available at this time.")
                        .foregroundColor(.gray)
                        .padding()
                }

                // Display the error message *within* the view
                if let error = purchaseError {
                    Text("Purchase Error: \(error)")
                        .foregroundColor(.red)
                        .padding() // Add some padding for better visual separation
                }

                ForEach(subscriptions, id: \.productIdentifier) { subscription in
                    // Pass a closure to handle errors
                    SubscriptionCard(subscription: subscription, currentSubscriptionPlan: $currentSubscriptionPlan, isLoading: $isLoading) { errorMessage in
                        self.purchaseError = errorMessage // Set the error
                        self.isLoading = false // Turn off loading indicator
                    }
                }
                .listStyle(PlainListStyle())
              // ... Rest of the buttons and toolbar
                Button(action: {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Manage Subscriptions with Apple")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    isLoading = true   // Show loading on restore
                    SubscriptionManager.shared.restorePurchases { success in
                        DispatchQueue.main.async {
                            isLoading = false
                            if success {
                                // Restore was successful, maybe show a confirmation message
                                if let product = SubscriptionManager.shared.recentlyPurchasedProduct {
                                    self.currentSubscriptionPlan = product.productIdentifier  // Or localizedTitle
                                    dismiss()
                                }
                             dismiss()
                            } else {
                                // Display restore error
                                self.purchaseError = "Failed to restore previous purchases."
                                
                            }
                        }
                    }

                }) {
                    Text("Restore Purchases")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationBarTitle("Subscriptions", displayMode: .inline)
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .toolbar { // Added toolbar for a close button.  MUCH better UX.
                ToolbarItem(placement: .cancellationAction) { // Use cancellationAction
                    Button("Close") {
                        dismiss()
                        self.purchaseError = nil //clear errors on sheet close.
                    }
                }
            }

        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.yellow)

    }
}
