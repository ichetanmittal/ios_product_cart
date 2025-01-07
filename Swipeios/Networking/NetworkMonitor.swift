import Foundation
import Network

/// Monitors the network connectivity status of the device
/// Implements the Observer pattern to notify subscribers of connectivity changes
class NetworkMonitor: ObservableObject {
    /// Shared instance of the NetworkMonitor
    static let shared = NetworkMonitor()
    /// Network path monitor instance from Network framework
    private let monitor = NWPathMonitor()
    /// Dedicated dispatch queue for network monitoring
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    /// Published property indicating current network connectivity status
    /// - true: Device is connected to the internet
    /// - false: Device is offline
    @Published var isConnected = true
    
    private init() {
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
