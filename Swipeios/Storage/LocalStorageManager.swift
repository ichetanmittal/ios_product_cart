import Foundation

/// Manages local storage operations for the application
/// Handles persistence of pending products and favorite status using UserDefaults
class LocalStorageManager {
    /// Shared instance of the LocalStorageManager
    static let shared = LocalStorageManager()
    
    /// UserDefaults key for storing pending products
    private let pendingProductsKey = "PendingProducts"
    /// UserDefaults key for storing favorite products
    private let favoritesKey = "FavoriteProducts"
    
    private init() {}
    
    // MARK: - Pending Products
    
    /// Represents a product that is pending to be synced with the server
    struct PendingProduct: Codable {
        /// Name of the product
        let name: String
        /// Type/category of the product
        let type: String
        /// Price of the product
        let price: Double
        /// Tax rate for the product
        let tax: Double
        /// Optional image data for the product
        let imageData: Data?
    }
    
    /// Saves a product to the pending queue
    /// - Parameter product: The product to be saved
    func savePendingProduct(_ product: PendingProduct) {
        var pendingProducts = getPendingProducts()
        pendingProducts.append(product)
        
        if let encoded = try? JSONEncoder().encode(pendingProducts) {
            UserDefaults.standard.set(encoded, forKey: pendingProductsKey)
        }
    }
    
    /// Retrieves all pending products from local storage
    /// - Returns: Array of pending products
    func getPendingProducts() -> [PendingProduct] {
        guard let data = UserDefaults.standard.data(forKey: pendingProductsKey),
              let products = try? JSONDecoder().decode([PendingProduct].self, from: data) else {
            return []
        }
        return products
    }
    
    /// Removes a pending product at the specified index
    /// - Parameter index: Index of the product to remove
    func removePendingProduct(at index: Int) {
        var pendingProducts = getPendingProducts()
        guard index < pendingProducts.count else { return }
        
        pendingProducts.remove(at: index)
        
        if let encoded = try? JSONEncoder().encode(pendingProducts) {
            UserDefaults.standard.set(encoded, forKey: pendingProductsKey)
        }
    }
    
    // MARK: - Favorites
    
    /// Saves the favorite status for a product
    /// - Parameters:
    ///   - productId: UUID of the product
    ///   - isFavorite: New favorite status
    func saveFavoriteStatus(for productId: UUID, isFavorite: Bool) {
        var favorites = getFavorites()
        favorites[productId.uuidString] = isFavorite
        
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    /// Retrieves the favorite status for all products
    /// - Returns: Dictionary of product IDs to favorite status
    func getFavorites() -> [String: Bool] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let favorites = try? JSONDecoder().decode([String: Bool].self, from: data) else {
            return [:]
        }
        return favorites
    }
}
