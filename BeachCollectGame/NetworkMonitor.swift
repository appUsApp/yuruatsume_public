import Foundation
import Network

/// Monitors the current network reachability status.
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected: Bool

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor.queue")

    init() {
        monitor = NWPathMonitor()
        let initialStatus = monitor.currentPath.status
        isConnected = initialStatus == .satisfied

        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
