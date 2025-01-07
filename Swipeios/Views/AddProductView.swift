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
    @State private var isSaving = false
    @FocusState private var focusedField: Field?
    
    private let productTypes = ["Product", "Service"]
    
    private enum Field {
        case productName, price, tax
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        focusedField = nil
                    }
                
                Form {
                    Section {
                        VStack(alignment: .center, spacing: 12) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(radius: 3)
                            }
                            
                            PhotosPicker(selection: $imageSelection,
                                       matching: .images) {
                                HStack {
                                    Image(systemName: selectedImage == nil ? "photo.badge.plus" : "photo.badge.plus.fill")
                                        .font(.system(size: 20))
                                    Text(selectedImage == nil ? "Add Image" : "Change Image")
                                        .font(.headline)
                                }
                                .foregroundColor(.blue)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color(.systemBackground))
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                            .onChange(of: imageSelection) { newValue in
                                Task {
                                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                        if let image = UIImage(data: data) {
                                            selectedImage = image
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                    
                    Section {
                        VStack(alignment: .leading, spacing: 16) {
                            TextField("Product Name", text: $productName)
                                .focused($focusedField, equals: .productName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                            
                            Picker("Product Type", selection: $productType) {
                                ForEach(productTypes, id: \.self) {
                                    Text($0)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text("Price")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    TextField("0.00", text: $price)
                                        .focused($focusedField, equals: .price)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Tax (%)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    TextField("0", text: $tax)
                                        .focused($focusedField, equals: .tax)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .navigationTitle("Add Product")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .disabled(isSaving)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveProduct()
                        }
                        .disabled(isSaving)
                    }
                }
                .alert("Error", isPresented: $showingAlert) {
                    Button("OK") { }
                } message: {
                    Text(alertMessage)
                }
                
                if isSaving {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Saving product...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        )
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
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
        
        isSaving = true
        focusedField = nil // Dismiss keyboard when saving
        
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
            isSaving = false
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
}
