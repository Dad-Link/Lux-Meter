import SwiftUI
import StoreKit

struct SubscriptionOptionsView: View {
    var subscriptions: [SKProduct]
    @Binding var currentSubscriptionPlan: String
    @Binding var isLoading: Bool
    @Environment(\.dismiss) var dismiss
    @State private var purchaseError: String? // To display any purchase error

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
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

                        // Display purchase error if any
                        if let error = purchaseError {
                            Text("Purchase Error: \(error)")
                                .foregroundColor(.red)
                                .padding()
                        }

                        ForEach(subscriptions, id: \.productIdentifier) { subscription in
                            // Each card manages its own loading, so pass a constant false here.
                            SubscriptionCard(
                                subscription: subscription,
                                currentSubscriptionPlan: $currentSubscriptionPlan,
                                onPurchaseError: { errorMessage in
                                    purchaseError = errorMessage
                                    isLoading = false
                                }
                            )
                        }
                        .listStyle(PlainListStyle())

                        // Button to manage Apple subscriptions
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
                        .disabled(isLoading)

                        // Restore Purchases button
                        Button(action: {
                            withAnimation {
                                isLoading = true
                            }
                            SubscriptionManager.shared.restorePurchases { success in
                                DispatchQueue.main.async {
                                    withAnimation {
                                        isLoading = false
                                    }
                                    if success {
                                        if let product = SubscriptionManager.shared.recentlyPurchasedProduct {
                                            currentSubscriptionPlan = product.productIdentifier
                                        }
                                        dismiss()
                                    } else {
                                        purchaseError = "Failed to restore previous purchases."
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
                                .opacity(isLoading ? 0.7 : 1.0)
                                .animation(.easeInOut, value: isLoading)
                        }
                        .disabled(isLoading)

                        // Additional Apple-related link
                        Link("Apple Subscription Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/us/terms.html")!)
                            .foregroundColor(.blue)
                            .padding(.top, 10)
                    }
                    .padding()
                }
                
                // Central overlay spinner for global actions
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        ProgressView("Processing...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: isLoading)
                }
            }
            .navigationBarTitle("Subscriptions", displayMode: .inline)
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                        purchaseError = nil // Clear errors on close
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.yellow)
    }
}
