import SwiftUI

struct SkeletonView: View {
    @State private var opacity: Double = 0.3
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(opacity))
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                    opacity = 0.7
                }
            }
    }
}

struct ProductSkeletonCard: View {
    var isGridView: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image skeleton
            SkeletonView()
                .frame(height: isGridView ? 150 : 200)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title skeleton
                SkeletonView()
                    .frame(height: 20)
                    .frame(width: isGridView ? 100 : 150)
                
                // Subtitle skeleton
                SkeletonView()
                    .frame(height: 15)
                    .frame(width: isGridView ? 80 : 120)
                
                HStack {
                    // Price skeleton
                    SkeletonView()
                        .frame(height: 25)
                        .frame(width: isGridView ? 60 : 80)
                    
                    Spacer()
                    
                    // Heart icon skeleton
                    SkeletonView()
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
