import Foundation

/// Represents a product in the application with its associated properties
/// Conforms to Codable for JSON serialization and Identifiable for SwiftUI list rendering
struct Product: Codable, Identifiable {
    /// Unique identifier for the product instance
    let id = UUID()
    /// Optional URL string for the product's image
    var image: String?
    /// Price of the product
    var price: Double
    /// Name of the product, used as a unique identifier
    var product_name: String
    /// Type/category of the product
    var product_type: String
    /// Tax rate applicable to the product
    var tax: Double
    /// Flag indicating if the product is marked as favorite
    var isFavorite: Bool = false
    
    /// Coding keys for JSON serialization/deserialization
    enum CodingKeys: String, CodingKey {
        case image, price, product_name, product_type, tax
    }
    
    /// Persistent identifier for the product, based on the product name
    /// Used for maintaining consistency across app sessions
    var persistentId: String {
        return product_name
    }
}

/// Response structure for product-related API calls
struct ProductResponse: Codable {
    /// Response message from the server
    let message: String
    /// Details of the product
    let product_details: Product
    /// Server-assigned product ID
    let product_id: Int
    /// Flag indicating if the API call was successful
    let success: Bool
}
