import SwiftUI

struct RemoteImage: View {
    let url: URL
    @State private var image: UIImage? = nil
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
                    .onAppear(perform: fetchImage)
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(Circle())
        .onAppear(perform: fetchImage)
    }

    private func fetchImage() {
        guard !isLoading else { return }
        isLoading = true

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            isLoading = false
            if let data = data, let fetchedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = fetchedImage
                }
            } else {
                print("Failed to fetch image: \(error?.localizedDescription ?? "Unknown error")")
            }
        }

        task.resume()
    }
}
