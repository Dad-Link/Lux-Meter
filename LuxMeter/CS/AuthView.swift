import Foundation

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = true  // Always allow entry
}
