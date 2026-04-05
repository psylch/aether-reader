import AppKit
@preconcurrency import PDFKit

@MainActor
protocol ThumbnailCacheProtocol {
    func thumbnail(for page: PDFPage, at index: Int) -> NSImage?
    func clearCache()
}
