# Swipe iOS API Documentation

This document provides information about the API endpoints used in the Swipe iOS application.

## Overview

The API is hosted at `https://app.getswipe.in/api` and provides endpoints for managing products.

## Documentation

### Interactive Documentation

To view the interactive API documentation:

1. Clone this repository
2. Make sure you have Python installed
3. Run the documentation server:
   ```bash
   ./serve-docs.sh
   ```
4. Open [http://localhost:8000/docs](http://localhost:8000/docs) in your browser

### API Specification

The complete API specification is available in OpenAPI (Swagger) format in the [api-spec.yaml](./api-spec.yaml) file.

## Available Endpoints

### Get Products

```http
GET /api/public/get
```

Retrieves a list of all available products.

#### Response

```json
[
  {
    "id": "uuid",
    "image": "string",
    "price": 0,
    "product_name": "string",
    "product_type": "string",
    "tax": 0,
    "isFavorite": false
  }
]
```

### Add Product

```http
POST /api/public/add
```

Creates a new product.

#### Request Body

Multipart form data with the following fields:

- `product_name` (required): Name of the product
- `product_type` (required): Type of the product (Product/Service)
- `price` (required): Price of the product
- `tax` (required): Tax percentage
- `image` (optional): Product image file

#### Response

```json
{
  "message": "string",
  "product_details": {
    "id": "uuid",
    "image": "string",
    "price": 0,
    "product_name": "string",
    "product_type": "string",
    "tax": 0,
    "isFavorite": false
  },
  "product_id": 0,
  "success": true
}
```

## Using the API in Code

### Swift Example

```swift
// Fetch products
func fetchProducts() async throws -> [Product] {
    guard let url = URL(string: "https://app.getswipe.in/api/public/get") else {
        throw NetworkError.invalidURL
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([Product].self, from: data)
}

// Add product
func addProduct(name: String, type: String, price: Double, tax: Double, imageData: Data?) async throws -> ProductResponse {
    guard let url = URL(string: "https://app.getswipe.in/api/public/add") else {
        throw NetworkError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    // Create multipart form data...
    // See NetworkManager.swift for complete implementation
}
```

## Error Handling

The API may return the following HTTP status codes:

- `200`: Success
- `400`: Bad Request - Check your input parameters
- `500`: Internal Server Error - Contact the API provider

## Rate Limiting

Currently, there are no rate limits imposed on the API endpoints.

## Support

For API support or questions, please file an issue in the repository.
