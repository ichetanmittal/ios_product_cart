import Foundation

/// Represents a product in the system
struct Product: Codable, Identifiable {
    /// Unique identifier for the product
    let id = UUID()
    
    /// URL of the product image, optional
    var image: String?
    
    /// Price of the product
    var price: Double
    
    /// Name of the product
    var product_name: String
    
    /// Type of the product (e.g., "Product" or "Service")
    var product_type: String
    
    /// Tax rate for the product
    var tax: Double
    
    /// Indicates if the product is marked as favorite
    var isFavorite: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case image, price, product_name, product_type, tax
    }
    
    /// Unique identifier used for persistence
    var persistentId: String {
        // Using product name as unique identifier since it appears unique in the API
        return product_name
    }
}

/// Response structure for product-related API calls
struct ProductResponse: Codable {
    /// Success or error message from the API
    let message: String
    
    /// Details of the added/modified product
    let product_details: Product
    
    /// Server-assigned product ID
    let product_id: Int
    
    /// Indicates if the API call was successful
    let success: Bool
}
