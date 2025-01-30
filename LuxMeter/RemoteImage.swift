import SwiftUI

struct RemoteImage: View {
    let urlString: String

    @State private var loadedImage: UIImage? = nil

    var body: some View {
        if let loadedImage = loadedImage {
            Image(uiImage: loadedImage)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "photo.fill")
                .resizable()
                .scaledToFit()
                .onAppear {
                    fetchImage()
                }
        }
    }

    private func fetchImage() {
        guard let imageUrl = URL(string: urlString) else { return }

        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: imageUrl), let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.loadedImage = uiImage
                }
            }
        }
    }
}
