import SwiftUI

/// Main view for displaying the list of products
struct ProductListView: View {
    /// View model containing the business logic
    @StateObject private var viewModel = ProductViewModel()
    
    /// Controls the presentation of the add product sheet
    @State private var showingAddProduct = false
    
    /// Tracks the scroll offset for potential future use (e.g., pull to refresh)
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .onAppear {
                            print("DEBUG: Loading products...")
                        }
                } else {
                    VStack {
                        // Offline mode indicator
                        if viewModel.isOffline {
                            HStack {
                                Image(systemName: "wifi.slash")
                                Text("Offline Mode")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        ScrollView {
                            // Geometry reader for scroll tracking
                            GeometryReader { geometry in
                                Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                                    value: geometry.frame(in: .named("scroll")).minY)
                            }
                            .frame(height: 0)
                            
                            // Product list
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredProducts) { product in
                                    ProductCard(product: product) {
                                        viewModel.toggleFavorite(for: product)
                                    }
                                    .padding(.horizontal)
                                    .onAppear {
                                        print("DEBUG: Loading product: \(product.product_name)")
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            scrollOffset = value
                            print("DEBUG: Scroll offset: \(scrollOffset)")
                        }
                        .refreshable {
                            print("DEBUG: Refreshing products...")
                            await viewModel.loadProducts()
                        }
                    }
                }
            }
            .navigationTitle("Products (\(viewModel.filteredProducts.count))")
            .searchable(text: $viewModel.searchText)
            .onChange(of: viewModel.searchText) { _, newValue in
                print("DEBUG: Search text changed to: \(newValue)")
                viewModel.filterProducts()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddProduct = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProduct) {
                AddProductView(viewModel: viewModel)
            }
            // Error alert
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            // Favorite action alert
            .alert("Success", isPresented: $viewModel.showFavoriteAlert) {
                Button("OK") {
                    viewModel.showFavoriteAlert = false
                }
            } message: {
                Text(viewModel.alertMessage)
            }
            // Add product success alert
            .alert("Success", isPresented: $viewModel.showAddProductAlert) {
                Button("OK") {
                    viewModel.showAddProductAlert = false
                }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
        .task {
            print("DEBUG: Initial products load")
            await viewModel.loadProducts()
        }
    }
}

/// Preference key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
