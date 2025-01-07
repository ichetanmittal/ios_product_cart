import SwiftUI

struct ViewToggleButton: View {
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
