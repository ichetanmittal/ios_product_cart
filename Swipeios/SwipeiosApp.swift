//
//  SwipeiosApp.swift
//  Swipeios
//
//  Created by Chetan Mittal on 2025/01/01.
//

import SwiftUI

/// Main entry point for the Swipeios application
/// Configures the app's window and initial view hierarchy
@main
struct SwipeiosApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}
