import Foundation
import Combine

class ReadingDataManager: ObservableObject {
    @Published var readings: [Reading] = []
    
    private var fileObserver: DispatchSourceFileSystemObject?
    private let fileURL: URL

    init() {
        self.fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("readings.json")

        loadReadings()
        startObservingFileChanges()
    }

    deinit {
        fileObserver?.cancel()
    }

    func loadReadings() {
        guard let data = try? Data(contentsOf: fileURL) else {
            self.readings = []
            return
        }

        DispatchQueue.main.async {
            self.readings = (try? JSONDecoder().decode([Reading].self, from: data)) ?? []
        }
    }

    func deleteReading(_ reading: Reading) {
        var savedReadings = readings
        savedReadings.removeAll { $0.id == reading.id }

        do {
            let data = try JSONEncoder().encode(savedReadings)
            try data.write(to: fileURL, options: .atomic)

            DispatchQueue.main.async {
                self.readings = savedReadings
            }
        } catch {
            print("❌ Error deleting reading: \(error.localizedDescription)")
        }
    }

    private func startObservingFileChanges() {
        let descriptor = open(fileURL.path, O_EVTONLY)
        guard descriptor != -1 else { return }

        fileObserver = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor, eventMask: .write, queue: DispatchQueue.main
        )

        fileObserver?.setEventHandler { [weak self] in
            self?.loadReadings() // Reload readings when file changes
        }

        fileObserver?.setCancelHandler {
            close(descriptor)
        }

        fileObserver?.resume()
    }
}
