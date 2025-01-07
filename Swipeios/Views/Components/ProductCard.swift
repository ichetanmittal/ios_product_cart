import SwiftUI

struct ProductCard: View {
    let product: Product
    let onFavorite: () -> Void
    let isGridView: Bool
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isPressed = false
    
    private var imageURL: URL? {
        if let urlString = product.image?.trimmingCharacters(in: .whitespacesAndNewlines),
           !urlString.isEmpty {
            return URL(string: urlString)
        }
        return nil
    }
    
    var body: some View {
        Group {
            if isGridView {
                gridLayout
            } else {
                listLayout
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
    
    private var gridLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                productImage
                favoriteButton
                    .padding(12)
            }
            .frame(height: 200)
            .clipped()
            
            productDetails
                .padding(12)
        }
    }
    
    private var listLayout: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                productImage
            }
            .frame(width: 120, height: 120)
            .clipped()
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(product.product_name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    favoriteButton
                        .scaleEffect(0.8)
                        .offset(x: 8, y: -8)
                }
                
                Text(product.product_type)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline) {
                    Text("₹\(String(format: "%.2f", product.price))")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("Tax: \(String(format: "%.1f", product.tax))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding(.vertical, 12)
            .padding(.trailing, 12)
        }
    }
    
    private var productImage: some View {
        Group {
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        defaultProductImage
                    @unknown default:
                        defaultProductImage
                    }
                }
            } else {
                defaultProductImage
            }
        }
    }
    
    private var favoriteButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onFavorite()
            }
        }) {
            Circle()
                .fill(.white)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: product.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(product.isFavorite ? .red : .gray)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private var productDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.product_name)
                .font(.headline)
                .lineLimit(1)
            
            Text(product.product_type)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack(alignment: .firstTextBaseline) {
                Text("₹\(String(format: "%.2f", product.price))")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Tax: \(String(format: "%.1f", product.tax))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.top, 4)
        }
    }
    
    private var defaultProductImage: some View {
        Image("swipe")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(Color.black.opacity(0.05))
    }
}
