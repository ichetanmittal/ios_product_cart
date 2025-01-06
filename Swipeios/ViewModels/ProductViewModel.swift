/// ViewModel responsible for managing product-related operations and state
@MainActor
class ProductViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// List of all products fetched from the API
    @Published var products: [Product] = []
    
    /// Filtered list of products based on search text and favorites
    @Published var filteredProducts: [Product] = []
    
    /// Loading state indicator
    @Published var isLoading = false
    
    /// Current search text for filtering products
    @Published var searchText = ""
    
    /// Error message to display to the user
    @Published var errorMessage: String?
    
    /// Alert control for favorite action
    @Published var showFavoriteAlert = false
    
    /// Alert control for add product action
    @Published var showAddProductAlert = false
    
    /// Message to display in alerts
    @Published var alertMessage = ""
    
    /// Indicates if the device is currently offline
    @Published var isOffline = false
    
    // MARK: - Private Properties
    
    private let networkManager = NetworkManager.shared
    private let storageManager = LocalStorageManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private let favoritesKey = "FavoriteProducts"
    
    /// Initializes the view model and sets up network monitoring
    init() {
        loadFavorites()
        setupNetworkMonitoring()
    }
    
    /// Sets up network monitoring to handle connectivity changes
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
    
    /// Syncs pending products when the device comes online
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
    
    /// Loads favorite products from user defaults
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
    
    /// Saves favorite products to user defaults
    private func saveFavorites() {
        debugPrint("DEBUG: Saving favorites to UserDefaults")
        let favorites = products.filter { $0.isFavorite }.map { $0.persistentId }
        UserDefaults.standard.set(favorites, forKey: favoritesKey)
        debugPrint("DEBUG: Saved \(favorites.count) favorites")
    }
    
    /// Loads products from the API
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
    
    /// Adds a new product to the API or saves it locally if offline
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
    
    /// Toggles the favorite status of a product
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
    
    /// Filters products based on search text
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
    
    /// Sorts products by favorite status and name
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
