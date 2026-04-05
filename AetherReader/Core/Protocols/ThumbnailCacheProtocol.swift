import UIKit
@preconcurrency import PDFKit

@MainActor
protocol ThumbnailCacheProtocol {
    func thumbnail(for page: PDFPage, at index: Int) -> UIImage?
    func clearCache()
}
