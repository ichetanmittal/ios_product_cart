import Foundation
import SwiftUI

@MainActor
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    func loadProducts() async {
        isLoading = true
        do {
            products = try await networkManager.fetchProducts()
            filteredProducts = sortProducts(products)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func addProduct(name: String, type: String, price: Double, tax: Double, image: UIImage?) async -> Bool {
        isLoading = true
        do {
            let imageData = image?.jpegData(compressionQuality: 0.8)
            let response = try await networkManager.addProduct(name: name, type: type, price: price, tax: tax, imageData: imageData)
            if response.success {
                await loadProducts()
                return true
            }
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func toggleFavorite(for product: Product) {
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products[index].isFavorite.toggle()
            filteredProducts = sortProducts(products)
        }
    }
    
    func filterProducts() {
        if searchText.isEmpty {
            filteredProducts = sortProducts(products)
        } else {
            let filtered = products.filter { product in
                product.product_name.lowercased().contains(searchText.lowercased()) ||
                product.product_type.lowercased().contains(searchText.lowercased())
            }
            filteredProducts = sortProducts(filtered)
        }
    }
    
    private func sortProducts(_ products: [Product]) -> [Product] {
        products.sorted { first, second in
            if first.isFavorite == second.isFavorite {
                return first.product_name < second.product_name
            }
            return first.isFavorite && !second.isFavorite
        }
    }
}
