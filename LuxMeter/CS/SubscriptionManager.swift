import StoreKit
import Combine

// Define notification names as extensions for type safety
extension Notification.Name {
    static let subscriptionPurchased = Notification.Name("subscriptionPurchased")
    static let productsUpdated = Notification.Name("productsUpdated")
    static let subscriptionFailed = Notification.Name("subscriptionFailed") // Add for failures.
}

class SubscriptionManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let shared = SubscriptionManager()

    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ((Bool, [SKProduct]?) -> Void)?
    private var purchaseCompletionHandler: (() -> Void)?
    @Published var products: [SKProduct] = [] // Could use @Published but Notifications needed still
    var recentlyPurchasedProduct: SKProduct? // Track recent purchases
    
    // Add the missing property for error handling
    var onPurchaseError: ((String) -> Void)?

    func startObserving() {
        SKPaymentQueue.default().add(self)
    }

    func stopObserving() {
        SKPaymentQueue.default().remove(self)
    }

    func requestProducts(productIdentifiers: Set<String>, completion: @escaping (Bool, [SKProduct]?) -> Void) {
        productsRequest?.cancel() // Cancel any existing requests.

        productsRequestCompletionHandler = completion

        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }


    // MARK: - SKProductsRequestDelegate

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let loadedProducts = response.products
        self.products = loadedProducts
        productsRequestCompletionHandler?(true, loadedProducts)  // Use the completion handler
        productsRequestCompletionHandler = nil // Clear after use.
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Error fetching products: \(error.localizedDescription)")
        productsRequestCompletionHandler?(false, nil) // Signal failure
        productsRequestCompletionHandler = nil
    }

    // MARK: - Purchase Handling
    func buyProduct(_ product: SKProduct, completion: @escaping () -> Void) {
        purchaseCompletionHandler = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        self.recentlyPurchasedProduct = product   // Store!
    }

    // MARK: - SKPaymentTransactionObserver

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                complete(transaction: transaction)
            case .failed:
                fail(transaction: transaction)
            case .deferred:
                print("Transaction deferred.")
            case .purchasing:
                print("purchasing")
            @unknown default:
                break
            }
        }
    }

    private func complete(transaction: SKPaymentTransaction) {
        print("Transaction complete...")
        recentlyPurchasedProduct = products.first { $0.productIdentifier == transaction.payment.productIdentifier }
        SKPaymentQueue.default().finishTransaction(transaction)

        NotificationCenter.default.post(name: .subscriptionPurchased, object: nil)
        purchaseCompletionHandler?() //call completion.
        purchaseCompletionHandler = nil; //Clear Handler
    }

    private func fail(transaction: SKPaymentTransaction) {
        print("Transaction failed...") // Keep this
        if let error = transaction.error as NSError? {
            var errorMessage = ""
            if error.domain == SKErrorDomain {
                switch error.code {
                case SKError.paymentCancelled.rawValue:
                    errorMessage = "Payment was cancelled by the user."
                case SKError.paymentInvalid.rawValue:
                    errorMessage = "The payment was invalid. Please check your payment information."
                case SKError.paymentNotAllowed.rawValue:
                    errorMessage = "Payments are not allowed on this device."
                case SKError.storeProductNotAvailable.rawValue:
                    errorMessage = "The product is not currently available in the store."
                case SKError.cloudServicePermissionDenied.rawValue:
                    errorMessage = "Permission to access the cloud service was denied."
                case SKError.cloudServiceNetworkConnectionFailed.rawValue:
                    errorMessage = "The device could not connect to the network."
                case SKError.cloudServiceRevoked.rawValue:
                    errorMessage = "Cloud service access was revoked."
                default:
                    errorMessage = "An unknown error occurred during purchase: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Transaction failed: \(error.localizedDescription)"
            }

            print(errorMessage) // For debugging
            DispatchQueue.main.async {
                self.onPurchaseError?(errorMessage) // Corrected line
            }
        }
        SKPaymentQueue.default().finishTransaction(transaction)
        purchaseCompletionHandler?() //call completion.
        purchaseCompletionHandler = nil //always clear.
    }

    func restorePurchases(completion: @escaping (Bool) -> Void) {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}
