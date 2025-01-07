import SwiftUI

/// Main view for displaying the list of products
/// Supports both grid and list layouts with offline capabilities and pull-to-refresh
struct ProductListView: View {
    /// View model managing the product data and business logic
    @StateObject private var viewModel = ProductViewModel()
    /// State for controlling the add product sheet presentation
    @State private var showingAddProduct = false
    /// Tracks the scroll offset for implementing pull-to-refresh
    @State private var scrollOffset: CGFloat = 0
    /// Controls the current view layout (grid/list)
    @State private var isGridView = true
    /// Selected filter tab (all/favorites)
    @State private var selectedTab = 0
    
    /// Grid layout configuration for two columns
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .onAppear {
                            print("DEBUG: Loading products...")
                        }
                } else {
                    VStack(spacing: 0) {
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
                        
                        Picker("Filter", selection: $selectedTab) {
                            Text("All").tag(0)
                            Text("Favorites").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        ScrollView {
                            GeometryReader { geometry in
                                Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                                    value: geometry.frame(in: .named("scroll")).minY)
                            }
                            .frame(height: 0)
                            
                            if isGridView {
                                LazyVGrid(columns: gridColumns, spacing: 16) {
                                    ForEach(viewModel.filteredProducts) { product in
                                        ProductCard(product: product,
                                                  onFavorite: { viewModel.toggleFavorite(for: product) },
                                                  isGridView: true)
                                    }
                                }
                                .padding(16)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(viewModel.filteredProducts) { product in
                                        ProductCard(product: product,
                                                  onFavorite: { viewModel.toggleFavorite(for: product) },
                                                  isGridView: false)
                                    }
                                }
                                .padding(16)
                            }
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
            .navigationTitle("Products")
            .searchable(text: $viewModel.searchText)
            .onChange(of: viewModel.searchText) { _, newValue in
                withAnimation {
                    print("DEBUG: Search text changed to: \(newValue)")
                    viewModel.filterProducts()
                }
            }
            .onChange(of: selectedTab) { _, newValue in
                withAnimation {
                    viewModel.showFavoritesOnly = newValue == 1
                    viewModel.filterProducts()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ViewToggleButton(isGridView: $isGridView)
                }
                
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
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Success", isPresented: $viewModel.showFavoriteAlert) {
                Button("OK") {
                    viewModel.showFavoriteAlert = false
                }
            } message: {
                Text(viewModel.alertMessage)
            }
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
/// Used to implement pull-to-refresh functionality
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
