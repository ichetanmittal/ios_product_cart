import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()
    @State private var showingAddProduct = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isGridView = true
    
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
            .navigationTitle("Products (\(viewModel.filteredProducts.count))")
            .searchable(text: $viewModel.searchText)
            .onChange(of: viewModel.searchText) { _, newValue in
                withAnimation {
                    print("DEBUG: Search text changed to: \(newValue)")
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

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
