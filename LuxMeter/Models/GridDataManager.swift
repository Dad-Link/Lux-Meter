import Foundation
import Combine

class GridDataManager: ObservableObject {
    @Published var grids: [Grid] = []

    private var fileObserver: DispatchSourceFileSystemObject?
    private let fileURL: URL

    init() {
        self.fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("grids.json")
        loadGrids()
        startObservingFileChanges()
    }

    deinit {
        fileObserver?.cancel()
    }

    func loadGrids() {
        guard let data = try? Data(contentsOf: fileURL) else {
            DispatchQueue.main.async {
                self.grids = []
            }
            return
        }

        DispatchQueue.main.async {
            self.grids = (try? JSONDecoder().decode([Grid].self, from: data)) ?? []
        }
    }

    func saveGrids() {
        do {
            let data = try JSONEncoder().encode(grids)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ Failed to save grids: \(error.localizedDescription)")
        }
    }

    private func startObservingFileChanges() {
        let descriptor = open(fileURL.path, O_EVTONLY)
        guard descriptor != -1 else { return }

        fileObserver = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor, eventMask: .write, queue: DispatchQueue.main
        )

        fileObserver?.setEventHandler { [weak self] in
            self?.loadGrids() // Reload when file changes
        }

        fileObserver?.setCancelHandler {
            close(descriptor)
        }

        fileObserver?.resume()
    }
}
