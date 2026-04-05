import SwiftUI

struct ReaderToolbar: View {
    let onSearch: () -> Void
    let onOutline: () -> Void
    let onThumbnails: () -> Void
    let onBookmark: () -> Void
    let onDisplayMode: () -> Void
    let isBookmarked: Bool

    var body: some View {
        HStack(spacing: 24) {
            toolbarButton(icon: "magnifyingglass", label: "Search", action: onSearch)
            toolbarButton(icon: "list.bullet", label: "Outline", action: onOutline)
            toolbarButton(icon: "square.grid.3x3", label: "Pages", action: onThumbnails)
            toolbarButton(
                icon: isBookmarked ? "bookmark.fill" : "bookmark",
                label: "Bookmark",
                action: onBookmark
            )
            toolbarButton(icon: "textformat.size", label: "Display", action: onDisplayMode)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassEffect(in: .capsule)
    }

    private func toolbarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 28, height: 28)
        }
        .accessibilityLabel(label)
    }
}
