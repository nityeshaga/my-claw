import Foundation

/// Watches a file for changes using DispatchSource
class FileMonitor {
    private let path: String
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1

    init(path: String, onChange: @escaping () -> Void) {
        self.path = path
        self.onChange = onChange
    }

    deinit {
        stop()
    }

    func start() {
        stop()

        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .rename],
            queue: .global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            self?.onChange()
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        source.resume()
        self.source = source
    }

    func stop() {
        source?.cancel()
        source = nil
    }
}
