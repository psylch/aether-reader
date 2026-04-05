import SwiftUI
import PDFKit

struct LibraryGridItem: View {
    let document: PDFDocumentModel
    let isSelected: Bool

    @State private var thumbnail: NSImage?

    private let thumbnailSize = CGSize(width: 180, height: 240)

    var body: some View {
        VStack(spacing: 6) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                thumbnailView
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 2)

                // Page count badge
                Text("\(document.pageCount) p.")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.5), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(6)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentColor, lineWidth: 2.5)
                }
            }

            // File name
            Text(document.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            // Reading progress
            if document.readingProgress > 0 {
                ProgressView(value: document.readingProgress)
                    .tint(.accentColor)
                    .scaleEffect(y: 0.5)
                    .padding(.horizontal, 8)
            }
        }
        .padding(8)
        .contentShape(Rectangle())
        .task(id: document.filePath) {
            await loadThumbnail()
        }
    }

    // MARK: - Thumbnail View

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail {
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
        }
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnail() async {
        // Check cache first
        if let cached = ThumbnailCache.shared.get(for: document.filePath) {
            self.thumbnail = cached
            return
        }

        let relativePath = document.filePath
        let size = thumbnailSize

        let image: NSImage? = await Task.detached(priority: .utility) {
            let url = await FileService.shared.pdfURL(for: relativePath)
            guard let pdfDoc = PDFDocument(url: url),
                  let page = pdfDoc.page(at: 0) else { return nil }
            return page.thumbnail(of: size, for: .mediaBox)
        }.value

        if let image {
            ThumbnailCache.shared.set(image, for: relativePath)
            self.thumbnail = image
        }
    }
}

// MARK: - Thumbnail Cache

private final class ThumbnailCache: @unchecked Sendable {
    static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, NSImage>()

    init() {
        cache.countLimit = 200
    }

    func get(for key: String) -> NSImage? {
        cache.object(forKey: key as NSString)
    }

    func set(_ image: NSImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
