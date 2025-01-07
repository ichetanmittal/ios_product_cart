import Foundation
import SwiftUI
import Combine

/// ViewModel responsible for managing product data, network operations, and local storage.
/// Handles product listing, filtering, favorites, and offline capabilities.
@MainActor
class ProductViewModel: ObservableObject {
    /// Array of all products
    @Published var products: [Product] = []
    /// Array of filtered products based on search criteria
    @Published var filteredProducts: [Product] = []
    /// Loading state indicator
    @Published var isLoading = false
    /// Current search text for filtering products
    @Published var searchText = ""
    /// Error message to display to the user
    @Published var errorMessage: String?
    /// Flag to show favorite action alert
    @Published var showFavoriteAlert = false
    /// Flag to show add product alert
    @Published var showAddProductAlert = false
    /// Alert message content
    @Published var alertMessage = ""
    /// Flag indicating offline status
    @Published var isOffline = false
    
    private let networkManager = NetworkManager.shared
    private let storageManager = LocalStorageManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private let favoritesKey = "FavoriteProducts"
    
    /// Initializes the view model, loads favorites, and sets up network monitoring
    init() {
        loadFavorites()
        setupNetworkMonitoring()
    }
    
    /// Sets up network connectivity monitoring and handles offline/online state transitions
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOffline = !isConnected
                if isConnected {
                    Task {
                        await self?.syncPendingProducts()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Synchronizes pending products stored locally when device comes back online
    private func syncPendingProducts() async {
        let pendingProducts = storageManager.getPendingProducts()
        for (index, product) in pendingProducts.enumerated() {
            do {
                _ = try await networkManager.addProduct(
                    name: product.name,
                    type: product.type,
                    price: product.price,
                    tax: product.tax,
                    imageData: product.imageData
                )
                storageManager.removePendingProduct(at: index)
            } catch {
                print("Failed to sync product: \(error.localizedDescription)")
            }
        }
        await loadProducts()
    }
    
    /// Loads favorite products from UserDefaults and updates the products array
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
    
    /// Saves favorite products to UserDefaults
    private func saveFavorites() {
        debugPrint("DEBUG: Saving favorites to UserDefaults")
        let favorites = products.filter { $0.isFavorite }.map { $0.persistentId }
        UserDefaults.standard.set(favorites, forKey: favoritesKey)
        debugPrint("DEBUG: Saved \(favorites.count) favorites")
    }
    
    /// Loads products from the network and updates the products array
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
    
    /// Adds a new product to the network or saves it locally if offline
    func addProduct(name: String, type: String, price: Double, tax: Double, image: UIImage?) async -> Bool {
        let imageData = image?.jpegData(compressionQuality: 0.8)
        
        if networkMonitor.isConnected {
            // Online mode - add directly
            isLoading = true
            do {
                let response = try await networkManager.addProduct(
                    name: name,
                    type: type,
                    price: price,
                    tax: tax,
                    imageData: imageData
                )
                if response.success {
                    await loadProducts()
                    alertMessage = "Product added successfully!"
                    showAddProductAlert = true
                    return true
                }
                return false
            } catch {
                errorMessage = error.localizedDescription
                return false
            }
        } else {
            // Offline mode - save locally
            let pendingProduct = LocalStorageManager.PendingProduct(
                name: name,
                type: type,
                price: price,
                tax: tax,
                imageData: imageData
            )
            storageManager.savePendingProduct(pendingProduct)
            alertMessage = "Product saved locally and will be synced when online"
            showAddProductAlert = true
            return true
        }
    }
    
    /// Toggles the favorite status of a product and updates the products array
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
    
    /// Filters products based on the search text
    func filterProducts() {
        if searchText.isEmpty {
            filteredProducts = sortProducts(products)
        } else {
            let filtered = products.filter { product in
                product.product_name.localizedCaseInsensitiveContains(searchText) ||
                product.product_type.localizedCaseInsensitiveContains(searchText)
            }
            filteredProducts = sortProducts(filtered)
        }
    }
    
    /// Sorts products by favorite status and then by name
    private func sortProducts(_ products: [Product]) -> [Product] {
        debugPrint("DEBUG: Sorting products - Total count: \(products.count)")
        return products.sorted { first, second in
            if first.isFavorite == second.isFavorite {
                return first.product_name < second.product_name
            }
            return first.isFavorite && !second.isFavorite
        }
    }
}
