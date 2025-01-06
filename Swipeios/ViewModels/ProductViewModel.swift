import Foundation
import SwiftUI
import Combine

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
    @Published var isOffline = false
    
    private let networkManager = NetworkManager.shared
    private let storageManager = LocalStorageManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private let favoritesKey = "FavoriteProducts"
    
    init() {
        loadFavorites()
        setupNetworkMonitoring()
    }
    
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
