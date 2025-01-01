import Foundation

struct Product: Codable, Identifiable {
    let id = UUID()
    var image: String?
    var price: Double
    var product_name: String
    var product_type: String
    var tax: Double
    var isFavorite: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case image, price, product_name, product_type, tax
    }
}

struct ProductResponse: Codable {
    let message: String
    let product_details: Product
    let product_id: Int
    let success: Bool
}
