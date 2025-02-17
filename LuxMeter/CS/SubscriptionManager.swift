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
    
    // Change this closure to accept a String? so we can pass back an error message or nil on success.
    private var purchaseCompletionHandler: ((String?) -> Void)?
    
    @Published var products: [SKProduct] = []
    var recentlyPurchasedProduct: SKProduct? // Track recent purchases
    
    // Global error callback if you want to use it, but not strictly required.
    var onPurchaseError: ((String) -> Void)?

    func startObserving() {
        SKPaymentQueue.default().add(self)
    }

    func stopObserving() {
        SKPaymentQueue.default().remove(self)
    }

    func requestProducts(productIdentifiers: Set<String>, completion: @escaping (Bool, [SKProduct]?) -> Void) {
        productsRequest?.cancel() // Cancel any existing requests

        productsRequestCompletionHandler = completion

        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }

    // MARK: - SKProductsRequestDelegate

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let loadedProducts = response.products
        self.products = loadedProducts
        productsRequestCompletionHandler?(true, loadedProducts)
        productsRequestCompletionHandler = nil
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Error fetching products: \(error.localizedDescription)")
        productsRequestCompletionHandler?(false, nil)
        productsRequestCompletionHandler = nil
    }

    // MARK: - Purchase Handling

    /// Updated to accept a completion closure that returns an optional error string.
    func buyProduct(_ product: SKProduct, completion: @escaping (String?) -> Void) {
        purchaseCompletionHandler = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        self.recentlyPurchasedProduct = product
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
        recentlyPurchasedProduct = products.first {
            $0.productIdentifier == transaction.payment.productIdentifier
        }
        SKPaymentQueue.default().finishTransaction(transaction)

        NotificationCenter.default.post(name: .subscriptionPurchased, object: nil)

        // Success => pass back nil for the error
        purchaseCompletionHandler?(nil)
        purchaseCompletionHandler = nil
    }

    private func fail(transaction: SKPaymentTransaction) {
        print("Transaction failed...")
        var errorMessage = "Unknown error"

        if let error = transaction.error as NSError? {
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
                    errorMessage = "An unknown error occurred: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Transaction failed: \(error.localizedDescription)"
            }
        }

        print(errorMessage)

        // If you want a global error callback as well:
        DispatchQueue.main.async {
            self.onPurchaseError?(errorMessage)
        }

        SKPaymentQueue.default().finishTransaction(transaction)

        // Failure => pass back the error message
        purchaseCompletionHandler?(errorMessage)
        purchaseCompletionHandler = nil
    }

    /// Restoring purchases is separate; you may want to handle success/failure in
    /// `paymentQueueRestoreCompletedTransactionsFinished` or `paymentQueue(_:restoreCompletedTransactionsFailedWithError:)`.
    func restorePurchases(completion: @escaping (Bool) -> Void) {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}
