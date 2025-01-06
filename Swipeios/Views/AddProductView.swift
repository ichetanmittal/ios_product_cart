import SwiftUI
import PhotosUI

/// View for adding a new product
struct AddProductView: View {
    /// Environment value to dismiss the view
    @Environment(\.dismiss) private var dismiss
    
    /// View model containing the business logic
    @ObservedObject var viewModel: ProductViewModel
    
    // MARK: - Form Fields
    
    /// Name of the product
    @State private var productName = ""
    
    /// Type of the product (Product/Service)
    @State private var productType = "Product"
    
    /// Price of the product
    @State private var price = ""
    
    /// Tax rate for the product
    @State private var tax = ""
    
    /// Selected product image
    @State private var selectedImage: UIImage?
    
    /// PhotosPicker selection
    @State private var imageSelection: PhotosPickerItem? = nil
    
    /// Controls the presentation of alert
    @State private var showingAlert = false
    
    /// Message to display in alert
    @State private var alertMessage = ""
    
    /// Available product types
    private let productTypes = ["Product", "Service"]
    
    var body: some View {
        NavigationView {
            Form {
                // Product Details Section
                Section(header: Text("Product Details")) {
                    TextField("Product Name", text: $productName)
                    
                    Picker("Product Type", selection: $productType) {
                        ForEach(productTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                    
                    TextField("Tax (%)", text: $tax)
                        .keyboardType(.decimalPad)
                }
                
                // Product Image Section
                Section(header: Text("Product Image")) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    
                    PhotosPicker(selection: $imageSelection,
                               matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text(selectedImage == nil ? "Add Image" : "Change Image")
                        }
                    }
                    .onChange(of: imageSelection) { newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                selectedImage = UIImage(data: data)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProduct()
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    /// Validates and saves the product
    private func saveProduct() {
        // Validate product name
        guard !productName.isEmpty else {
            showAlert(message: "Please enter a product name")
            return
        }
        
        // Validate price
        guard let priceValue = Double(price), priceValue > 0 else {
            showAlert(message: "Please enter a valid price")
            return
        }
        
        // Validate tax
        guard let taxValue = Double(tax), taxValue >= 0 && taxValue <= 100 else {
            showAlert(message: "Please enter a valid tax percentage (0-100)")
            return
        }
        
        // Save product
        Task {
            if await viewModel.addProduct(
                name: productName,
                type: productType,
                price: priceValue,
                tax: taxValue,
                image: selectedImage
            ) {
                dismiss()
            } else {
                showAlert(message: "Failed to add product")
            }
        }
    }
    
    /// Shows an alert with the specified message
    /// - Parameter message: Message to display
    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
}
