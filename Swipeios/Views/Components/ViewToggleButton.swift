import SwiftUI

/// A reusable button component that toggles between grid and list view layouts
/// Provides visual feedback through animations and icon changes
struct ViewToggleButton: View {
    /// Binding to control the grid/list view state
    /// - true: Grid view
    /// - false: List view
    @Binding var isGridView: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isGridView.toggle()
            }
        }) {
            Image(systemName: isGridView ? "square.grid.2x2" : "list.bullet")
                .imageScale(.large)
                .foregroundColor(.primary)
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
        }
    }
}
