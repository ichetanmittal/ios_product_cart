import SwiftUI

/// Card view for displaying a single product
struct ProductCard: View {
    /// Product to display
    let product: Product
    
    /// Action to perform when favorite button is tapped
    let onFavorite: () -> Void
    
    /// Default image to use when product image is not available
    private let defaultImage = UIImage(systemName: "photo")!
    
    private var imageURL: URL? {
        if let urlString = product.image?.trimmingCharacters(in: .whitespacesAndNewlines),
           !urlString.isEmpty {
            let url = URL(string: urlString)
            if url != nil {
                debugPrint("DEBUG: Valid URL found for \(product.product_name): \(urlString)")
            }
            return url
        }
        debugPrint("DEBUG: No valid URL for \(product.product_name)")
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product Image
            ZStack {
                if let url = imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(uiImage: defaultImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .foregroundColor(.gray)
                        @unknown default:
                            Image(uiImage: defaultImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    Image(uiImage: defaultImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 200)
            .clipped()
            .cornerRadius(8)
            
            // Product Details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.product_name)
                        .font(.headline)
                    Text(product.product_type)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onFavorite) {
                    Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(product.isFavorite ? .red : .gray)
                }
            }
            
            HStack {
                Text("₹\(String(format: "%.2f", product.price))")
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Text("Tax: \(String(format: "%.1f", product.tax))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            debugPrint("DEBUG: ProductCard appeared for \(product.product_name)")
            if let originalString = product.image {
                debugPrint("DEBUG: Original image string: \(originalString)")
            }
        }
    }
}
