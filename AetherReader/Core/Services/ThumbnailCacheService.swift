import AppKit
@preconcurrency import PDFKit

@MainActor
final class ThumbnailCacheService: ThumbnailCacheProtocol {
    private let cache = NSCache<NSNumber, NSImage>()
    private let thumbnailSize = CGSize(width: 120, height: 160)

    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50_000_000 // ~50MB
    }

    func thumbnail(for page: PDFPage, at index: Int) -> NSImage? {
        let key = NSNumber(value: index)
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let image = page.thumbnail(of: thumbnailSize, for: .cropBox)
        cache.setObject(image, forKey: key)
        return image
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
