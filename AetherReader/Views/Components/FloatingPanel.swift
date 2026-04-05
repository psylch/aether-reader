import SwiftUI

/// Shared floating panel container — glass effect, consistent styling.
/// Used by annotation tools (Phase 2), measurement (Phase 7), etc.
struct FloatingPanel<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(12)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
}
