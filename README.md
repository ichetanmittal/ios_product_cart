# Swipeios - Product Management App

A SwiftUI-based iOS application for managing products with offline support.

## Features

- Product listing with search functionality
- Add new products with image support
- Mark products as favorites
- Offline support for adding products
- Beautiful UI with modern SwiftUI components

## Requirements

- Xcode 14.0 or later
- iOS 16.0 or later
- Swift 5.7 or later

## Installation

1. Clone the repository
2. Open `Swipeios.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run the project (⌘ + R)

## Project Structure

```
Swipeios/
├── Models/
│   └── Product.swift
├── ViewModels/
│   └── ProductViewModel.swift
├── Views/
│   ├── ProductListView.swift
│   ├── AddProductView.swift
│   └── Components/
│       └── ProductCard.swift
├── Networking/
│   └── NetworkManager.swift
└── Storage/
    └── LocalStorageManager.swift
```

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture:
- **Models**: Define the data structure
- **Views**: Handle the UI and user interactions
- **ViewModels**: Manage business logic and data flow
- **NetworkManager**: Handle API communications
- **LocalStorageManager**: Manage offline storage

## API Endpoints

- GET Products: `https://app.getswipe.in/api/public/get`
- POST Add Product: `https://app.getswipe.in/api/public/add`

## Offline Support

The app includes offline support through `LocalStorageManager`:
- Products created while offline are stored locally
- Favorites are persisted locally
- Pending products are automatically synced when online
