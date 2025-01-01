import Foundation

class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private let pendingProductsKey = "PendingProducts"
    private let favoritesKey = "FavoriteProducts"
    
    private init() {}
    
    // MARK: - Pending Products
    
    struct PendingProduct: Codable {
        let name: String
        let type: String
        let price: Double
        let tax: Double
        let imageData: Data?
    }
    
    func savePendingProduct(_ product: PendingProduct) {
        var pendingProducts = getPendingProducts()
        pendingProducts.append(product)
        
        if let encoded = try? JSONEncoder().encode(pendingProducts) {
            UserDefaults.standard.set(encoded, forKey: pendingProductsKey)
        }
    }
    
    func getPendingProducts() -> [PendingProduct] {
        guard let data = UserDefaults.standard.data(forKey: pendingProductsKey),
              let products = try? JSONDecoder().decode([PendingProduct].self, from: data) else {
            return []
        }
        return products
    }
    
    func removePendingProduct(at index: Int) {
        var pendingProducts = getPendingProducts()
        guard index < pendingProducts.count else { return }
        
        pendingProducts.remove(at: index)
        
        if let encoded = try? JSONEncoder().encode(pendingProducts) {
            UserDefaults.standard.set(encoded, forKey: pendingProductsKey)
        }
    }
    
    // MARK: - Favorites
    
    func saveFavoriteStatus(for productId: UUID, isFavorite: Bool) {
        var favorites = getFavorites()
        favorites[productId.uuidString] = isFavorite
        
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    func getFavorites() -> [String: Bool] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let favorites = try? JSONDecoder().decode([String: Bool].self, from: data) else {
            return [:]
        }
        return favorites
    }
}
