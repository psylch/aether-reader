import SwiftUI
import PDFKit

struct ThumbnailSidebarView: View {
    let viewModel: ReaderViewModel

    private let thumbnailSize = CGSize(width: 100, height: 140)

    var body: some View {
        if let document = viewModel.pdfDocument {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(0..<viewModel.totalPages, id: \.self) { index in
                        if let page = document.page(at: index) {
                            thumbnailItem(page: page, index: index)
                                .onTapGesture {
                                    viewModel.goToPage(index)
                                }
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .scrollContentBackground(.hidden)
        } else {
            ContentUnavailableView(
                "No Document",
                systemImage: "doc.text",
                description: Text("Open a PDF to see page thumbnails.")
            )
        }
    }

    private func thumbnailItem(page: PDFPage, index: Int) -> some View {
        let isSelected = viewModel.currentPageIndex == index

        return VStack(spacing: 6) {
            Image(nsImage: page.thumbnail(of: thumbnailSize, for: .mediaBox))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: thumbnailSize.width, maxHeight: thumbnailSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(
                    color: isSelected ? Color.accentColor.opacity(0.4) : .black.opacity(0.2),
                    radius: isSelected ? 6 : 3,
                    y: isSelected ? 0 : 1
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.accentColor.opacity(0.6) : .clear, lineWidth: 1.5)
                )

            Text("Page \(index + 1)")
                .font(.caption2)
                .foregroundStyle(isSelected ? .primary : .tertiary)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
