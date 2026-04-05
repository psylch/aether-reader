import SwiftUI
@preconcurrency import PDFKit

@Observable
@MainActor
final class ThumbnailStripViewModel {
    var thumbnails: [Int: NSImage] = [:]
    var currentPageIndex: Int = 0

    private let cacheService: ThumbnailCacheService
    private weak var document: PDFDocument?

    init(cacheService: ThumbnailCacheService = ThumbnailCacheService()) {
        self.cacheService = cacheService
    }

    func setDocument(_ document: PDFDocument?) {
        self.document = document
        thumbnails.removeAll()
        cacheService.clearCache()
    }

    func loadThumbnail(at index: Int) {
        guard thumbnails[index] == nil,
              let page = document?.page(at: index)
        else { return }

        if let image = cacheService.thumbnail(for: page, at: index) {
            thumbnails[index] = image
        }
    }

    var pageCount: Int {
        document?.pageCount ?? 0
    }
}
