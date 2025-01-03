import Foundation
import SwiftUI

@MainActor
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published var showFavoriteAlert = false
    @Published var showAddProductAlert = false
    @Published var alertMessage = ""
    
    private let networkManager = NetworkManager.shared
    private let favoritesKey = "FavoriteProducts"
    
    init() {
        loadFavorites()
    }
    
    private func loadFavorites() {
        debugPrint("DEBUG: Loading favorites from UserDefaults")
        let favorites = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        debugPrint("DEBUG: Found \(favorites.count) favorites")
        
        // Update products with saved favorites
        for (index, var product) in products.enumerated() {
            product.isFavorite = favorites.contains(product.persistentId)
            products[index] = product
        }
        
        filteredProducts = sortProducts(products)
    }
    
    private func saveFavorites() {
        debugPrint("DEBUG: Saving favorites to UserDefaults")
        let favorites = products.filter { $0.isFavorite }.map { $0.persistentId }
        UserDefaults.standard.set(favorites, forKey: favoritesKey)
        debugPrint("DEBUG: Saved \(favorites.count) favorites")
    }
    
    func loadProducts() async {
        debugPrint("DEBUG: Starting to load products...")
        isLoading = true
        do {
            products = try await networkManager.fetchProducts()
            // After loading products, restore their favorite status
            let favorites = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
            for (index, var product) in products.enumerated() {
                product.isFavorite = favorites.contains(product.persistentId)
                products[index] = product
            }
            filteredProducts = sortProducts(products)
            debugPrint("DEBUG: Successfully loaded \(products.count) products")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("DEBUG: Error loading products: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func addProduct(name: String, type: String, price: Double, tax: Double, image: UIImage?) async -> Bool {
        debugPrint("DEBUG: Adding new product - Name: \(name), Type: \(type), Price: \(price), Tax: \(tax)")
        isLoading = true
        do {
            let imageData = image?.jpegData(compressionQuality: 0.8)
            let response = try await networkManager.addProduct(name: name, type: type, price: price, tax: tax, imageData: imageData)
            if response.success {
                debugPrint("DEBUG: Product added successfully")
                await loadProducts()
                alertMessage = "Product added successfully!"
                showAddProductAlert = true
                return true
            }
            debugPrint("DEBUG: Failed to add product")
            return false
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("DEBUG: Error adding product: \(error.localizedDescription)")
            return false
        }
    }
    
    func toggleFavorite(for product: Product) {
        debugPrint("DEBUG: Toggling favorite for product: \(product.product_name)")
        if let index = products.firstIndex(where: { $0.persistentId == product.persistentId }) {
            products[index].isFavorite.toggle()
            let isFavorite = products[index].isFavorite
            filteredProducts = sortProducts(products)
            
            // Save favorites after toggling
            saveFavorites()
            
            alertMessage = isFavorite ? "Product marked as favorite!" : "Product removed from favorites"
            showFavoriteAlert = true
            
            debugPrint("DEBUG: Product \(product.product_name) is now \(isFavorite ? "favorited" : "unfavorited")")
        }
    }
    
    func filterProducts() {
        debugPrint("DEBUG: Filtering products with search text: \(searchText)")
        if searchText.isEmpty {
            filteredProducts = sortProducts(products)
        } else {
            let filtered = products.filter { product in
                product.product_name.lowercased().contains(searchText.lowercased()) ||
                product.product_type.lowercased().contains(searchText.lowercased())
            }
            filteredProducts = sortProducts(filtered)
        }
        debugPrint("DEBUG: Found \(filteredProducts.count) products after filtering")
    }
    
    private func sortProducts(_ products: [Product]) -> [Product] {
        debugPrint("DEBUG: Sorting products - Total count: \(products.count)")
        let sorted = products.sorted { first, second in
            if first.isFavorite == second.isFavorite {
                return first.product_name < second.product_name
            }
            return first.isFavorite && !second.isFavorite
        }
        debugPrint("DEBUG: Sorting complete - Favorites at top")
        return sorted
    }
}
