import Foundation
import Network

/// Monitors network connectivity status using NWPathMonitor
class NetworkMonitor: ObservableObject {
    /// Shared instance for app-wide network monitoring
    static let shared = NetworkMonitor()
    
    /// The underlying path monitor from Network framework
    private let monitor = NWPathMonitor()
    
    /// Dedicated dispatch queue for network monitoring
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    /// Published property indicating if device has internet connectivity
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
