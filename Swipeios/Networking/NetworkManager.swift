import Foundation

/// Possible network-related errors
enum NetworkError: Error {
    /// Invalid URL format or construction
    case invalidURL
    /// No data received from the server
    case noData
    /// Error decoding the response data
    case decodingError
    /// Other network-related errors
    case networkError(Error)
}

/// Manages all network operations for the app
class NetworkManager {
    /// Shared instance for app-wide network operations
    static let shared = NetworkManager()
    
    private init() {}
    
    /// Base URL for the API
    private let baseURL = "https://app.getswipe.in/api/public"
    
    /// Fetches all products from the API
    /// - Returns: Array of Product objects
    /// - Throws: NetworkError if the request fails
    func fetchProducts() async throws -> [Product] {
        guard let url = URL(string: "\(baseURL)/get") else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Product].self, from: data)
    }
    
    /// Adds a new product to the API
    /// - Parameters:
    ///   - name: Name of the product
    ///   - type: Type of the product (Product/Service)
    ///   - price: Price of the product
    ///   - tax: Tax rate for the product
    ///   - imageData: Optional image data for the product
    /// - Returns: ProductResponse containing the server response
    /// - Throws: NetworkError if the request fails
    func addProduct(name: String, type: String, price: Double, tax: Double, imageData: Data?) async throws -> ProductResponse {
        guard let url = URL(string: "\(baseURL)/add") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add text fields
        let parameters = [
            "product_name": name,
            "product_type": type,
            "price": String(price),
            "tax": String(tax)
        ]
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add image if available
        if let imageData = imageData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files[]\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ProductResponse.self, from: data)
    }
}
