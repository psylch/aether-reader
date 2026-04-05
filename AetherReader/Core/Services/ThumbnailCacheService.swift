import UIKit
@preconcurrency import PDFKit

@MainActor
final class ThumbnailCacheService: ThumbnailCacheProtocol {
    private let cache = NSCache<NSNumber, UIImage>()
    private let thumbnailSize = CGSize(width: 120, height: 160)

    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50_000_000 // ~50MB

        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearCache()
        }
    }

    func thumbnail(for page: PDFPage, at index: Int) -> UIImage? {
        let key = NSNumber(value: index)
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let image = page.thumbnail(of: thumbnailSize, for: .cropBox)
        cache.setObject(image, forKey: key, cost: image.jpegData(compressionQuality: 0.5)?.count ?? 0)
        return image
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
