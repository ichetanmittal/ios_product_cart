import SwiftUI
import PhotosUI

struct AddProductView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProductViewModel
    
    @State private var productName = ""
    @State private var productType = "Product"
    @State private var price = ""
    @State private var tax = ""
    @State private var selectedImage: UIImage?
    @State private var imageSelection: PhotosPickerItem? = nil
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let productTypes = ["Product", "Service"]
    
    var body: some View {
        NavigationView {
            Form {
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
    
    private func saveProduct() {
        guard !productName.isEmpty else {
            showAlert(message: "Please enter a product name")
            return
        }
        
        guard let priceValue = Double(price), priceValue > 0 else {
            showAlert(message: "Please enter a valid price")
            return
        }
        
        guard let taxValue = Double(tax), taxValue >= 0 && taxValue <= 100 else {
            showAlert(message: "Please enter a valid tax percentage (0-100)")
            return
        }
        
        Task {
            if await viewModel.addProduct(name: productName,
                                        type: productType,
                                        price: priceValue,
                                        tax: taxValue,
                                        image: selectedImage) {
                dismiss()
            } else {
                showAlert(message: "Failed to add product")
            }
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
}
