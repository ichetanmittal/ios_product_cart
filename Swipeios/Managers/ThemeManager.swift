import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("isDarkMode") private(set) var isDarkMode: Bool = false
    
    private init() {}
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
}
